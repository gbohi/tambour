from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from reservations.models import Reservation, Billet
from tambour_backend.tests_utils import creer_user, creer_trajet
from transport.models import Trajet


class EspaceChauffeurTests(TestCase):
    def setUp(self):
        self.chauffeur = creer_user('chauffeur@tambour.ci', role='chauffeur')
        self.voyageur = creer_user('voyageur@tambour.ci')
        self.trajet = creer_trajet()
        self.trajet.chauffeur = self.chauffeur
        self.trajet.save()
        # Réservation payée de 2 passagers
        c = APIClient()
        c.force_authenticate(self.voyageur)
        c.post('/api/v1/reservations/', {'trajet_id': str(self.trajet.id), 'passagers': [
            {'prenom': 'Awa', 'nom': 'Koné', 'telephone': '0707070707'},
            {'prenom': 'Yao', 'nom': 'Kouassi', 'telephone': '0505050505'}]}, format='json')
        self.res = Reservation.objects.get()
        self.res.confirmer()
        self.billet = Billet.objects.get(reservation=self.res, numero=1)
        self.client = APIClient()
        self.client.force_authenticate(self.chauffeur)

    def test_reserve_aux_chauffeurs(self):
        c = APIClient()
        c.force_authenticate(self.voyageur)
        self.assertEqual(c.get('/api/v1/chauffeur/trajets/').status_code, 403)

    def test_mes_trajets_et_passagers(self):
        data = self.client.get('/api/v1/chauffeur/trajets/').json()['data']
        self.assertEqual(len(data['results']), 1)
        self.assertEqual(data['results'][0]['nb_passagers'], 2)
        detail = self.client.get(f'/api/v1/chauffeur/trajets/{self.trajet.id}/').json()['data']
        self.assertEqual([p['siege'] for p in detail['passagers']], ['1A', '1B'])
        self.assertFalse(detail['passagers'][0]['embarque'])

    def test_scan_qr(self):
        r = self.client.post('/api/v1/chauffeur/scanner/', {
            'trajet_id': str(self.trajet.id), 'qr_data': self.billet.qr_data}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(r.json()['data']['siege'], '1A')
        # Deuxième scan refusé
        r = self.client.post('/api/v1/chauffeur/scanner/', {
            'trajet_id': str(self.trajet.id), 'qr_data': self.billet.qr_data}, format='json')
        self.assertEqual(r.status_code, 409)
        detail = self.client.get(f'/api/v1/chauffeur/trajets/{self.trajet.id}/').json()['data']
        self.assertEqual(detail['nb_embarques'], 1)

    def test_saisie_manuelle(self):
        r = self.client.post('/api/v1/chauffeur/scanner/', {
            'trajet_id': str(self.trajet.id), 'reference_billet': f'{self.res.reference}-P2'.lower()}, format='json')
        self.assertEqual(r.status_code, 200, r.content)

    def test_billet_d_un_autre_trajet(self):
        autre = creer_trajet()
        autre.chauffeur = self.chauffeur
        autre.save()
        r = self.client.post('/api/v1/chauffeur/scanner/', {
            'trajet_id': str(autre.id), 'qr_data': self.billet.qr_data}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertIn('Mauvais car', r.json()['message'])

    def test_billet_non_paye_et_qr_inconnu(self):
        self.res.statut = Reservation.Statut.EN_ATTENTE
        self.res.save()
        r = self.client.post('/api/v1/chauffeur/scanner/', {
            'trajet_id': str(self.trajet.id), 'qr_data': self.billet.qr_data}, format='json')
        self.assertEqual(r.status_code, 400)
        r = self.client.post('/api/v1/chauffeur/scanner/', {
            'trajet_id': str(self.trajet.id), 'qr_data': 'https://exemple.com'}, format='json')
        self.assertEqual(r.status_code, 400)

    def test_demarrer_terminer_et_historique(self):
        self.assertEqual(self.client.post(f'/api/v1/chauffeur/trajets/{self.trajet.id}/demarrer/').status_code, 200)
        self.assertEqual(self.client.post(f'/api/v1/chauffeur/trajets/{self.trajet.id}/terminer/').status_code, 200)
        self.trajet.refresh_from_db()
        self.assertEqual(self.trajet.statut, Trajet.Statut.TERMINE)
        self.assertIsNotNone(self.trajet.heure_arrivee_reelle)
        self.assertEqual(self.client.get('/api/v1/chauffeur/trajets/').json()['data']['results'], [])
        hist = self.client.get('/api/v1/chauffeur/trajets/', {'periode': 'historique'}).json()['data']
        self.assertEqual(len(hist['results']), 1)
        self.assertEqual(hist['stats']['nb_passagers'], 2)

    def test_un_chauffeur_ne_voit_pas_les_trajets_des_autres(self):
        autre = creer_user('autre@tambour.ci', role='chauffeur')
        c = APIClient()
        c.force_authenticate(autre)
        self.assertEqual(c.get(f'/api/v1/chauffeur/trajets/{self.trajet.id}/').status_code, 404)
        self.assertEqual(c.post(f'/api/v1/chauffeur/trajets/{self.trajet.id}/terminer/').status_code, 404)


class NotationTrajetTests(TestCase):
    def setUp(self):
        self.voyageur = creer_user()
        self.trajet = creer_trajet()
        self.client = APIClient()
        self.client.force_authenticate(self.voyageur)
        self.client.post('/api/v1/reservations/', {'trajet_id': str(self.trajet.id), 'passagers': [
            {'prenom': 'Awa', 'nom': 'Koné', 'telephone': '0707070707'}]}, format='json')
        self.res = Reservation.objects.get()
        self.res.confirmer()

    def noter(self, **extra):
        return self.client.post('/api/v1/avis/', {'reservation_id': str(self.res.id), 'note': 4,
                                                  'commentaire': 'Bon voyage', **extra}, format='json')

    def test_pas_avant_le_depart(self):
        self.assertEqual(self.noter().status_code, 400)
        res = self.client.get('/api/v1/reservations/').json()['data'][0]
        self.assertFalse(res['peut_etre_notee'])

    def test_noter_apres_le_trajet(self):
        Trajet.objects.filter(pk=self.trajet.pk).update(heure_depart=timezone.now() - timedelta(hours=5),
                                                         statut=Trajet.Statut.TERMINE)
        res = self.client.get('/api/v1/reservations/').json()['data'][0]
        self.assertTrue(res['peut_etre_notee'])
        self.assertTrue(res['passagers'][0]['billet']['qr_data'].startswith('TAMBOUR|'))
        r = self.noter(note_ponctualite=5, note_confort=3, note_proprete=4)
        self.assertEqual(r.status_code, 201, r.content)
        self.trajet.refresh_from_db()
        self.assertEqual(float(self.trajet.note_moyenne), 4.0)
        res = self.client.get('/api/v1/reservations/').json()['data'][0]
        self.assertEqual(res['avis_note'], 4)
        self.assertFalse(res['peut_etre_notee'])
        self.assertEqual(self.noter().status_code, 400)  # une seule fois


class CreationCompteParAdminTests(TestCase):
    def test_creer_chauffeur(self):
        admin = creer_user('admin@tambour.ci', role='admin', is_staff=True)
        c = APIClient()
        c.force_authenticate(admin)
        r = c.post('/api/v1/auth/users/', {'email': 'Moussa@tambour.ci', 'prenom': 'Moussa', 'nom': 'Traoré',
                                            'password': 'Chauffeur!2026', 'role': 'chauffeur'}, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual(r.json()['data']['role'], 'chauffeur')
        trajet = creer_trajet()
        r = c.patch(f'/api/v1/trajets/{trajet.id}/', {'chauffeur': r.json()['data']['id']}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        trajet.refresh_from_db()
        self.assertEqual(trajet.chauffeur.email, 'moussa@tambour.ci')
