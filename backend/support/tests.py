from django.test import TestCase
from rest_framework.test import APIClient

from tambour_backend.tests_utils import creer_user, creer_trajet
from reservations.models import Reservation
from .models import Reclamation, MessageSupport, AvisApplication


class SupportTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = creer_user()
        self.admin = creer_user('admin@tambour.ci', role='admin', is_staff=True)

    def test_faq_publique(self):
        data = self.client.get('/api/v1/support/faq/').json()['data']
        self.assertTrue(data['categories'])
        self.assertTrue(data['categories'][0]['questions'])

    def test_contact(self):
        self.assertIn('telephone', self.client.get('/api/v1/support/contact/').json()['data'])
        self.client.force_authenticate(self.user)
        r = self.client.post('/api/v1/support/contact/', {'sujet': 'Question', 'message': 'Bonjour'}, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        msg = MessageSupport.objects.get()
        self.assertEqual(msg.email, self.user.email)

    def test_contact_anonyme_sans_coordonnees_refuse(self):
        r = self.client.post('/api/v1/support/contact/', {'nom': 'X', 'sujet': 'S', 'message': 'M'}, format='json')
        self.assertEqual(r.status_code, 400)

    def test_reclamation_liee_a_une_reservation(self):
        trajet = creer_trajet()
        res = Reservation.objects.create(user=self.user, trajet=trajet, montant_total=3500)
        self.client.force_authenticate(self.user)
        r = self.client.post('/api/v1/support/reclamations/', {
            'categorie': 'paiement', 'sujet': 'Débité deux fois', 'description': 'Détails',
            'reference_reservation': res.reference.lower()}, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        rec = Reclamation.objects.get()
        self.assertEqual(rec.reservation, res)
        self.assertTrue(rec.reference.startswith('REC'))
        self.assertEqual(len(self.client.get('/api/v1/support/reclamations/').json()['data']['results']), 1)

    def test_reclamation_reference_inconnue(self):
        self.client.force_authenticate(self.user)
        r = self.client.post('/api/v1/support/reclamations/', {
            'categorie': 'autre', 'sujet': 'S', 'description': 'D', 'reference_reservation': 'TB000'}, format='json')
        self.assertEqual(r.status_code, 400)

    def test_traitement_reclamation_par_admin(self):
        rec = Reclamation.objects.create(user=self.user, categorie='autre', sujet='S', description='D')
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.patch(f'/api/v1/support/reclamations/{rec.id}/', {'statut': 'resolue'},
                                           format='json').status_code, 403)
        self.client.force_authenticate(self.admin)
        r = self.client.patch(f'/api/v1/support/reclamations/{rec.id}/',
                              {'statut': 'resolue', 'reponse': 'Remboursé'}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        rec.refresh_from_db()
        self.assertEqual(rec.statut, 'resolue')
        self.assertIsNotNone(rec.traitee_le)

    def test_noter_application(self):
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.post('/api/v1/support/avis-app/', {'note': 4}, format='json').status_code, 201)
        self.assertEqual(self.client.post('/api/v1/support/avis-app/', {'note': 5, 'commentaire': 'Top'},
                                          format='json').status_code, 200)
        self.assertEqual(AvisApplication.objects.get().note, 5)
        self.assertEqual(self.client.post('/api/v1/support/avis-app/', {'note': 6}, format='json').status_code, 400)
        self.client.force_authenticate(self.admin)
        self.assertEqual(self.client.get('/api/v1/support/avis-app/').json()['data']['moyenne'], 5)


class LignesPopulairesTests(TestCase):
    def test_liste(self):
        creer_trajet()
        data = APIClient().get('/api/v1/lignes/populaires/').json()['data']['results']
        self.assertEqual(data[0]['depart'], 'Abidjan')
        self.assertEqual(data[0]['prix_min'], 3500)
