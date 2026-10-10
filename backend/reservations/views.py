from django.db import transaction
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated

from .models import Reservation, Passager, Billet, Avis
from .serializers import (
    CreerReservationSerializer, ReservationListSerializer,
    ReservationDetailSerializer, CreerAvisSerializer, AvisSerializer,
)
from transport.models import Siege
from authentication.views import StandardPagination
from yobus_backend.utils import success_response, error_response


class ReservationViewSet(viewsets.GenericViewSet):
    """
    Comportement selon le rôle :
    - admin/support  → toutes les réservations
    - transporteur   → réservations de ses trajets
    - voyageur       → ses propres réservations
    """
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        base = Reservation.objects.select_related(
            'trajet__ligne__depart', 'trajet__ligne__arrivee',
            'trajet__bus', 'trajet__transporteur', 'user'
        ).prefetch_related('passagers__siege', 'passagers__billet').order_by('-created_at')

        if user.role in ['admin', 'support']:
            return base
        if user.role == 'transporteur':
            try:
                return base.filter(trajet__transporteur=user.transporteur)
            except Exception:
                return base.none()
        return base.filter(user=user)

    # ── Créer réservation ─────────────────────────────────────────────────────
    def create(self, request):
        serializer = CreerReservationSerializer(
            data=request.data, context={'request': request})
        if not serializer.is_valid():
            return error_response('Données invalides.',
                                  serializer.errors, status.HTTP_400_BAD_REQUEST)

        trajet        = serializer.validated_data['trajet_id']
        passagers_data = serializer.validated_data['passagers']
        sieges_map    = serializer.validated_data['sieges_qs']
        email_payeur  = serializer.validated_data.get('email_payeur', '')

        # Si email_payeur non fourni, prendre l'email du 1er passager
        if not email_payeur and passagers_data:
            email_payeur = passagers_data[0].get('email', '')

        with transaction.atomic():
            montant = trajet.prix_actuel * len(passagers_data)
            reservation = Reservation.objects.create(
                user=request.user, trajet=trajet,
                montant_total=montant,
                nb_passagers=len(passagers_data),
                email_payeur=email_payeur)

            for ordre, p_data in enumerate(passagers_data, start=1):
                siege = sieges_map[p_data['siege_id']]
                # Bloquer le siège
                Siege.objects.filter(
                    id=siege.id,
                    statut__in=[Siege.Statut.LIBRE, Siege.Statut.RESERVE]
                ).update(statut=Siege.Statut.RESERVE, reserve_jusqu=reservation.expire_at)

                # Créer le passager (sans pièce d'identité)
                passager = Passager.objects.create(
                    reservation=reservation,
                    siege=siege,
                    prenom=p_data['prenom'],
                    nom=p_data['nom'],
                    telephone=p_data['telephone'],
                    email=p_data.get('email', ''),
                    ordre=ordre)

                # Créer immédiatement le billet individuel avec QR unique
                Billet.objects.create(
                    passager=passager,
                    reservation=reservation,
                    numero=ordre)

        return success_response(
            data=ReservationDetailSerializer(
                reservation, context={'request': request}).data,
            message='Réservation créée. Vous avez 15 minutes pour payer.',
            status_code=status.HTTP_201_CREATED)

    # ── Lister les réservations ───────────────────────────────────────────────
    def list(self, request):
        # Expirer les réservations en attente dépassées
        Reservation.objects.filter(
            statut=Reservation.Statut.EN_ATTENTE,
            expire_at__lt=timezone.now()
        ).update(statut=Reservation.Statut.EXPIREE)

        qs = self.get_queryset()

        # Filtres
        statut_f  = request.query_params.get('statut')
        section   = request.query_params.get('section')
        search_f  = request.query_params.get('search')
        date_f    = request.query_params.get('date')
        now       = timezone.now()

        if statut_f:
            qs = qs.filter(statut=statut_f)
        if date_f:
            qs = qs.filter(trajet__heure_depart__date=date_f)
        if search_f:
            from django.db.models import Q
            qs = qs.filter(
                Q(reference__icontains=search_f) |
                Q(user__email__icontains=search_f) |
                Q(user__nom__icontains=search_f) |
                Q(user__prenom__icontains=search_f))
        if section == 'a_venir':
            qs = qs.filter(statut=Reservation.Statut.CONFIRMEE,
                           trajet__heure_depart__gte=now)
        elif section == 'passees':
            qs = qs.filter(trajet__heure_depart__lt=now).exclude(
                statut=Reservation.Statut.EN_ATTENTE)

        # Pagination pour admin/support/transporteur
        user = request.user
        if user.role in ['admin', 'support', 'transporteur']:
            paginator = StandardPagination()
            page = paginator.paginate_queryset(qs, request)
            data = ReservationListSerializer(
                page, many=True, context={'request': request}).data
            return success_response(data={
                'count':    paginator.page.paginator.count,
                'next':     paginator.get_next_link(),
                'previous': paginator.get_previous_link(),
                'results':  data,
            })

        return success_response(
            data=ReservationListSerializer(
                qs, many=True, context={'request': request}).data)

    # ── Détail réservation ────────────────────────────────────────────────────
    def retrieve(self, request, pk=None):
        try:
            res = self.get_queryset().get(id=pk)
        except Reservation.DoesNotExist:
            return error_response('Réservation introuvable.',
                                  status_code=status.HTTP_404_NOT_FOUND)
        return success_response(
            data=ReservationDetailSerializer(res, context={'request': request}).data)

    # ── Annuler réservation ───────────────────────────────────────────────────
    @action(detail=True, methods=['post'])
    def annuler(self, request, pk=None):
        try:
            res = self.get_queryset().get(id=pk)
        except Reservation.DoesNotExist:
            return error_response('Réservation introuvable.',
                                  status_code=status.HTTP_404_NOT_FOUND)

        user = request.user
        if user.role == 'voyageur' and not res.peut_etre_annulee:
            return error_response(
                "Annulation impossible. Délai de 2h avant le départ dépassé.",
                status_code=status.HTTP_400_BAD_REQUEST)

        if res.statut not in [Reservation.Statut.CONFIRMEE, Reservation.Statut.EN_ATTENTE]:
            return error_response("Cette réservation ne peut pas être annulée.",
                                  status_code=status.HTTP_400_BAD_REQUEST)

        montant_rembourse = res.calculer_remboursement()
        with transaction.atomic():
            Siege.objects.filter(passager__reservation=res).update(
                statut=Siege.Statut.LIBRE, reserve_jusqu=None)
            Billet.objects.filter(reservation=res).update(est_valide=False)
            res.statut           = Reservation.Statut.ANNULEE
            res.montant_rembourse = montant_rembourse
            res.notes            = request.data.get('motif', '')
            res.save(update_fields=['statut', 'montant_rembourse', 'notes', 'updated_at'])

        return success_response(
            data={'reference': res.reference, 'statut': res.statut,
                  'montant_rembourse': montant_rembourse},
            message=f'Réservation annulée. {montant_rembourse:,} FCFA seront remboursés.')

    # ── Billets d'une réservation (tous les passagers) ────────────────────────
    @action(detail=True, methods=['get'])
    def billets(self, request, pk=None):
        """
        Retourne tous les billets individuels d'une réservation.
        GET /reservations/<id>/billets/
        """
        try:
            res = self.get_queryset().get(id=pk, statut=Reservation.Statut.CONFIRMEE)
        except Reservation.DoesNotExist:
            return error_response('Réservation introuvable ou non confirmée.',
                                  status_code=status.HTTP_404_NOT_FOUND)

        from .serializers import PassagerSerializer
        return success_response(data={
            'reference':   res.reference,
            'nb_billets':  res.nb_passagers,
            'email_payeur': res.email_payeur,
            'trajet': {
                'depart':       res.trajet.ligne.depart.nom,
                'arrivee':      res.trajet.ligne.arrivee.nom,
                'heure_depart': res.trajet.heure_depart.isoformat(),
                'compagnie':    res.trajet.transporteur.nom,
            },
            'passagers': PassagerSerializer(
                res.passagers.all(), many=True).data,
        })

    # ── Valider QR d'un billet individuel ─────────────────────────────────────
    @action(detail=True, methods=['post'], url_path='valider-qr')
    def valider_qr(self, request, pk=None):
        """
        Valide le billet d'UN passager spécifique.
        Body : { "passager_id": "<uuid>" }
        """
        user = request.user
        if user.role not in ['transporteur', 'admin', 'support']:
            return error_response('Permission refusée.',
                                  status_code=status.HTTP_403_FORBIDDEN)

        try:
            res = Reservation.objects.get(id=pk, statut=Reservation.Statut.CONFIRMEE)
        except Reservation.DoesNotExist:
            return error_response('Réservation introuvable ou non confirmée.',
                                  status_code=status.HTTP_404_NOT_FOUND)

        # Transporteur : vérifier que c'est son trajet
        if user.role == 'transporteur':
            try:
                if res.trajet.transporteur != user.transporteur:
                    return error_response('Ce trajet ne vous appartient pas.',
                                          status_code=status.HTTP_403_FORBIDDEN)
            except Exception:
                return error_response('Permission refusée.',
                                      status_code=status.HTTP_403_FORBIDDEN)

        passager_id = request.data.get('passager_id')
        if not passager_id:
            return error_response('passager_id requis.',
                                  status_code=status.HTTP_400_BAD_REQUEST)

        try:
            billet = Billet.objects.get(
                reservation=res, passager_id=passager_id, est_valide=True)
        except Billet.DoesNotExist:
            return error_response('Billet introuvable ou déjà utilisé.',
                                  status_code=status.HTTP_404_NOT_FOUND)

        billet.valider()

        return success_response(
            data={
                'reference_billet': billet.reference_billet,
                'passager': billet.passager.nom_complet,
                'siege':    billet.passager.siege.numero,
                'trajet':   str(res.trajet.ligne),
                'heure_depart': res.trajet.heure_depart.isoformat(),
            },
            message=f'Billet {billet.reference_billet} validé avec succès.')


# ── Avis ──────────────────────────────────────────────────────────────────────

class AvisViewSet(viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated]

    def create(self, request):
        serializer = CreerAvisSerializer(
            data=request.data, context={'request': request})
        if not serializer.is_valid():
            return error_response('Données invalides.',
                                  serializer.errors, status.HTTP_400_BAD_REQUEST)
        avis = serializer.save()
        self._mettre_a_jour_notes(avis.trajet)
        return success_response(
            data=AvisSerializer(avis).data,
            message='Avis publié avec succès.',
            status_code=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'],
            url_path='trajet/(?P<trajet_id>[^/.]+)', permission_classes=[])
    def par_trajet(self, request, trajet_id=None):
        avis = Avis.objects.filter(
            trajet_id=trajet_id, est_publie=True
        ).select_related('user').order_by('-created_at')
        if not avis.exists():
            return success_response(data={'count': 0, 'results': [], 'note_moyenne': 0})
        note_moyenne = sum(a.note for a in avis) / len(avis)
        return success_response(data={
            'count':        len(avis),
            'note_moyenne': round(note_moyenne, 2),
            'results':      AvisSerializer(avis, many=True).data,
        })

    def _mettre_a_jour_notes(self, trajet):
        from django.db.models import Avg, Count
        stats = Avis.objects.filter(
            trajet=trajet, est_publie=True
        ).aggregate(note_moy=Avg('note'), count=Count('id'))
        trajet.note_moyenne = stats['note_moy'] or 0
        trajet.nombre_avis  = stats['count']
        trajet.save(update_fields=['note_moyenne', 'nombre_avis'])
