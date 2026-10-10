import logging
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Paiement, Versement
from .serializers import (
    InitierPaiementSerializer, PaiementSerializer,
    WebhookCinetPaySerializer, VersementSerializer,
)
from .services import CinetPayService, CinetPayException
from reservations.models import Reservation
from transport.models import Siege
from authentication.permissions import EstAdmin
from authentication.views import StandardPagination
from tambour_backend.utils import success_response, error_response

logger = logging.getLogger(__name__)


def _confirmer_paiement(paiement):
    with transaction.atomic():
        paiement.statut = Paiement.Statut.SUCCES
        paiement.confirme_le = timezone.now()
        paiement.save()
        reservation = paiement.reservation
        reservation.confirmer()
        Siege.objects.filter(passager__reservation=reservation).update(
            statut=Siege.Statut.OCCUPE, reserve_jusqu=None)
        points = reservation.montant_total // 1000
        paiement.user.ajouter_points(
            points, motif='voyage', description=f'Voyage {reservation.trajet.ligne} ({reservation.reference})')
        paiement.user.incrementer_voyages()
        logger.info(f'Paiement {paiement.reference} confirme - {reservation.reference}')


# ── Voyageur ──────────────────────────────────────────────────────────────

class InitierPaiementView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = InitierPaiementSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Donnees invalides.',
                                  serializer.errors, status.HTTP_400_BAD_REQUEST)
        data = serializer.validated_data
        try:
            reservation = Reservation.objects.get(
                id=data['reservation_id'], user=request.user,
                statut=Reservation.Statut.EN_ATTENTE)
        except Reservation.DoesNotExist:
            return error_response('Reservation introuvable ou deja payee.',
                                  status_code=status.HTTP_404_NOT_FOUND)
        if reservation.est_expiree:
            reservation.statut = Reservation.Statut.EXPIREE
            reservation.save(update_fields=['statut'])
            return error_response('La reservation a expire. Veuillez recommencer.',
                                  status_code=status.HTTP_410_GONE)

        paiement = Paiement.objects.create(
            reservation=reservation, user=request.user,
            methode=data['methode'], montant=reservation.montant_total,
            telephone=data['telephone'], statut=Paiement.Statut.INITIE)

        service = CinetPayService()
        try:
            result = service.initier_paiement(
                reference=paiement.reference, montant=paiement.montant,
                description=f'TamBour - {reservation.trajet.ligne} - {reservation.reference}',
                telephone=data['telephone'], methode=data['methode'],
                metadata={'reservation_id': str(reservation.id), 'user_id': str(request.user.id)})
            paiement.statut = Paiement.Statut.EN_ATTENTE
            paiement.transaction_id_operateur = result['transaction_id']
            paiement.url_paiement = result.get('url_paiement', '')
            paiement.reference_operateur = result.get('operateur_reference', '')
            paiement.donnees_operateur = result.get('raw', {})
            paiement.save()
        except CinetPayException as e:
            paiement.statut = Paiement.Statut.ECHEC
            paiement.message_erreur = str(e)
            paiement.save()
            logger.error(f'Erreur CinetPay {paiement.reference}: {e}')
            return error_response("Erreur lors de l'initiation du paiement.",
                                  status_code=status.HTTP_502_BAD_GATEWAY)

        return success_response(
            data={
                'paiement': PaiementSerializer(paiement).data,
                'url_paiement': paiement.url_paiement,
                'message': f'Confirmez le paiement sur votre telephone.',
            },
            status_code=status.HTTP_201_CREATED)


class VerifierPaiementView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, reference):
        try:
            paiement = Paiement.objects.get(reference=reference, user=request.user)
        except Paiement.DoesNotExist:
            return error_response('Paiement introuvable.',
                                  status_code=status.HTTP_404_NOT_FOUND)
        if paiement.statut == Paiement.Statut.SUCCES:
            return success_response(data=PaiementSerializer(paiement).data)
        service = CinetPayService()
        try:
            result = service.verifier_paiement(paiement.transaction_id_operateur)
            if result['statut'] == 'ACCEPTED':
                _confirmer_paiement(paiement)
            elif result['statut'] in ['REFUSED', 'CANCELLED']:
                paiement.statut = Paiement.Statut.ECHEC
                paiement.message_erreur = f'Statut : {result["statut"]}'
                paiement.save()
        except CinetPayException as e:
            logger.warning(f'Verification CinetPay echouee : {e}')
        return success_response(data=PaiementSerializer(paiement).data)


class MesPaiementsView(APIView):
    """Paiements du voyageur connecté."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        paiements = Paiement.objects.filter(
            user=request.user
        ).select_related('reservation').order_by('-created_at')
        return success_response(data=PaiementSerializer(paiements, many=True).data)


class RemboursementView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        reservation_id = request.data.get('reservation_id')
        try:
            reservation = Reservation.objects.get(
                id=reservation_id, user=request.user,
                statut=Reservation.Statut.ANNULEE, montant_rembourse__gt=0)
        except Reservation.DoesNotExist:
            return error_response('Reservation introuvable ou non eligible.',
                                  status_code=status.HTTP_404_NOT_FOUND)
        paiement = Paiement.objects.filter(
            reservation=reservation, statut=Paiement.Statut.SUCCES).first()
        if not paiement:
            return error_response('Aucun paiement confirme.',
                                  status_code=status.HTTP_404_NOT_FOUND)
        paiement.statut = Paiement.Statut.REMBOURSE
        paiement.montant_rembourse = reservation.montant_rembourse
        paiement.save()
        return success_response(
            data={
                'reference': reservation.reference,
                'montant_rembourse': reservation.montant_rembourse,
                'methode': paiement.get_methode_display(),
                'telephone': paiement.telephone,
            },
            message=f'Remboursement de {reservation.montant_rembourse:,} FCFA initie.')


# ── Webhook CinetPay ──────────────────────────────────────────────────────

class WebhookCinetPayView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = WebhookCinetPaySerializer(data=request.data)
        if not serializer.is_valid():
            logger.warning(f'Webhook invalide : {request.data}')
            return Response({'status': 'error'}, status=400)
        data = serializer.validated_data
        transaction_id = data['cpm_trans_id']
        try:
            paiement = Paiement.objects.get(reference=transaction_id)
        except Paiement.DoesNotExist:
            logger.error(f'Webhook : paiement {transaction_id} introuvable')
            return Response({'status': 'error'}, status=404)
        if paiement.statut == Paiement.Statut.SUCCES:
            return Response({'status': 'ok'})
        erreur = data.get('cpm_error_message', '')
        if not erreur or erreur.lower() == 'success':
            try:
                _confirmer_paiement(paiement)
            except Exception as e:
                logger.error(f'Erreur webhook {transaction_id}: {e}')
                return Response({'status': 'error'}, status=500)
        else:
            paiement.statut = Paiement.Statut.ECHEC
            paiement.message_erreur = erreur
            paiement.save()
        return Response({'status': 'ok'})


# ── Admin ──────────────────────────────────────────────────────────────────

class AdminPaiementsView(APIView):
    """
    Liste tous les paiements avec filtres.
    GET /api/v1/paiements/
    Accès : admin uniquement
    """
    permission_classes = [IsAuthenticated, EstAdmin]

    def get(self, request):
        qs = Paiement.objects.select_related(
            'user', 'reservation'
        ).order_by('-created_at')

        statut_f  = request.query_params.get('statut')
        methode_f = request.query_params.get('methode')
        search_f  = request.query_params.get('search')

        if statut_f:
            qs = qs.filter(statut=statut_f)
        if methode_f:
            qs = qs.filter(methode=methode_f)
        if search_f:
            from django.db.models import Q
            qs = qs.filter(
                Q(reference__icontains=search_f) |
                Q(telephone__icontains=search_f) |
                Q(user__email__icontains=search_f)
            )

        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        data = PaiementSerializer(page, many=True).data
        return success_response(data={
            'count':    paginator.page.paginator.count,
            'next':     paginator.get_next_link(),
            'previous': paginator.get_previous_link(),
            'results':  data,
        })


class VersementsView(APIView):
    """
    Versements aux transporteurs calculés dynamiquement depuis les paiements.
    GET /api/v1/paiements/versements/
    Accès : admin uniquement
    Filtres : statut, page, page_size
    """
    permission_classes = [IsAuthenticated, EstAdmin]

    def get(self, request):
        from django.db.models.functions import TruncMonth

        statut_f = request.query_params.get('statut')

        # Utiliser le modèle Versement réel s'il existe
        if Versement.objects.exists():
            qs = Versement.objects.select_related('transporteur').order_by('-periode_fin')
            if statut_f:
                qs = qs.filter(statut=statut_f)
            paginator = StandardPagination()
            page = paginator.paginate_queryset(qs, request)
            data = VersementSerializer(page, many=True).data
            return success_response(data={
                'count':    paginator.page.paginator.count,
                'next':     paginator.get_next_link(),
                'previous': paginator.get_previous_link(),
                'results':  data,
            })

        # Sinon calculer dynamiquement depuis les paiements
        from transport.models import Transporteur
        rows = (
            Paiement.objects
            .filter(statut='succes')
            .select_related('reservation__trajet__transporteur')
            .annotate(mois=TruncMonth('confirme_le'))
            .values(
                'reservation__trajet__transporteur__id',
                'reservation__trajet__transporteur__nom',
                'reservation__trajet__transporteur__taux_commission',
                'mois',
            )
            .annotate(montant_brut=Sum('montant'))
            .order_by('-mois')
        )

        versements = []
        for row in rows:
            t_id   = row['reservation__trajet__transporteur__id']
            t_nom  = row['reservation__trajet__transporteur__nom']
            taux   = float(row['reservation__trajet__transporteur__taux_commission'] or 10)
            brut   = row['montant_brut'] or 0
            comm   = round(brut * taux / 100)
            net    = brut - comm
            mois   = row['mois']
            if not t_id or not mois:
                continue
            import calendar
            dernier = mois.replace(
                day=calendar.monthrange(mois.year, mois.month)[1])
            versements.append({
                'id': f'{t_id}_{mois.strftime("%Y%m")}',
                'transporteur': str(t_id),
                'transporteur_nom': t_nom or 'Inconnu',
                'periode_debut': mois.replace(day=1).date().isoformat(),
                'periode_fin':   dernier.date().isoformat(),
                'montant_brut': int(brut),
                'montant_commission': int(comm),
                'montant_net': int(net),
                'statut': 'en_attente',
                'traite_le': None,
                'created_at': timezone.now().isoformat(),
            })

        if statut_f:
            versements = [v for v in versements if v['statut'] == statut_f]

        # Pagination manuelle
        page_size = int(request.query_params.get('page_size', 20))
        page_num  = int(request.query_params.get('page', 1))
        total     = len(versements)
        start     = (page_num - 1) * page_size
        return success_response(data={
            'count': total,
            'next':  None,
            'previous': None,
            'results': versements[start:start + page_size],
        })
