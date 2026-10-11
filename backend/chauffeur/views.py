"""
Espace chauffeur : ses trajets (à venir / historique), liste des passagers,
validation des billets par scan du QR code, démarrage et fin du trajet.
"""
from datetime import timedelta
from django.db import transaction
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView

from reservations.models import Billet, Passager, Reservation
from tambour_backend.utils import success_response, error_response
from transport.models import Trajet
from .permissions import EstChauffeur

STATUTS_ACTIFS = [Trajet.Statut.PLANIFIE, Trajet.Statut.RETARDE, Trajet.Statut.EN_COURS]


def _trajets_du_chauffeur(user):
    confirmees = Q(reservations__statut=Reservation.Statut.CONFIRMEE)
    return (Trajet.objects.filter(chauffeur=user)
            .select_related('ligne__depart', 'ligne__arrivee', 'ligne__gare_depart', 'bus', 'transporteur')
            .annotate(
                nb_passagers=Count('reservations__passagers', filter=confirmees, distinct=True),
                nb_embarques=Count('reservations__billets', distinct=True,
                                   filter=confirmees & Q(reservations__billets__utilise_le__isnull=False))))


def _trajet_json(t):
    return {
        'id': str(t.id),
        'depart': t.ligne.depart.nom,
        'arrivee': t.ligne.arrivee.nom,
        'gare_depart': t.ligne.gare_depart.nom if t.ligne.gare_depart else None,
        'heure_depart': t.heure_depart.isoformat(),
        'heure_arrivee_estimee': t.heure_arrivee_estimee.isoformat(),
        'heure_arrivee_reelle': t.heure_arrivee_reelle.isoformat() if t.heure_arrivee_reelle else None,
        'demarre_le': t.demarre_le.isoformat() if t.demarre_le else None,
        'statut': t.statut,
        'statut_label': t.get_statut_display(),
        'retard_minutes': t.retard_minutes,
        'compagnie': t.transporteur.nom,
        'bus_immatriculation': t.bus.immatriculation if t.bus else '',
        'bus_modele': t.bus.modele if t.bus else '',
        'places_total': t.bus.capacite if t.bus else 0,
        'nb_passagers': getattr(t, 'nb_passagers', 0),
        'nb_embarques': getattr(t, 'nb_embarques', 0),
    }


def _passager_json(p):
    billet = getattr(p, 'billet', None)
    return {
        'id': str(p.id),
        'nom_complet': f'{p.prenom} {p.nom}',
        'telephone': p.telephone,
        'siege': p.siege.numero,
        'reservation': p.reservation.reference,
        'reference_billet': billet.reference_billet if billet else '',
        'embarque': bool(billet and billet.utilise_le),
        'embarque_le': billet.utilise_le.isoformat() if billet and billet.utilise_le else None,
    }


class MesTrajetsView(APIView):
    """GET /api/v1/chauffeur/trajets/?periode=a_venir|historique"""
    permission_classes = [EstChauffeur]

    def get(self, request):
        qs = _trajets_du_chauffeur(request.user)
        if request.query_params.get('periode') == 'historique':
            qs = qs.filter(Q(statut__in=[Trajet.Statut.TERMINE, Trajet.Statut.ANNULE])
                           | Q(heure_arrivee_estimee__lt=timezone.now() - timedelta(hours=12),
                               statut__in=STATUTS_ACTIFS)).order_by('-heure_depart')[:100]
        else:
            qs = qs.filter(statut__in=STATUTS_ACTIFS,
                           heure_arrivee_estimee__gte=timezone.now() - timedelta(hours=12)).order_by('heure_depart')
        trajets = list(qs)
        historique = request.query_params.get('periode') == 'historique'
        return success_response(data={
            'results': [_trajet_json(t) for t in trajets],
            'stats': {
                'nb_trajets': len(trajets),
                'nb_passagers': sum(t.nb_passagers for t in trajets),
            } if historique else None,
        })


class TrajetDetailView(APIView):
    """GET /api/v1/chauffeur/trajets/<id>/ — détail et liste des passagers."""
    permission_classes = [EstChauffeur]

    def get(self, request, pk):
        trajet = get_object_or_404(_trajets_du_chauffeur(request.user), pk=pk)
        passagers = (Passager.objects
                     .filter(reservation__trajet=trajet, reservation__statut=Reservation.Statut.CONFIRMEE)
                     .select_related('siege', 'reservation', 'billet')
                     .order_by('siege__rangee', 'siege__colonne'))
        return success_response(data={**_trajet_json(trajet),
                                      'passagers': [_passager_json(p) for p in passagers]})


class DemarrerTrajetView(APIView):
    """POST /api/v1/chauffeur/trajets/<id>/demarrer/"""
    permission_classes = [EstChauffeur]

    def post(self, request, pk):
        trajet = get_object_or_404(Trajet, pk=pk, chauffeur=request.user)
        if trajet.statut not in [Trajet.Statut.PLANIFIE, Trajet.Statut.RETARDE]:
            return error_response(f'Impossible de démarrer un trajet « {trajet.get_statut_display()} ».')
        trajet.statut = Trajet.Statut.EN_COURS
        trajet.demarre_le = timezone.now()
        trajet.save(update_fields=['statut', 'demarre_le', 'updated_at'])
        return success_response(data={'statut': trajet.statut}, message='Bon voyage ! Trajet démarré.')


class TerminerTrajetView(APIView):
    """POST /api/v1/chauffeur/trajets/<id>/terminer/"""
    permission_classes = [EstChauffeur]

    def post(self, request, pk):
        trajet = get_object_or_404(Trajet, pk=pk, chauffeur=request.user)
        if trajet.statut in [Trajet.Statut.TERMINE, Trajet.Statut.ANNULE]:
            return error_response(f'Ce trajet est déjà « {trajet.get_statut_display()} ».')
        maintenant = timezone.now()
        trajet.statut = Trajet.Statut.TERMINE
        trajet.heure_arrivee_reelle = maintenant
        trajet.demarre_le = trajet.demarre_le or trajet.heure_depart
        trajet.save(update_fields=['statut', 'heure_arrivee_reelle', 'demarre_le', 'updated_at'])
        return success_response(data={'statut': trajet.statut},
                                message='Trajet terminé. Les voyageurs peuvent maintenant le noter.')


class ScannerBilletView(APIView):
    """
    POST /api/v1/chauffeur/scanner/  { "trajet_id": "...", "qr_data": "TAMBOUR|REF|N|TRAJET|..." }
    ou { "trajet_id": "...", "reference_billet": "TB...-P2" } pour une saisie manuelle.
    """
    permission_classes = [EstChauffeur]

    def post(self, request):
        trajet = get_object_or_404(Trajet, pk=request.data.get('trajet_id'), chauffeur=request.user)
        reference, numero = self._lire(request.data)
        if not reference:
            return error_response('QR code non reconnu : ce n\'est pas un billet TamBour.')

        with transaction.atomic():
            billet = (Billet.objects.select_for_update()
                      .select_related('reservation__trajet__ligne__depart', 'reservation__trajet__ligne__arrivee',
                                      'passager__siege')
                      .filter(reservation__reference=reference, numero=numero).first())
            if not billet:
                return error_response('Billet introuvable.', {'code': ['introuvable']},
                                      status.HTTP_404_NOT_FOUND)
            res = billet.reservation
            if res.trajet_id != trajet.id:
                t = res.trajet
                return error_response(
                    f'Mauvais car : ce billet est pour {t.ligne.depart.nom} → {t.ligne.arrivee.nom} '
                    f'du {timezone.localtime(t.heure_depart):%d/%m à %H:%M}.', {'code': ['autre_trajet']})
            if res.statut != Reservation.Statut.CONFIRMEE:
                return error_response(f'Billet non valable (réservation {res.get_statut_display().lower()}).',
                                      {'code': ['non_paye']})
            if billet.utilise_le:
                return error_response(
                    f'Billet déjà scanné à {timezone.localtime(billet.utilise_le):%H:%M}.',
                    {'code': ['deja_utilise']}, status.HTTP_409_CONFLICT)
            billet.valider()

        return success_response(data=_passager_json(billet.passager),
                                message=f'{billet.passager.prenom} {billet.passager.nom} — siège {billet.passager.siege.numero}')

    @staticmethod
    def _lire(data):
        qr = (data.get('qr_data') or '').strip()
        if qr:
            parts = qr.split('|')
            if len(parts) >= 3 and parts[0] in ('TAMBOUR', 'YOBUS') and parts[2].isdigit():
                return parts[1].upper(), int(parts[2])
            return None, None
        ref = (data.get('reference_billet') or '').strip().upper()
        if '-P' in ref:
            reference, _, numero = ref.rpartition('-P')
            if numero.isdigit():
                return reference, int(numero)
        return None, None
