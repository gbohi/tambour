"""Crée les bannières d'accueil de démonstration (sans doublon) : python manage.py seed_bannieres"""
from pathlib import Path
from django.core.files import File
from django.core.management.base import BaseCommand

from plateforme.models import Banniere
from transport.models import Ville

DEMO = Path(__file__).resolve().parents[2] / 'demo'


class Command(BaseCommand):
    help = "Crée les bannières d'accueil de démonstration."

    def handle(self, *args, **options):
        villes = {v.nom: v for v in Ville.objects.filter(nom__in=['Abidjan', 'Yamoussoukro'])}
        bannieres = [
            dict(titre='Abidjan → Yamoussoukro', sous_titre='Dès 2 600 F, départs toute la journée',
                 texte_bouton='Voir les départs', action=Banniere.Action.RECHERCHE, couleur_fond='#0F4A3B',
                 depart=villes.get('Abidjan'), arrivee=villes.get('Yamoussoukro'), image='banniere-3.jpg'),
            dict(titre='Parrainez vos amis', sous_titre='500 points pour vous, 200 pour eux',
                 texte_bouton='Inviter', action=Banniere.Action.PAGE, page=Banniere.Page.FIDELITE,
                 couleur_fond='#F2A93B', image='banniere-1.jpg'),
            dict(titre='Suivez votre car en direct', sous_titre="Heure d'arrivée et position en temps réel",
                 action=Banniere.Action.AUCUNE, couleur_fond='#E7F0EC', image='banniere-4.jpg'),
            dict(titre='Payez en Mobile Money', sous_titre='Orange Money, Wave, MTN MoMo, Moov Money',
                 action=Banniere.Action.AUCUNE, couleur_fond='#072A21', image='banniere-2.jpg'),
        ]
        crees = 0
        for ordre, b in enumerate(bannieres, start=1):
            if b['action'] == Banniere.Action.RECHERCHE and not (b['depart'] and b['arrivee']):
                continue
            if Banniere.objects.filter(titre=b['titre']).exists():
                continue
            image = b.pop('image')
            banniere = Banniere(ordre=ordre, **b)
            with open(DEMO / image, 'rb') as f:
                banniere.image.save(image, File(f), save=False)
            banniere.save()
            crees += 1
        self.stdout.write(self.style.SUCCESS(f'{crees} bannière(s) créée(s).'))
