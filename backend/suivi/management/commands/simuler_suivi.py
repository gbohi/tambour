"""
Simule un car en route pour tester le suivi en temps réel sans téléphone.

    python manage.py simuler_suivi                 # choisit un trajet avec chauffeur et des passagers
    python manage.py simuler_suivi --trajet <id>   # trajet précis
    python manage.py simuler_suivi --progression 40 --une-fois   # place le car à 40 % et s'arrête

Le trajet passe « en cours » ; une position est enregistrée toutes les --intervalle secondes,
le long de la ligne droite départ → arrivée (avec un léger décalage pour imiter la route).
"""
import math
import random
import time
from datetime import timedelta

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.db.models import Count, F, Q
from django.utils import timezone

from reservations.models import Reservation
from suivi.models import PositionGPS
from suivi.services import _point
from transport.models import Trajet

User = get_user_model()


class Command(BaseCommand):
    help = 'Simule les positions GPS d\'un car pour le suivi en temps réel.'

    def add_arguments(self, parser):
        parser.add_argument('--trajet', help='Identifiant du trajet')
        parser.add_argument('--progression', type=float, default=10, help='Progression de départ, en %% (défaut 10)')
        parser.add_argument('--intervalle', type=float, default=5, help='Secondes entre deux positions (défaut 5)')
        parser.add_argument('--pas', type=float, default=0.5, help='Progression ajoutée à chaque position, en %% (défaut 0,5)')
        parser.add_argument('--une-fois', action='store_true', help='Enregistre une seule position puis s\'arrête')

    def handle(self, *args, **o):
        trajet = self._trajet(o['trajet'])
        dep = _point(trajet.ligne.gare_depart, trajet.ligne.depart)
        arr = _point(trajet.ligne.gare_arrivee, trajet.ligne.arrivee)
        if not dep or not arr:
            raise CommandError('Coordonnées manquantes pour la ligne de ce trajet.')
        duree = trajet.heure_arrivee_estimee - trajet.heure_depart
        p = max(0.0, min(o['progression'], 99.0))
        if trajet.statut != Trajet.Statut.EN_COURS:
            trajet.statut = Trajet.Statut.EN_COURS
            trajet.demarre_le = timezone.now() - duree * (p / 100)
            trajet.save(update_fields=['statut', 'demarre_le', 'updated_at'])
        self.stdout.write(self.style.SUCCESS(
            f'Trajet {trajet.id} : {trajet.ligne.depart.nom} → {trajet.ligne.arrivee.nom} (en cours)'))
        while True:
            t = p / 100
            # Petit arc pour que le tracé ne soit pas une ligne parfaitement droite
            bombe = math.sin(math.pi * t) * 0.08
            lat = dep['latitude'] + (arr['latitude'] - dep['latitude']) * t + bombe
            lng = dep['longitude'] + (arr['longitude'] - dep['longitude']) * t - bombe / 2
            PositionGPS.objects.create(trajet=trajet, latitude=round(lat, 6), longitude=round(lng, 6),
                                       vitesse_kmh=round(random.uniform(55, 80), 1), enregistre_le=timezone.now())
            self.stdout.write(f'  position à {p:.1f} % ({lat:.4f}, {lng:.4f})')
            if o['une_fois'] or p >= 100:
                break
            p = min(100.0, p + o['pas'])
            time.sleep(o['intervalle'])

    def _trajet(self, ident):
        if ident:
            try:
                return Trajet.objects.select_related('ligne__depart', 'ligne__arrivee').get(pk=ident)
            except (Trajet.DoesNotExist, ValueError):
                raise CommandError(f'Trajet introuvable : {ident}')
        maintenant = timezone.now()
        qs = (Trajet.objects.filter(statut__in=[Trajet.Statut.PLANIFIE, Trajet.Statut.RETARDE, Trajet.Statut.EN_COURS],
                                    heure_depart__range=(maintenant - timedelta(hours=6), maintenant + timedelta(days=3)))
              .annotate(nb=Count('reservations', filter=Q(reservations__statut=Reservation.Statut.CONFIRMEE)))
              .filter(nb__gt=0)
              .order_by(F('chauffeur').asc(nulls_last=True), '-nb', 'heure_depart'))
        trajet = qs.first()
        if not trajet:
            raise CommandError("Aucun trajet réservé dans les 3 prochains jours. Lancez d'abord « seed_demo ».")
        if not trajet.chauffeur_id:
            chauffeur = User.objects.filter(role='chauffeur', is_active=True).order_by('date_joined').first()
            if chauffeur:
                trajet.chauffeur = chauffeur
                trajet.save(update_fields=['chauffeur', 'updated_at'])
                self.stdout.write(f'  chauffeur affecté : {chauffeur.email}')
        return trajet
