from datetime import timedelta
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from tambour_backend.tests_utils import creer_user
from .models import Banniere

# Plus petit JPEG valide (1 × 1 px)
JPEG = bytes.fromhex(
    'ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c'
    '20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffc0000b080001000101011100ffc4001f000001050101010101010000'
    '0000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1'
    '082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a7374'
    '75767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1'
    'e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffda0008010100003f00fbd3ffd9')


@override_settings(MEDIA_ROOT='/tmp/tambour-tests-media')
class BannieresTests(TestCase):
    def setUp(self):
        self.admin = APIClient()
        self.admin.force_authenticate(creer_user('admin@tambour.ci', role='admin', is_staff=True))

    def test_admin_cree_une_banniere_avec_image(self):
        r = self.admin.post('/api/v1/admin/bannieres/', {
            'titre': 'Promo Bouaké', 'sous_titre': '-20 % ce week-end', 'action': 'page', 'page': 'fidelite',
            'image': SimpleUploadedFile('promo.jpg', JPEG, content_type='image/jpeg')}, format='multipart')
        self.assertEqual(r.status_code, 201, r.content)
        publiques = APIClient().get('/api/v1/bannieres/').json()['data']['results']
        self.assertEqual(publiques[0]['titre'], 'Promo Bouaké')
        self.assertTrue(publiques[0]['image_url'].startswith('http://testserver/media/bannieres/'))

    def test_seules_les_bannieres_actives_et_en_cours_sont_publiques(self):
        maintenant = timezone.now()
        Banniere.objects.create(titre='Active', ordre=2)
        Banniere.objects.create(titre='Désactivée', est_active=False)
        Banniere.objects.create(titre='Pas encore', debut=maintenant + timedelta(days=1))
        Banniere.objects.create(titre='Terminée', fin=maintenant - timedelta(days=1))
        Banniere.objects.create(titre='En tête', ordre=1)
        titres = [b['titre'] for b in APIClient().get('/api/v1/bannieres/').json()['data']['results']]
        self.assertEqual(titres, ['En tête', 'Active'])

    def test_action_recherche_exige_les_villes(self):
        r = self.admin.post('/api/v1/admin/bannieres/', {'titre': 'X', 'action': 'recherche'}, format='json')
        self.assertEqual(r.status_code, 400)

    def test_reserve_aux_admins(self):
        c = APIClient(); c.force_authenticate(creer_user())
        self.assertEqual(c.post('/api/v1/admin/bannieres/', {'titre': 'X'}, format='json').status_code, 403)
