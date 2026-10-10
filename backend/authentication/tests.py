from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from tambour_backend.tests_utils import creer_user
from .models import User, MouvementPoints


def inscription(client, email, **extra):
    data = {'prenom': 'Yao', 'nom': 'Kouassi', 'email': email, 'telephone': '0505050505',
            'password': 'MotDePasse!2026', 'password_confirm': 'MotDePasse!2026', **extra}
    return client.post('/api/v1/auth/register/', data, format='json')


@override_settings(POINTS_PARRAIN=500, POINTS_FILLEUL=200)
class ParrainageTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.parrain = creer_user('parrain@tambour.ci')

    def test_chaque_utilisateur_a_un_code(self):
        self.assertRegex(self.parrain.code_parrainage, r'^TB[A-Z2-9]{6}$')

    def test_inscription_avec_code_credite_les_deux(self):
        r = inscription(self.client, 'filleul@tambour.ci', code_parrainage=self.parrain.code_parrainage.lower())
        self.assertEqual(r.status_code, 201, r.content)
        filleul = User.objects.get(email='filleul@tambour.ci')
        self.parrain.refresh_from_db()
        self.assertEqual(filleul.parrain, self.parrain)
        self.assertEqual(filleul.points_fidelite, 200)
        self.assertEqual(self.parrain.points_fidelite, 500)
        self.assertTrue(MouvementPoints.objects.filter(user=self.parrain, motif='parrainage', points=500).exists())
        self.assertTrue(MouvementPoints.objects.filter(user=filleul, motif='bienvenue', points=200).exists())

    def test_code_invalide_refuse(self):
        r = inscription(self.client, 'x@tambour.ci', code_parrainage='TBNOPE00')
        self.assertEqual(r.status_code, 400)
        self.assertFalse(User.objects.filter(email='x@tambour.ci').exists())

    def test_inscription_sans_code(self):
        r = inscription(self.client, 'seul@tambour.ci')
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual(User.objects.get(email='seul@tambour.ci').points_fidelite, 0)

    def test_verifier_code(self):
        r = self.client.get('/api/v1/auth/parrainage/verifier/', {'code': self.parrain.code_parrainage})
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()['data']['parrain_prenom'], 'Awa')
        self.assertEqual(self.client.get('/api/v1/auth/parrainage/verifier/', {'code': 'zzz'}).status_code, 404)

    def test_page_fidelite(self):
        inscription(self.client, 'f1@tambour.ci', code_parrainage=self.parrain.code_parrainage)
        self.parrain.refresh_from_db()
        self.client.force_authenticate(self.parrain)
        data = self.client.get('/api/v1/auth/fidelite/').json()['data']
        self.assertEqual(data['points'], 500)
        self.assertEqual(data['nb_filleuls'], 1)
        self.assertEqual(data['points_parrainage'], 500)
        self.assertEqual(data['code_parrainage'], self.parrain.code_parrainage)
        self.assertIn(self.parrain.code_parrainage, data['message_partage'])
        self.assertEqual(len(data['historique']), 1)
