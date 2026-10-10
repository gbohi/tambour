from django.test import TestCase
from rest_framework.test import APIClient

from tambour_backend.tests_utils import creer_user, creer_trajet
from transport.models import Siege
from .models import Reservation


def passagers(n):
    return [{'prenom': f'P{i}', 'nom': 'Test', 'telephone': '0707070707'} for i in range(n)]


class AttributionSiegesTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.client.force_authenticate(creer_user())
        self.trajet = creer_trajet(capacite=12)

    def reserver(self, n):
        return self.client.post('/api/v1/reservations/', {
            'trajet_id': str(self.trajet.id), 'passagers': passagers(n)}, format='json')

    def test_sieges_attribues_automatiquement_et_contigus(self):
        r = self.reserver(3)
        self.assertEqual(r.status_code, 201, r.content)
        res = Reservation.objects.get()
        numeros = [p.siege.numero for p in res.passagers.order_by('ordre')]
        self.assertEqual(numeros, ['1A', '1B', '1C'])
        self.assertEqual(Siege.objects.filter(trajet=self.trajet, statut=Siege.Statut.RESERVE).count(), 3)

    def test_deux_reservations_ne_partagent_pas_de_siege(self):
        self.reserver(2)
        self.reserver(2)
        numeros = [p.siege.numero for r in Reservation.objects.all() for p in r.passagers.all()]
        self.assertEqual(len(numeros), len(set(numeros)))

    def test_trajet_complet(self):
        self.assertEqual(self.reserver(9).status_code, 201)
        self.assertEqual(self.reserver(3).status_code, 201)
        r = self.reserver(1)
        self.assertEqual(r.status_code, 400)
        self.assertIn('places', r.json()['message'])

    def test_siege_reattribue_apres_expiration(self):
        from django.utils import timezone
        self.reserver(9)
        self.reserver(3)
        Siege.objects.filter(trajet=self.trajet, numero='1A').update(
            reserve_jusqu=timezone.now() - timezone.timedelta(minutes=1))
        r = self.reserver(1)
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual(Siege.objects.get(trajet=self.trajet, numero='1A').passagers.count(), 2)
