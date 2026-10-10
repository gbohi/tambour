from django.conf import settings
from django.db.models import Avg, Count
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from authentication.permissions import EstAdminOuSupport
from reservations.models import Reservation
from tambour_backend.utils import success_response, error_response
from .models import QuestionFAQ, MessageSupport, Reclamation, AvisApplication
from .serializers import (
    QuestionFAQSerializer, MessageSupportSerializer, MessageSupportAdminSerializer,
    ReclamationSerializer, ReclamationAdminSerializer, AvisApplicationSerializer,
)


def _est_staff(user):
    return user.is_authenticated and user.role in ['admin', 'support']


# ── Centre d'aide ────────────────────────────────────────────────────────────

class FAQView(APIView):
    """GET /api/v1/support/faq/ — questions fréquentes regroupées par catégorie."""
    permission_classes = [AllowAny]

    def get(self, request):
        qs = QuestionFAQ.objects.filter(est_active=True)
        recherche = request.query_params.get('q')
        if recherche:
            qs = qs.filter(question__icontains=recherche) | qs.filter(reponse__icontains=recherche)
        categories = []
        for code, label in QuestionFAQ.Categorie.choices:
            questions = [q for q in qs if q.categorie == code]
            if questions:
                categories.append({'code': code, 'label': label,
                                   'questions': QuestionFAQSerializer(questions, many=True).data})
        return success_response(data={'categories': categories})


# ── Contacter le support ─────────────────────────────────────────────────────

class ContactView(APIView):
    """
    GET  /api/v1/support/contact/ — coordonnées du service client
    POST /api/v1/support/contact/ — envoyer un message
    """
    permission_classes = [AllowAny]

    def get(self, request):
        return success_response(data={
            'telephone': settings.SUPPORT_TELEPHONE,
            'whatsapp': settings.SUPPORT_WHATSAPP,
            'email': settings.SUPPORT_EMAIL,
            'horaires': settings.SUPPORT_HORAIRES,
        })

    def post(self, request):
        data = request.data.copy()
        user = request.user if request.user.is_authenticated else None
        if user:
            data.setdefault('nom', user.nom_complet)
            data.setdefault('email', user.email)
            data.setdefault('telephone', user.telephone)
        serializer = MessageSupportSerializer(data=data)
        if not serializer.is_valid():
            return error_response('Données invalides.', serializer.errors)
        message = serializer.save(user=user)
        return success_response(
            data=MessageSupportSerializer(message).data,
            message='Message envoyé. Notre équipe vous répond au plus vite.',
            status_code=status.HTTP_201_CREATED)


class MessagesSupportAdminView(APIView):
    """GET /api/v1/support/messages/ — liste (admin/support), filtre ?statut="""
    permission_classes = [EstAdminOuSupport]

    def get(self, request):
        qs = MessageSupport.objects.select_related('user')
        statut = request.query_params.get('statut')
        if statut:
            qs = qs.filter(statut=statut)
        return success_response(data={
            'results': MessageSupportAdminSerializer(qs[:200], many=True).data,
            'nb_nouveaux': MessageSupport.objects.filter(statut=MessageSupport.Statut.NOUVEAU).count(),
        })


class MessageSupportAdminDetailView(APIView):
    """PATCH /api/v1/support/messages/<id>/ — statut et réponse (admin/support)."""
    permission_classes = [EstAdminOuSupport]

    def patch(self, request, pk):
        message = MessageSupport.objects.filter(pk=pk).first()
        if not message:
            return error_response('Message introuvable.', status_code=status.HTTP_404_NOT_FOUND)
        serializer = MessageSupportAdminSerializer(message, data=request.data, partial=True)
        if not serializer.is_valid():
            return error_response('Données invalides.', serializer.errors)
        serializer.save()
        return success_response(data=serializer.data, message='Message mis à jour.')


# ── Réclamations ─────────────────────────────────────────────────────────────

class ReclamationsView(APIView):
    """
    GET  /api/v1/support/reclamations/ — mes réclamations (toutes pour admin/support, filtre ?statut=)
    POST /api/v1/support/reclamations/ — déposer une réclamation
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if _est_staff(request.user):
            qs = Reclamation.objects.select_related('user')
            statut = request.query_params.get('statut')
            if statut:
                qs = qs.filter(statut=statut)
            stats = dict(Reclamation.objects.values_list('statut').annotate(n=Count('id')))
            return success_response(data={
                'results': ReclamationAdminSerializer(qs[:300], many=True).data,
                'stats': {code: stats.get(code, 0) for code, _ in Reclamation.Statut.choices},
            })
        qs = Reclamation.objects.filter(user=request.user)
        return success_response(data={'results': ReclamationSerializer(qs, many=True).data})

    def post(self, request):
        serializer = ReclamationSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Données invalides.', serializer.errors)
        ref = serializer.validated_data.get('reference_reservation', '').strip().upper()
        reservation = None
        if ref:
            reservation = Reservation.objects.filter(reference=ref, user=request.user).first()
            if not reservation:
                return error_response(
                    'Aucune de vos réservations ne correspond à cette référence.',
                    {'reference_reservation': ['Référence introuvable.']})
        reclamation = serializer.save(user=request.user, reservation=reservation, reference_reservation=ref)
        return success_response(
            data=ReclamationSerializer(reclamation).data,
            message=f'Réclamation {reclamation.reference} enregistrée. Nous revenons vers vous sous 48 h.',
            status_code=status.HTTP_201_CREATED)


class ReclamationDetailView(APIView):
    """
    GET   /api/v1/support/reclamations/<id>/
    PATCH /api/v1/support/reclamations/<id>/ — statut et réponse (admin/support)
    """
    permission_classes = [IsAuthenticated]

    def _get(self, request, pk):
        qs = Reclamation.objects.select_related('user')
        if not _est_staff(request.user):
            qs = qs.filter(user=request.user)
        return qs.filter(pk=pk).first()

    def get(self, request, pk):
        reclamation = self._get(request, pk)
        if not reclamation:
            return error_response('Réclamation introuvable.', status_code=status.HTTP_404_NOT_FOUND)
        cls = ReclamationAdminSerializer if _est_staff(request.user) else ReclamationSerializer
        return success_response(data=cls(reclamation).data)

    def patch(self, request, pk):
        if not _est_staff(request.user):
            return error_response('Action réservée au support.', status_code=status.HTTP_403_FORBIDDEN)
        reclamation = self._get(request, pk)
        if not reclamation:
            return error_response('Réclamation introuvable.', status_code=status.HTTP_404_NOT_FOUND)
        serializer = ReclamationAdminSerializer(reclamation, data=request.data, partial=True)
        if not serializer.is_valid():
            return error_response('Données invalides.', serializer.errors)
        serializer.save()
        return success_response(data=serializer.data, message='Réclamation mise à jour.')


# ── Noter l'application ──────────────────────────────────────────────────────

class AvisApplicationView(APIView):
    """
    GET  /api/v1/support/avis-app/ — mon avis (admin/support : tous les avis + moyenne)
    POST /api/v1/support/avis-app/ — noter ou mettre à jour sa note
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if _est_staff(request.user):
            qs = AvisApplication.objects.select_related('user')
            agg = qs.aggregate(moyenne=Avg('note'), total=Count('id'))
            repartition = dict(qs.values_list('note').annotate(n=Count('id')))
            return success_response(data={
                'results': AvisApplicationSerializer(qs[:300], many=True).data,
                'moyenne': round(agg['moyenne'] or 0, 2),
                'total': agg['total'],
                'repartition': {n: repartition.get(n, 0) for n in range(1, 6)},
            })
        avis = AvisApplication.objects.filter(user=request.user).first()
        return success_response(data=AvisApplicationSerializer(avis).data if avis else None)

    def post(self, request):
        avis = AvisApplication.objects.filter(user=request.user).first()
        serializer = AvisApplicationSerializer(avis, data=request.data)
        if not serializer.is_valid():
            return error_response('Données invalides.', serializer.errors)
        serializer.save(user=request.user)
        return success_response(data=serializer.data, message='Merci pour votre avis !',
                                status_code=status.HTTP_200_OK if avis else status.HTTP_201_CREATED)
