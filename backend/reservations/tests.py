from django.test import TestCase
from rest_framework.test import APIClient

from tambour_backend.tests_utils import creer_user, creer_trajet
from decimal import Decimal
from plateforme.models import ParametresPlateforme
from transport.models import Siege, places_disponibles
from .models import Reservation


def passagers(n):
    return [{'prenom': f'P{i}', 'nom': 'Test', 'telephone': '0707070707'} for i in range(n)]


class AttributionSiegesTests(TestCase):
    """Places retenues pendant le paiement, sièges attribués seulement une fois le paiement validé."""

    def setUp(self):
        self.client = APIClient()
        self.client.force_authenticate(creer_user())
        self.trajet = creer_trajet(capacite=12)

    def reserver(self, n):
        return self.client.post('/api/v1/reservations/', {
            'trajet_id': str(self.trajet.id), 'passagers': passagers(n)}, format='json')

    def test_aucun_siege_avant_le_paiement(self):
        r = self.reserver(3)
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual([p['siege_numero'] for p in r.json()['data']['passagers']], [None, None, None])
        self.assertFalse(Siege.objects.filter(trajet=self.trajet).exclude(statut=Siege.Statut.LIBRE).exists())
        self.assertEqual(places_disponibles(self.trajet), 9)   # places retenues pendant le paiement

    def test_sieges_attribues_au_paiement_cote_a_cote(self):
        self.reserver(3)
        res = Reservation.objects.get()
        res.confirmer()
        numeros = [p.siege.numero for p in res.passagers.order_by('ordre')]
        self.assertEqual(numeros, ['1A', '1B', '1C'])
        self.assertEqual(Siege.objects.filter(trajet=self.trajet, statut=Siege.Statut.OCCUPE).count(), 3)
        self.assertEqual(res.billets.count(), 3)
        self.assertIn('|1A|', res.billets.get(numero=1).qr_data)

    def test_deux_reservations_ne_partagent_pas_de_siege(self):
        self.reserver(2)
        self.reserver(2)
        for res in Reservation.objects.all():
            res.confirmer()
        numeros = [p.siege.numero for r in Reservation.objects.all() for p in r.passagers.all()]
        self.assertEqual(len(numeros), 4)
        self.assertEqual(len(numeros), len(set(numeros)))

    def test_trajet_complet(self):
        self.assertEqual(self.reserver(9).status_code, 201)
        self.assertEqual(self.reserver(3).status_code, 201)
        r = self.reserver(1)
        self.assertEqual(r.status_code, 400)
        self.assertIn('places', r.json()['message'])

    def test_places_liberees_apres_expiration(self):
        from django.utils import timezone
        self.reserver(9)
        self.reserver(3)
        Reservation.objects.filter(nb_passagers=3).update(expire_at=timezone.now() - timezone.timedelta(minutes=1))
        self.assertEqual(self.reserver(1).status_code, 201)

    def test_paiement_tardif_sans_place_rembourse(self):
        from django.utils import timezone
        from paiements.models import Paiement
        from paiements.views import _confirmer_paiement
        self.reserver(3)
        tardive = Reservation.objects.get()
        Reservation.objects.filter(pk=tardive.pk).update(expire_at=timezone.now() - timezone.timedelta(minutes=1))
        self.reserver(9)    # les places ont été reprises entre-temps
        self.reserver(3)
        for autre in Reservation.objects.exclude(pk=tardive.pk):
            autre.confirmer()
        paiement = Paiement.objects.create(reservation=tardive, user=tardive.user, montant=tardive.montant_total,
                                           methode='wave', telephone='0707070707', reference='PAY-TARDIF')
        _confirmer_paiement(paiement)
        tardive.refresh_from_db()
        self.assertEqual(tardive.statut, Reservation.Statut.ANNULEE)
        self.assertEqual(tardive.montant_rembourse, tardive.montant_total)
        self.assertFalse(tardive.billets.exists())


class FraisServiceTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.client.force_authenticate(creer_user())
        self.trajet = creer_trajet(prix=3500)

    def test_frais_par_defaut_ajoutes_au_total(self):
        r = self.client.post('/api/v1/reservations/', {'trajet_id': str(self.trajet.id), 'passagers': passagers(2)},
                             format='json').json()['data']
        self.assertEqual((r['montant_billets'], r['frais_service'], r['montant_total']), (7000, 500, 7500))

    def test_devis_public(self):
        r = APIClient().get(f'/api/v1/reservations/devis/?trajet_id={self.trajet.id}&passagers=3')
        self.assertEqual(r.status_code, 200, r.content)
        d = r.json()['data']
        self.assertEqual((d['montant_billets'], d['frais_service'], d['montant_total']), (10500, 500, 11000))
        self.assertEqual(d['libelle_frais'], '500 FCFA par réservation')

    def test_modes_de_calcul(self):
        p = ParametresPlateforme.actuels()
        p.frais_service_mode, p.frais_service_valeur = 'par_passager', 200
        p.save()
        self.assertEqual(p.calculer_frais(7000, 2), 400)
        p.frais_service_mode, p.frais_service_valeur, p.frais_service_minimum = 'pourcentage', Decimal('3.5'), 250
        p.save()
        self.assertEqual(p.calculer_frais(7000, 2), 250)   # 3,5 % = 245 F, relevé au minimum de 250 F
        self.assertEqual(p.calculer_frais(20000, 4), 700)

    def test_admin_modifie_les_frais(self):
        admin = creer_user('admin@tambour.ci', role='admin', is_staff=True)
        c = APIClient(); c.force_authenticate(admin)
        r = c.patch('/api/v1/admin/parametres/', {'frais_service_mode': 'par_passager', 'frais_service_valeur': 150},
                    format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(APIClient().get('/api/v1/plateforme/tarifs/').json()['data']['libelle_frais'],
                         '150 FCFA par passager')
        self.assertEqual(self.client.patch('/api/v1/admin/parametres/', {'frais_service_valeur': 0},
                                           format='json').status_code, 403)

    def test_frais_non_remboursables_par_defaut(self):
        self.client.post('/api/v1/reservations/', {'trajet_id': str(self.trajet.id), 'passagers': passagers(1)},
                         format='json')
        res = Reservation.objects.get()
        res.confirmer()
        self.assertEqual(res.calculer_remboursement(), 3500)   # départ dans 2 jours : billets remboursés, frais conservés
        ParametresPlateforme.objects.filter(pk=1).update(frais_remboursables=True)
        self.assertEqual(res.calculer_remboursement(), 4000)


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
        self.assertEqual(Reservation.objects.get(pk=res_id).montant_total, 8500)   # 8 000 F de billets + 500 F de frais
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
