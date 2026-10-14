"""
Données de démonstration complètes : compagnies, cars, trajets des 7 prochains jours,
comptes de test (admin, chauffeur, voyageur) et réservations.

    python manage.py seed_donnees   # villes, gares, lignes (à lancer d'abord)
    python manage.py seed_demo
"""
import random
from datetime import datetime, time, timedelta

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from paiements.models import Paiement
from reservations.models import Reservation, Passager, Billet
from transport.models import places_disponibles, Bus, Gare, Ligne, Siege, Trajet, Transporteur, Ville

User = get_user_model()

COMPTES = [
    # email, mot de passe, prénom, nom, rôle
    ('admin@tambour.ci', 'Admin2026!', 'Awa', 'Diabaté', 'admin'),
    ('chauffeur@tambour.ci', 'Chauffeur2026!', 'Moussa', 'Traoré', 'chauffeur'),
    ('voyageur@tambour.ci', 'Voyageur2026!', 'Kouassi', 'Adjoumani', 'voyageur'),
]

COMPAGNIES = [
    ('Trans Ivoire', 'contact@transivoire.ci', '27 20 30 40 50', [
        ('AB-2341-CI', 'Yutong ZK6122', 54, 'standard', ['clim', 'usb']),
        ('AB-5512-CI', 'Higer KLQ6128', 54, 'confort', ['clim', 'wifi', 'usb', 'eau']),
    ]),
    ('Confort Express', 'contact@confortexpress.ci', '27 20 31 41 51', [
        ('CE-1100-CI', 'Mercedes Tourismo', 49, 'confort', ['clim', 'wifi', 'usb', 'snack']),
    ]),
    ('VIP Voyages', 'contact@vipvoyages.ci', '27 20 32 42 52', [
        ('VV-7777-CI', 'Setra ComfortClass', 40, 'vip', ['clim', 'wifi', 'usb', 'eau', 'snack', 'siege_large', 'toilet']),
    ]),
]

HEURES = [time(6, 0), time(8, 30), time(11, 0), time(14, 0), time(17, 30), time(21, 0)]
MAJORATION = {'standard': 1.0, 'confort': 1.25, 'vip': 1.7}


class Command(BaseCommand):
    help = 'Injecte des données de démonstration (compagnies, trajets, comptes de test)'

    @transaction.atomic
    def handle(self, *args, **options):
        if not Ligne.objects.exists():
            call_command('seed_donnees')
        random.seed(2026)
        comptes = self._comptes()
        bus = self._compagnies()
        self._lignes_retour()
        trajets = self._trajets(bus)
        self._exemples(comptes, trajets)
        call_command('seed_bannieres')
        self.stdout.write(self.style.SUCCESS('\nDonnées de démonstration prêtes :'))
        for email, mdp, *_ in COMPTES:
            self.stdout.write(f'  {email:<24} {mdp}')

    def _comptes(self):
        comptes = {}
        for email, mdp, prenom, nom, role in COMPTES:
            user, cree = User.objects.get_or_create(email=email, defaults={
                'prenom': prenom, 'nom': nom, 'role': role, 'is_verified': True,
                'telephone': '07' + ''.join(random.choice('0123456789') for _ in range(8)),
                'is_staff': role == 'admin', 'is_superuser': role == 'admin'})
            if cree:
                user.set_password(mdp)
                user.save()
            comptes[role] = user
        return comptes

    def _compagnies(self):
        tous = []
        aujourd_hui = timezone.now().date()
        for nom, email, tel, cars in COMPAGNIES:
            t, _ = Transporteur.objects.get_or_create(nom=nom, defaults={
                'email': email, 'telephone': tel, 'est_verifie': True, 'note_moyenne': round(random.uniform(3.8, 4.8), 1)})
            for immat, modele, capacite, classe, equipements in cars:
                b, _ = Bus.objects.get_or_create(immatriculation=immat, defaults={
                    'transporteur': t, 'modele': modele, 'capacite': capacite, 'classe': classe,
                    'assurance_expiration': aujourd_hui + timedelta(days=300),
                    'visite_technique_expiration': aujourd_hui + timedelta(days=200),
                    **{f'a_{e}': True for e in equipements}})
                tous.append(b)
        return tous

    def _lignes_retour(self):
        """Chaque ligne existe dans les deux sens, avec la gare principale de la ville de départ."""
        for l in list(Ligne.objects.select_related('depart', 'arrivee')):
            Ligne.objects.get_or_create(depart=l.arrivee, arrivee=l.depart, defaults={
                'distance_km': l.distance_km, 'duree_estimee_minutes': l.duree_estimee_minutes,
                'est_populaire': l.est_populaire})
        for l in Ligne.objects.filter(gare_depart__isnull=True):
            gare = Gare.objects.filter(ville=l.depart).order_by('-est_principale').first()
            if gare:
                l.gare_depart = gare
                l.save(update_fields=['gare_depart'])

    def _trajets(self, bus):
        crees = []
        tz = timezone.get_current_timezone()
        lignes = list(Ligne.objects.filter(est_active=True).select_related('depart', 'arrivee'))
        for jour in range(-2, 8):
            date = timezone.localdate() + timedelta(days=jour)
            for ligne in lignes:
                heures = HEURES if ligne.est_populaire else HEURES[::2]
                for h in heures:
                    depart = datetime.combine(date, h, tzinfo=tz)
                    if Trajet.objects.filter(ligne=ligne, heure_depart=depart).exists():
                        continue
                    car = random.choice(bus)
                    duree = ligne.duree_estimee_minutes or 240
                    base = max(2000, round((ligne.distance_km or 250) * 11 / 100) * 100)
                    prix = int(round(base * MAJORATION[car.classe] / 100) * 100)
                    passe = depart < timezone.now() - timedelta(hours=duree / 60)
                    trajet = Trajet.objects.create(
                        ligne=ligne, bus=car, transporteur=car.transporteur, heure_depart=depart,
                        heure_arrivee_estimee=depart + timedelta(minutes=duree), prix_fcfa=prix,
                        prix_promo_fcfa=int(prix * 0.85) if random.random() < 0.12 else None,
                        statut=Trajet.Statut.TERMINE if passe else Trajet.Statut.PLANIFIE,
                        heure_arrivee_reelle=depart + timedelta(minutes=duree + 10) if passe else None,
                        note_moyenne=round(random.uniform(3.6, 4.9), 1), nombre_avis=random.randint(4, 180))
                    Siege.generer_pour_trajet(trajet)
                    # Remplissage aléatoire pour un rendu réaliste
                    sieges = list(trajet.sieges.all())
                    occupes = random.sample(sieges, k=random.randint(0, int(len(sieges) * 0.8)))
                    Siege.objects.filter(id__in=[s.id for s in occupes]).update(statut=Siege.Statut.OCCUPE)
                    crees.append(trajet)
        self.stdout.write(f'  {len(crees)} trajets créés')
        return crees

    def _exemples(self, comptes, trajets):
        chauffeur, voyageur = comptes['chauffeur'], comptes['voyageur']
        if Trajet.objects.filter(chauffeur=chauffeur).exists():
            return
        maintenant = timezone.now()
        a_venir = list(Trajet.objects.filter(heure_depart__gt=maintenant + timedelta(hours=1),
                                             statut=Trajet.Statut.PLANIFIE).order_by('heure_depart'))
        passes = list(Trajet.objects.filter(statut=Trajet.Statut.TERMINE).order_by('-heure_depart'))
        if not a_venir or not passes:
            return
        # Le chauffeur : 3 prochains trajets + 2 trajets effectués
        for t in a_venir[:3] + passes[:2]:
            t.chauffeur = chauffeur
            t.save(update_fields=['chauffeur'])
        # Passagers sur le prochain trajet du chauffeur, réservation du voyageur à venir et passée
        for t, n in [(a_venir[0], 4), (passes[0], 2)]:
            self._reserver(voyageur, t, n)
        prenoms = ['Aya', 'Ibrahim', 'Mariam', 'Yao', 'Fatou', 'Koffi', 'Adjoua', 'Seydou', 'Aminata', 'Jean-Marc', 'Salimata', 'Didier']
        noms = ['Koné', 'Diallo', 'Coulibaly', 'Kouassi', 'Bamba', 'Yao', 'Touré', 'Ouattara', 'Kouamé', 'Traoré', 'Brou', 'Gbagbo']
        clients = []
        for i, (pr, nm) in enumerate(zip(prenoms, noms)):
            client, _ = User.objects.get_or_create(email=f'client{i + 1}@tambour.ci', defaults={
                'prenom': pr, 'nom': nm, 'is_verified': True, 'telephone': f'07{random.randint(10000000, 99999999)}'})
            clients.append(client)
        for client in clients[:3]:
            self._reserver(client, a_venir[0], 2)
        # Activité des 7 derniers jours (tableau de bord, rapports)
        for _ in range(60):
            res = self._reserver(random.choice(clients), random.choice(a_venir[:200]), random.randint(1, 3))
            if res:
                quand = maintenant - timedelta(days=random.randint(0, 6), hours=random.randint(0, 12))
                Reservation.objects.filter(pk=res.pk).update(created_at=quand)
                Paiement.objects.filter(reservation=res).update(created_at=quand, confirme_le=quand)

    @staticmethod
    def _reserver(user, trajet, nb):
        from reservations.models import PlacesEpuisees
        from reservations.views import calculer_devis
        if places_disponibles(trajet) < nb:
            return None
        devis = calculer_devis(trajet, nb)
        res = Reservation.objects.create(user=user, trajet=trajet, nb_passagers=nb, email_payeur=user.email,
                                         montant_billets=devis['montant_billets'], frais_service=devis['frais_service'],
                                         montant_total=devis['montant_total'])
        for i in range(1, nb + 1):
            Passager.objects.create(reservation=res, prenom=user.prenom if i == 1 else f'Accompagnant {i}',
                                    nom=user.nom, telephone=user.telephone or '0700000000', ordre=i)
        try:
            res.confirmer()   # attribue les sièges et émet les billets, comme après un paiement
        except PlacesEpuisees:
            res.delete()
            return None
        Paiement.objects.create(
            reservation=res, user=user, montant=res.montant_total, statut=Paiement.Statut.SUCCES,
            methode=random.choice(['orange_money', 'mtn_momo', 'moov_money', 'wave', 'wave', 'carte']),
            telephone=user.telephone or '0700000000', confirme_le=timezone.now(),
            reference=f'PAY{res.reference}')
        user.nb_voyages += 1
        user.save(update_fields=['nb_voyages'])
        return res
