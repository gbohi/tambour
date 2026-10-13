"""
Calcul de l'état d'un trajet pour le suivi en temps réel : position du car,
distance et temps restants, heure d'arrivée estimée, progression.

La distance restante est estimée à vol d'oiseau multipliée par un facteur
routier ; la vitesse est la moyenne des dernières positions GPS, bornée.
Sans GPS récent, on se rabat sur l'horaire prévu.
"""
import math
from datetime import timedelta
from django.utils import timezone

from transport.models import Trajet

FACTEUR_ROUTE = 1.25            # route réelle ≈ 25 % plus longue que la ligne droite
FRAICHEUR_GPS = timedelta(minutes=5)
FENETRE_VITESSE = timedelta(minutes=15)
VITESSE_MIN, VITESSE_MAX = 25.0, 90.0   # km/h, bornes de la vitesse moyenne utilisée
RAFRAICHISSEMENT_S = 15
ARRIVEE_PROCHE_M = 400          # en deçà, le car est considéré arrivé à la gare


def distance_m(lat1, lng1, lat2, lng2):
    """Distance à vol d'oiseau (formule de haversine), en mètres."""
    r = 6_371_000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def _point(gare, ville):
    """Coordonnées d'une extrémité de ligne : la gare si connue, sinon la ville."""
    if gare and gare.latitude is not None:
        return {'nom': gare.nom, 'ville': ville.nom, 'latitude': float(gare.latitude), 'longitude': float(gare.longitude)}
    if ville.latitude is not None:
        return {'nom': ville.nom, 'ville': ville.nom, 'latitude': float(ville.latitude), 'longitude': float(ville.longitude)}
    return None


def _vitesse_moyenne_kmh(positions, ligne_kmh):
    vitesses = [p.vitesse_kmh for p in positions if p.vitesse_kmh is not None and p.vitesse_kmh >= 5]
    if vitesses:
        v = sum(vitesses) / len(vitesses)
    elif len(positions) >= 2:
        # Vitesse déduite du déplacement entre la plus ancienne et la plus récente position
        a, b = positions[-1], positions[0]
        duree_h = (b.enregistre_le - a.enregistre_le).total_seconds() / 3600
        d_km = distance_m(float(a.latitude), float(a.longitude), float(b.latitude), float(b.longitude)) * FACTEUR_ROUTE / 1000
        v = d_km / duree_h if duree_h > 0 else ligne_kmh
    else:
        v = ligne_kmh
    return max(VITESSE_MIN, min(VITESSE_MAX, v))


def etat_suivi(trajet: Trajet, maintenant=None, avec_trace=True):
    maintenant = maintenant or timezone.now()
    ligne = trajet.ligne
    depart = _point(ligne.gare_depart, ligne.depart)
    arrivee = _point(ligne.gare_arrivee, ligne.arrivee)

    duree_prevue = trajet.heure_arrivee_estimee - trajet.heure_depart
    if ligne.distance_km:
        distance_totale = ligne.distance_km * 1000
    elif depart and arrivee:
        distance_totale = distance_m(depart['latitude'], depart['longitude'],
                                     arrivee['latitude'], arrivee['longitude']) * FACTEUR_ROUTE
    else:
        distance_totale = None
    duree_h = max(duree_prevue.total_seconds() / 3600, 0.5)
    ligne_kmh = (distance_totale / 1000 / duree_h) if distance_totale else 60.0

    positions = list(trajet.positions.filter(enregistre_le__gte=maintenant - FENETRE_VITESSE)[:60])
    derniere = positions[0] if positions else trajet.positions.first()
    retard = timedelta(minutes=trajet.retard_minutes or 0)

    etat = {
        'phase': 'a_venir', 'source': 'horaire',
        'position': None, 'distance_totale_km': round(distance_totale / 1000, 1) if distance_totale else None,
        'distance_restante_km': None, 'minutes_restantes': None, 'arrivee_estimee': None,
        'progression': 0, 'depart_dans_minutes': None,
    }
    if derniere:
        etat['position'] = {
            'latitude': float(derniere.latitude), 'longitude': float(derniere.longitude),
            'vitesse_kmh': derniere.vitesse_kmh, 'cap': derniere.cap,
            'enregistre_le': derniere.enregistre_le.isoformat(),
            'il_y_a_secondes': max(0, int((maintenant - derniere.enregistre_le).total_seconds())),
        }

    if trajet.statut == Trajet.Statut.TERMINE:
        fin = trajet.heure_arrivee_reelle or trajet.heure_arrivee_estimee
        etat.update(phase='arrive', source='chauffeur', progression=100, minutes_restantes=0,
                    distance_restante_km=0, arrivee_estimee=fin.isoformat())
    elif trajet.statut == Trajet.Statut.ANNULE:
        etat.update(phase='annule')
    elif trajet.statut == Trajet.Statut.EN_COURS:
        etat['phase'] = 'en_route'
        gps_frais = derniere and arrivee and maintenant - derniere.enregistre_le <= FRAICHEUR_GPS
        if gps_frais:
            restant = distance_m(float(derniere.latitude), float(derniere.longitude),
                                 arrivee['latitude'], arrivee['longitude']) * FACTEUR_ROUTE
            if distance_totale:
                restant = min(restant, distance_totale)
            vitesse = _vitesse_moyenne_kmh(positions, ligne_kmh)
            secondes = 0 if restant <= ARRIVEE_PROCHE_M else restant / (vitesse / 3.6)
            progression = (1 - restant / distance_totale) * 100 if distance_totale else 0
            etat.update(source='gps', vitesse_moyenne_kmh=round(vitesse))
        else:
            debut = trajet.demarre_le or trajet.heure_depart
            ecoule = maintenant - debut
            ratio = min(max(ecoule / duree_prevue if duree_prevue.total_seconds() else 0, 0), 0.99)
            secondes = max((duree_prevue - ecoule).total_seconds(), 0)
            restant = distance_totale * (1 - ratio) if distance_totale else None
            progression = ratio * 100
        if restant is not None and restant <= ARRIVEE_PROCHE_M:
            etat['phase'] = 'arrivee_imminente'
        etat.update(
            distance_restante_km=round(restant / 1000, 1) if restant is not None else None,
            minutes_restantes=math.ceil(secondes / 60),
            arrivee_estimee=(maintenant + timedelta(seconds=secondes)).isoformat(),
            progression=round(max(0, min(progression, 99 if secondes > 0 else 100))))
    else:  # planifié ou retardé : pas encore parti
        depart_prevu = trajet.heure_depart + retard
        etat.update(
            phase='a_venir', source='horaire',
            depart_dans_minutes=max(0, math.ceil((depart_prevu - maintenant).total_seconds() / 60)),
            arrivee_estimee=(trajet.heure_arrivee_estimee + retard).isoformat(),
            minutes_restantes=max(0, math.ceil((trajet.heure_arrivee_estimee + retard - maintenant).total_seconds() / 60)),
            distance_restante_km=etat['distance_totale_km'])

    etat.update({
        'trajet': {
            'id': str(trajet.id), 'statut': trajet.statut, 'statut_label': trajet.get_statut_display(),
            'depart': ligne.depart.nom, 'arrivee': ligne.arrivee.nom,
            'heure_depart': trajet.heure_depart.isoformat(),
            'heure_arrivee_prevue': trajet.heure_arrivee_estimee.isoformat(),
            'retard_minutes': trajet.retard_minutes, 'compagnie': trajet.transporteur.nom,
            'bus_immatriculation': trajet.bus.immatriculation if trajet.bus else '',
        },
        'point_depart': depart, 'point_arrivee': arrivee,
        'rafraichir_dans_secondes': RAFRAICHISSEMENT_S,
        'genere_le': maintenant.isoformat(),
    })
    if avec_trace:
        trace = trajet.positions.order_by('enregistre_le').values_list('latitude', 'longitude')
        points = [[float(a), float(b)] for a, b in trace]
        # On allège la trace : au plus ~300 points
        pas = max(1, len(points) // 300)
        etat['trace'] = points[::pas] + (points[-1:] if points and len(points) % pas else [])
    return etat
