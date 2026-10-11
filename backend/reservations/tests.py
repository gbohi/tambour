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


class ParcoursCompletTests(TestCase):
    """Réservation → paiement (mode simulation) → billets confirmés, sièges occupés, points gagnés."""

    def test_reserver_et_payer(self):
        from django.test import override_settings
        user = creer_user()
        trajet = creer_trajet(prix=4000)
        c = APIClient()
        c.force_authenticate(user)
        r = c.post('/api/v1/reservations/', {'trajet_id': str(trajet.id), 'passagers': passagers(2)}, format='json')
        res_id = r.json()['data']['id']
        with override_settings(PAIEMENT_SIMULATION=True):
            r = c.post('/api/v1/paiements/initier/', {'reservation_id': res_id, 'methode': 'wave',
                                                       'telephone': '0707070707'}, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        self.assertTrue(r.json()['data']['simulation'])
        res = Reservation.objects.get(pk=res_id)
        self.assertEqual(res.statut, Reservation.Statut.CONFIRMEE)
        self.assertEqual(res.billets.count(), 2)
        self.assertEqual(Siege.objects.filter(trajet=trajet, statut=Siege.Statut.OCCUPE).count(), 2)
        user.refresh_from_db()
        self.assertEqual(user.points_fidelite, 8)  # 8 000 F → 8 points
        self.assertTrue(user.mouvements_points.filter(motif='voyage').exists())


    def test_payer_avec_moov_money(self):
        from django.test import override_settings
        from paiements.models import Paiement
        user = creer_user()
        trajet = creer_trajet(prix=3000)
        c = APIClient()
        c.force_authenticate(user)
        res_id = c.post('/api/v1/reservations/', {'trajet_id': str(trajet.id), 'passagers': passagers(1)},
                        format='json').json()['data']['id']
        with override_settings(PAIEMENT_SIMULATION=True):
            r = c.post('/api/v1/paiements/initier/', {'reservation_id': res_id, 'methode': 'moov_money',
                                                       'telephone': '0101010101'}, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual(Paiement.objects.get(reservation_id=res_id).methode, 'moov_money')
        self.assertEqual(Reservation.objects.get(pk=res_id).statut, Reservation.Statut.CONFIRMEE)

class RechercheTrajetTests(TestCase):
    """La recherche publique ne doit pas être captée par la route détail du routeur DRF."""

    def test_recherche_publique(self):
        trajet = creer_trajet()
        r = APIClient().post('/api/v1/trajets/recherche/', {
            'depart': str(trajet.ligne.depart_id), 'arrivee': str(trajet.ligne.arrivee_id),
            'date': trajet.heure_depart.date().isoformat(), 'passagers': 1}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual([t['id'] for t in r.json()['data']['results']], [str(trajet.id)])
