from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from .models import Notification, TokenPush
from .serializers import NotificationSerializer, MarquerLueSerializer, TokenPushSerializer
from authentication.permissions import EstAdminOuSupport
from tambour_backend.utils import success_response, error_response


class NotificationsView(APIView):
    """
    GET /api/v1/notifications/
    - admin/support : toutes les notifications du système
    - voyageur/transporteur : uniquement les siennes
    Filtres : type, non_lues, limit
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        if user.role in ['admin', 'support']:
            qs = Notification.objects.select_related('user').order_by('-created_at')
            nb_non_lues = Notification.objects.filter(lue=False).count()
        else:
            qs = Notification.objects.filter(user=user).order_by('-created_at')
            nb_non_lues = Notification.objects.filter(user=user, lue=False).count()

        type_filtre = request.query_params.get('type')
        non_lues    = request.query_params.get('non_lues')
        if type_filtre:
            qs = qs.filter(type_notif=type_filtre)
        if non_lues == '1':
            qs = qs.filter(lue=False)

        limit = min(int(request.query_params.get('limit', 50)), 200)
        qs = qs[:limit]

        return success_response(data={
            'nb_non_lues': nb_non_lues,
            'count': len(qs),
            'results': NotificationSerializer(qs, many=True).data,
        })

    def delete(self, request):
        user = request.user
        if user.role in ['admin', 'support']:
            Notification.objects.all().delete()
        else:
            Notification.objects.filter(user=user).delete()
        return success_response(message='Notifications supprimees.')


class MarquerLueView(APIView):
    """
    POST /api/v1/notifications/lire/
    Body : { notification_ids: [...] } ou vide pour toutes
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = MarquerLueSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Donnees invalides.',
                                  serializer.errors, status.HTTP_400_BAD_REQUEST)
        ids = serializer.validated_data.get('notification_ids', [])
        maintenant = timezone.now()
        user = request.user

        # Admin/support marquent les notifs du système
        if user.role in ['admin', 'support']:
            base_qs = Notification.objects.filter(lue=False)
        else:
            base_qs = Notification.objects.filter(user=user, lue=False)

        if ids:
            base_qs.filter(id__in=ids).update(lue=True, lue_le=maintenant)
        else:
            base_qs.update(lue=True, lue_le=maintenant)

        if user.role in ['admin', 'support']:
            nb_non_lues = Notification.objects.filter(lue=False).count()
        else:
            nb_non_lues = Notification.objects.filter(user=user, lue=False).count()

        return success_response(
            data={'nb_non_lues': nb_non_lues},
            message='Notifications marquees comme lues.')


class EnvoiNotifBulkView(APIView):
    """
    POST /api/v1/notifications/bulk/
    Envoi de notifications en masse — admin et support uniquement.
    Body : { titre, message, type_notif, cibles: ['all'|'active'|'inactive'] }
    """
    permission_classes = [IsAuthenticated, EstAdminOuSupport]

    def post(self, request):
        titre      = request.data.get('titre', '').strip()
        message    = request.data.get('message', '').strip()
        type_notif = request.data.get('type_notif', 'info')
        cibles     = request.data.get('cibles', ['all'])

        if not titre or not message:
            return error_response('titre et message sont requis.',
                                  status_code=status.HTTP_400_BAD_REQUEST)

        from authentication.models import User
        from datetime import timedelta

        qs = User.objects.filter(role='voyageur', is_active=True)
        cible = cibles[0] if isinstance(cibles, list) and cibles else 'all'

        if cible == 'active':
            depuis = timezone.now() - timedelta(days=30)
            qs = qs.filter(reservations__created_at__gte=depuis).distinct()
        elif cible == 'inactive':
            depuis = timezone.now() - timedelta(days=30)
            qs = qs.exclude(reservations__created_at__gte=depuis)

        notifs = [
            Notification(
                user=user,
                type_notif=type_notif,
                canal='push',
                titre=titre,
                message=message,
            )
            for user in qs
        ]
        Notification.objects.bulk_create(notifs, batch_size=500)

        return success_response(
            data={'nb_envoyes': len(notifs), 'cible': cible},
            message=f'{len(notifs)} notification(s) envoyee(s).',
            status_code=status.HTTP_201_CREATED)


class TokenPushView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = TokenPushSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return error_response('Token invalide.',
                                  serializer.errors, status.HTTP_400_BAD_REQUEST)
        token = serializer.save()
        return success_response(
            data=TokenPushSerializer(token).data,
            message='Token push enregistre.',
            status_code=status.HTTP_201_CREATED)

    def delete(self, request):
        token = request.data.get('token')
        if not token:
            return error_response('Token requis.', status_code=status.HTTP_400_BAD_REQUEST)
        TokenPush.objects.filter(user=request.user, token=token).update(est_actif=False)
        return success_response(message='Token push desactive.')
