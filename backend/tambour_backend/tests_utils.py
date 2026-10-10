"""Fabriques de données partagées par les tests."""
from datetime import timedelta
from django.contrib.auth import get_user_model
from django.utils import timezone
from transport.models import Ville, Transporteur, Bus, Ligne, Trajet, Siege

User = get_user_model()


def creer_user(email='client@tambour.ci', **kwargs):
    defaults = {'prenom': 'Awa', 'nom': 'Koné', 'telephone': '0707070707'}
    defaults.update(kwargs)
    return User.objects.create_user(email=email, password='MotDePasse!2026', **defaults)


def creer_trajet(capacite=12, prix=3500):
    abj, _ = Ville.objects.get_or_create(nom='Abidjan', defaults={'region': 'Lagunes'})
    bke, _ = Ville.objects.get_or_create(nom='Bouaké', defaults={'region': 'Gbêkê'})
    ligne, _ = Ligne.objects.get_or_create(depart=abj, arrivee=bke, defaults={'est_populaire': True,
                                                                            'duree_estimee_minutes': 210})
    transporteur, _ = Transporteur.objects.get_or_create(
        nom='UTB Test', defaults={'email': 'utb@test.ci', 'telephone': '0101010101'})
    bus = Bus.objects.create(transporteur=transporteur, immatriculation=f'AB-{Bus.objects.count():04d}-CI',
                             modele='Coaster', capacite=capacite,
                             assurance_expiration=timezone.now().date() + timedelta(days=365),
                             visite_technique_expiration=timezone.now().date() + timedelta(days=365))
    depart = timezone.now() + timedelta(days=2)
    trajet = Trajet.objects.create(ligne=ligne, bus=bus, transporteur=transporteur, prix_fcfa=prix,
                                   heure_depart=depart, heure_arrivee_estimee=depart + timedelta(hours=4))
    Siege.generer_pour_trajet(trajet)
    return trajet
