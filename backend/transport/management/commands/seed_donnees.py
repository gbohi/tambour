from django.core.management.base import BaseCommand
from transport.models import Ville, Gare, Ligne


class Command(BaseCommand):
    help = "Injecte les donnees initiales de la Cote d'Ivoire"

    def handle(self, *args, **kwargs):
        # Bases initialisées avec l'ancienne version (noms sans accents) : on renomme
        for ancien, nouveau in [('Bouake', 'Bouaké'), ('San-Pedro', 'San-Pédro'), ('Odienne', 'Odienné')]:
            if not Ville.objects.filter(nom=nouveau).exists():
                Ville.objects.filter(nom=ancien).update(nom=nouveau)
        for ancien, nouveau in [("Gare d'Adjame Sud", "Gare d'Adjamé Sud"), ('Gare Routiere de Bouake', 'Gare routière de Bouaké')]:
            if not Gare.objects.filter(nom=nouveau).exists():
                Gare.objects.filter(nom=ancien).update(nom=nouveau)

        self.stdout.write("Injection des villes...")
        villes_data = [
            {'nom': 'Abidjan', 'region': 'Lagunes', 'latitude': 5.3600, 'longitude': -4.0083, 'ordre_affichage': 1},
            {'nom': 'Bouaké', 'region': 'Vallée du Bandama', 'latitude': 7.6899, 'longitude': -5.0317, 'ordre_affichage': 2},
            {'nom': 'Yamoussoukro', 'region': 'Lacs', 'latitude': 6.8276, 'longitude': -5.2893, 'ordre_affichage': 3},
            {'nom': 'Daloa', 'region': 'Haut-Sassandra', 'latitude': 6.8774, 'longitude': -6.4502, 'ordre_affichage': 4},
            {'nom': 'San-Pédro', 'region': 'Bas-Sassandra', 'latitude': 4.7485, 'longitude': -6.6363, 'ordre_affichage': 5},
            {'nom': 'Man', 'region': 'Tonkpi', 'latitude': 7.4126, 'longitude': -7.5535, 'ordre_affichage': 6},
            {'nom': 'Korhogo', 'region': 'Poro', 'latitude': 9.4580, 'longitude': -5.6296, 'ordre_affichage': 7},
            {'nom': 'Aboisso', 'region': 'Sud-Comoé', 'latitude': 5.4665, 'longitude': -3.2073, 'ordre_affichage': 8},
            {'nom': 'Dimbokro', 'region': "N'Zi", 'latitude': 6.6500, 'longitude': -4.7000, 'ordre_affichage': 9},
            {'nom': 'Odienné', 'region': 'Kabadougou', 'latitude': 9.5100, 'longitude': -7.5600, 'ordre_affichage': 10},
        ]
        villes = {}
        for data in villes_data:
            ville, created = Ville.objects.update_or_create(nom=data['nom'], defaults=data)
            villes[data['nom']] = ville
            if created:
                self.stdout.write(f'  OK {ville.nom}')

        self.stdout.write("Injection des gares...")
        gares_data = [
            {'nom': "Gare d'Adjamé Sud", 'ville': 'Abidjan', 'adresse': 'Boulevard de la République, Adjamé', 'latitude': 5.3600, 'longitude': -4.0167, 'telephone': '27 20 37 25 00', 'est_principale': True},
            {'nom': "Gare de Yopougon", 'ville': 'Abidjan', 'adresse': 'Rue des Transporteurs, Yopougon', 'latitude': 5.3453, 'longitude': -4.0714, 'telephone': '27 20 45 12 33', 'est_principale': False},
            {'nom': 'Gare routière de Bouaké', 'ville': 'Bouaké', 'adresse': 'Avenue Houphouët-Boigny', 'latitude': 7.6899, 'longitude': -5.0317, 'telephone': '27 31 63 14 00', 'est_principale': True},
            {'nom': 'Gare de Yamoussoukro', 'ville': 'Yamoussoukro', 'adresse': 'Route de Toumodi', 'latitude': 6.8276, 'longitude': -5.2893, 'telephone': '27 30 64 00 12', 'est_principale': True},
        ]
        for data in gares_data:
            ville_nom = data.pop('ville')
            gare, created = Gare.objects.update_or_create(nom=data['nom'], defaults={**data, 'ville': villes[ville_nom]})
            if created:
                self.stdout.write(f'  OK {gare.nom}')

        self.stdout.write("Injection des lignes populaires...")
        lignes_data = [
            ('Abidjan', 'Bouaké', 320, 210, True),
            ('Abidjan', 'Yamoussoukro', 240, 165, True),
            ('Abidjan', 'San-Pédro', 340, 255, True),
            ('Abidjan', 'Daloa', 380, 240, False),
            ('Abidjan', 'Man', 620, 420, False),
            ('Bouaké', 'Korhogo', 230, 180, False),
            ('Bouaké', 'Yamoussoukro', 160, 90, False),
        ]
        for dep, arr, dist, duree, pop in lignes_data:
            if dep in villes and arr in villes:
                ligne, created = Ligne.objects.update_or_create(depart=villes[dep], arrivee=villes[arr], defaults={'distance_km': dist, 'duree_estimee_minutes': duree, 'est_populaire': pop})
                if created:
                    self.stdout.write(f'  OK {ligne}')

        self.stdout.write(self.style.SUCCESS('\nDonnees injectees avec succes !'))
