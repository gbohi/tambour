from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from reservations.models import Reservation
from tambour_backend.tests_utils import creer_user, creer_trajet
from transport.models import Trajet, Ville
from .models import PositionGPS
from .services import etat_suivi, distance_m

ABIDJAN = (5.36, -4.0083)
BOUAKE = (7.6899, -5.0317)


class SuiviTempsReelTests(TestCase):
    def setUp(self):
        self.chauffeur = creer_user('chauffeur@tambour.ci', role='chauffeur')
        self.voyageur = creer_user('voyageur@tambour.ci')
        self.autre = creer_user('autre@tambour.ci')
        self.trajet = creer_trajet()
        Ville.objects.filter(nom='Abidjan').update(latitude=ABIDJAN[0], longitude=ABIDJAN[1])
        Ville.objects.filter(nom='Bouaké').update(latitude=BOUAKE[0], longitude=BOUAKE[1])
        self.trajet.chauffeur = self.chauffeur
        self.trajet.save()
        c = APIClient(); c.force_authenticate(self.voyageur)
        c.post('/api/v1/reservations/', {'trajet_id': str(self.trajet.id), 'passagers': [
            {'prenom': 'Awa', 'nom': 'Koné', 'telephone': '0707070707'}]}, format='json')
        Reservation.objects.get().confirmer()
        self.c_chauffeur = APIClient(); self.c_chauffeur.force_authenticate(self.chauffeur)
        self.c_voyageur = APIClient(); self.c_voyageur.force_authenticate(self.voyageur)
        self.url_suivi = f'/api/v1/trajets/{self.trajet.id}/suivi/'
        self.url_position = f'/api/v1/chauffeur/trajets/{self.trajet.id}/position/'

    def _demarrer(self):
        self.c_chauffeur.post(f'/api/v1/chauffeur/trajets/{self.trajet.id}/demarrer/')
        self.trajet.refresh_from_db()

    def test_acces_reserve_aux_voyageurs_du_trajet(self):
        self.assertEqual(self.c_voyageur.get(self.url_suivi).status_code, 200)
        self.assertEqual(self.c_chauffeur.get(self.url_suivi).status_code, 200)
        autre = APIClient(); autre.force_authenticate(self.autre)
        self.assertEqual(autre.get(self.url_suivi).status_code, 403)
        self.assertEqual(APIClient().get(self.url_suivi).status_code, 401)

    def test_avant_le_depart(self):
        d = self.c_voyageur.get(self.url_suivi).json()['data']
        self.assertEqual(d['phase'], 'a_venir')
        self.assertGreater(d['depart_dans_minutes'], 60 * 24)
        self.assertIsNone(d['position'])

    def test_position_refusee_si_trajet_non_demarre(self):
        r = self.c_chauffeur.post(self.url_position, {'latitude': 6.0, 'longitude': -4.5}, format='json')
        self.assertEqual(r.status_code, 409)

    def test_position_reservee_au_chauffeur_du_trajet(self):
        self._demarrer()
        r = self.c_voyageur.post(self.url_position, {'latitude': 6.0, 'longitude': -4.5}, format='json')
        self.assertEqual(r.status_code, 403)

    def test_eta_calculee_depuis_le_gps(self):
        self._demarrer()
        # À mi-chemin, deux positions à 70 km/h
        mi = ((ABIDJAN[0] + BOUAKE[0]) / 2, (ABIDJAN[1] + BOUAKE[1]) / 2)
        for lat in (mi[0] - 0.01, mi[0]):
            r = self.c_chauffeur.post(self.url_position, {'latitude': lat, 'longitude': mi[1], 'vitesse_kmh': 70},
                                      format='json')
            self.assertEqual(r.status_code, 201, r.content)
        retour = r.json()['data']
        self.assertEqual(retour['source'], 'gps')
        restant_km = distance_m(*mi, *BOUAKE) * 1.25 / 1000
        self.assertAlmostEqual(retour['minutes_restantes'], restant_km / 70 * 60, delta=2)
        d = self.c_voyageur.get(self.url_suivi).json()['data']
        self.assertEqual(d['phase'], 'en_route')
        self.assertTrue(40 <= d['progression'] <= 60, d['progression'])
        self.assertEqual(len(d['trace']), 2)
        self.assertEqual(d['position']['latitude'], round(mi[0], 6))

    def test_sans_gps_on_suit_l_horaire(self):
        self._demarrer()
        Trajet.objects.filter(pk=self.trajet.pk).update(demarre_le=timezone.now() - timedelta(hours=1))
        self.trajet.refresh_from_db()
        d = etat_suivi(self.trajet)
        self.assertEqual(d['source'], 'horaire')
        self.assertAlmostEqual(d['minutes_restantes'], 180, delta=1)   # 4 h prévues, 1 h écoulée
        self.assertEqual(d['progression'], 25)

    def test_gps_perime_ignore(self):
        self._demarrer()
        PositionGPS.objects.create(trajet=self.trajet, latitude=7.6, longitude=-5.0,
                                   enregistre_le=timezone.now() - timedelta(minutes=20))
        self.assertEqual(etat_suivi(self.trajet)['source'], 'horaire')

    def test_arrive(self):
        self._demarrer()
        self.c_chauffeur.post(f'/api/v1/chauffeur/trajets/{self.trajet.id}/terminer/')
        d = self.c_voyageur.get(self.url_suivi).json()['data']
        self.assertEqual((d['phase'], d['progression'], d['minutes_restantes']), ('arrive', 100, 0))
