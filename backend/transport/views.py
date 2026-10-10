from django.db.models import Q, Prefetch
from django.utils import timezone
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from .models import Ville, Gare, Transporteur, Bus, Ligne, Trajet, Siege, Horaire
from .serializers import (
    VilleSerializer, GareSerializer, TrajetListSerializer,
    RechercheTrajetSerializer, SiegeSerializer,
)
from .filters import TrajetFilter
from authentication.permissions import EstAdminOuSupport
from authentication.views import StandardPagination
from yobus_backend.utils import success_response, error_response


# ── Villes (public) ─────────────────────────────────────────────────────────

class VilleViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Ville.objects.filter(est_active=True)
    serializer_class = VilleSerializer
    permission_classes = [AllowAny]
    filterset_fields = ['region']
    search_fields = ['nom', 'region']
    ordering_fields = ['nom', 'ordre_affichage']

    @method_decorator(cache_page(60 * 30))
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)


# ── Gares (lecture publique, écriture admin) ──────────────────────────────

class GareViewSet(viewsets.ModelViewSet):
    serializer_class = GareSerializer
    filterset_fields = ['ville', 'est_principale', 'est_active']
    search_fields = ['nom', 'ville__nom', 'adresse']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated(), EstAdminOuSupport()]

    def get_queryset(self):
        return Gare.objects.select_related('ville').order_by('ville__nom', 'nom')

    @action(detail=False, methods=['get'], url_path='proches')
    def proches(self, request):
        lat = request.query_params.get('lat')
        lng = request.query_params.get('lng')
        if not lat or not lng:
            return error_response('Les parametres lat et lng sont requis.',
                                  status_code=status.HTTP_400_BAD_REQUEST)
        try:
            lat, lng = float(lat), float(lng)
        except ValueError:
            return error_response('Coordonnees GPS invalides.',
                                  status_code=status.HTTP_400_BAD_REQUEST)
        from django.db.models import FloatField
        from django.db.models.expressions import RawSQL
        distance_sql = RawSQL(
            '6371 * acos(cos(radians(%s)) * cos(radians(latitude)) * '
            'cos(radians(longitude) - radians(%s)) + sin(radians(%s)) * sin(radians(latitude)))',
            (lat, lng, lat), output_field=FloatField())
        rayon = float(request.query_params.get('rayon', 50))
        gares = self.get_queryset().annotate(
            distance_km=distance_sql).filter(distance_km__lte=rayon).order_by('distance_km')
        return success_response(
            data=self.get_serializer(gares, many=True, context={'request': request}).data)


# ── Transporteurs (admin/support lecture+écriture) ─────────────────────────

class TransporteurViewSet(viewsets.ModelViewSet):
    filterset_fields = ['est_verifie', 'est_actif']
    search_fields = ['nom', 'email', 'telephone']
    ordering_fields = ['nom', 'created_at', 'note_moyenne']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated(), EstAdminOuSupport()]
        return [IsAuthenticated(), EstAdminOuSupport()]

    def get_queryset(self):
        return Transporteur.objects.all().order_by('-created_at')

    def get_serializer_class(self):
        return TransporteurSerializer

    def partial_update(self, request, *args, **kwargs):
        # Seul admin peut modifier le rôle/taux commission
        if request.user.role != 'admin':
            allowed = ['est_actif']
            if 'est_verifie' not in request.data and not any(
                    k not in allowed for k in request.data):
                pass
            # Support ne peut que changer est_actif
            data = {k: v for k, v in request.data.items() if k in ['est_actif', 'est_verifie']}
            request._full_data = data
        return super().partial_update(request, *args, **kwargs)


class TransporteurSerializer:
    """Import local pour éviter la circularité — défini dans serializers.py."""
    pass

# Réimport correct
from .serializers import GareSerializer as _GS
from rest_framework import serializers as _s

class TransporteurSerializer(_s.ModelSerializer):
    class Meta:
        from transport.models import Transporteur as _T
        model = _T
        fields = [
            'id', 'nom', 'email', 'telephone', 'adresse', 'rccm',
            'taux_commission', 'note_moyenne', 'nombre_avis',
            'est_actif', 'est_verifie', 'created_at',
        ]
        read_only_fields = ['id', 'note_moyenne', 'nombre_avis', 'created_at']


# ── Trajets ────────────────────────────────────────────────────────────────

class RechercheTrajetView(APIView):
    """POST /api/v1/trajets/recherche/ — public."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RechercheTrajetSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Parametres invalides.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        params = serializer.validated_data
        trajets = self._rechercher(params)
        result_serializer = TrajetListSerializer(trajets, many=True, context={'request': request})
        return success_response(data={
            'count': len(trajets),
            'passagers': params['passagers'],
            'date': params['date'].isoformat(),
            'results': result_serializer.data,
        })

    def _rechercher(self, params):
        trajets = Trajet.objects.filter(
            ligne__depart_id=params['depart'],
            ligne__arrivee_id=params['arrivee'],
            heure_depart__date=params['date'],
            statut__in=[Trajet.Statut.PLANIFIE, Trajet.Statut.EN_COURS]
        ).select_related(
            'ligne__depart', 'ligne__arrivee', 'bus', 'transporteur'
        ).prefetch_related(
            Prefetch('sieges', queryset=Siege.objects.filter(statut=Siege.Statut.LIBRE),
                     to_attr='sieges_libres'))
        nb = params['passagers']
        trajets = [t for t in trajets if len(t.sieges_libres) >= nb]
        if params.get('classe'):
            trajets = [t for t in trajets if t.bus and t.bus.classe == params['classe']]
        if params.get('prix_max'):
            trajets = [t for t in trajets if t.prix_actuel <= params['prix_max']]
        tri = params.get('tri', 'horaire')
        if tri == 'prix':   trajets.sort(key=lambda t: t.prix_actuel)
        elif tri == 'duree': trajets.sort(key=lambda t: t.duree_minutes)
        elif tri == 'note':  trajets.sort(key=lambda t: t.note_moyenne, reverse=True)
        else:                trajets.sort(key=lambda t: t.heure_depart)
        return trajets


class TrajetViewSet(viewsets.ModelViewSet):
    """
    GET    : public pour lecture (app Flutter)
    PATCH  : admin/support (tous trajets) ou transporteur (ses trajets)
    Filtres: date, statut, classe, transporteur, search
    """
    filterset_class = TrajetFilter
    search_fields = ['ligne__depart__nom', 'ligne__arrivee__nom', 'transporteur__nom']
    ordering_fields = ['heure_depart', 'prix_fcfa', 'note_moyenne']

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'sieges']:
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user

        # Admin/support → tous les trajets (y compris passés et annulés)
        if user.is_authenticated and user.role in ['admin', 'support']:
            return Trajet.objects.select_related(
                'ligne__depart', 'ligne__arrivee', 'bus', 'transporteur'
            ).order_by('-heure_depart')

        # Transporteur → uniquement ses trajets
        if user.is_authenticated and user.role == 'transporteur':
            try:
                return Trajet.objects.filter(
                    transporteur=user.transporteur
                ).select_related(
                    'ligne__depart', 'ligne__arrivee', 'bus', 'transporteur'
                ).order_by('-heure_depart')
            except Exception:
                return Trajet.objects.none()

        # Public → uniquement futurs et actifs
        return Trajet.objects.filter(
            heure_depart__gte=timezone.now(),
            statut__in=[Trajet.Statut.PLANIFIE, Trajet.Statut.EN_COURS]
        ).select_related('ligne__depart', 'ligne__arrivee', 'bus', 'transporteur')

    def get_serializer_class(self):
        return TrajetListSerializer

    def partial_update(self, request, *args, **kwargs):
        trajet = self.get_object()
        user = request.user

        if not user.is_authenticated:
            return error_response('Authentification requise.',
                                  status_code=status.HTTP_401_UNAUTHORIZED)

        # Transporteur ne peut modifier que ses propres trajets
        if user.role == 'transporteur':
            try:
                if trajet.transporteur != user.transporteur:
                    return error_response('Permission refusee.',
                                          status_code=status.HTTP_403_FORBIDDEN)
            except Exception:
                return error_response('Permission refusee.',
                                      status_code=status.HTTP_403_FORBIDDEN)

        allowed = ['statut', 'motif_annulation', 'retard_minutes']
        data = {k: v for k, v in request.data.items() if k in allowed}

        for field, value in data.items():
            setattr(trajet, field, value)
        trajet.save(update_fields=list(data.keys()))

        # Notifier voyageurs si annulation ou retard
        if data.get('statut') == 'annule':
            _notifier_annulation(trajet)
        elif data.get('statut') == 'retarde':
            _notifier_retard(trajet, data.get('retard_minutes', 0))

        return success_response(
            data=TrajetListSerializer(trajet, context={'request': request}).data,
            message='Trajet mis a jour.')

    @action(detail=True, methods=['get'])
    def sieges(self, request, pk=None):
        trajet = self.get_object()
        Siege.objects.filter(
            trajet=trajet, statut=Siege.Statut.RESERVE,
            reserve_jusqu__lt=timezone.now()
        ).update(statut=Siege.Statut.LIBRE, reserve_jusqu=None)
        sieges = trajet.sieges.all().order_by('rangee', 'colonne')
        return success_response(data={
            'trajet_id': str(trajet.id),
            'capacite': trajet.bus.capacite if trajet.bus else 0,
            'places_disponibles': sieges.filter(statut=Siege.Statut.LIBRE).count(),
            'sieges': SiegeSerializer(sieges, many=True).data,
        })

    @action(detail=True, methods=['post'])
    def reserver_temporaire(self, request, pk=None):
        trajet = self.get_object()
        siege_ids = request.data.get('siege_ids', [])
        if not siege_ids:
            return error_response('Aucun siege selectionne.',
                                  status_code=status.HTTP_400_BAD_REQUEST)
        if len(siege_ids) > 9:
            return error_response('Maximum 9 sieges par reservation.',
                                  status_code=status.HTTP_400_BAD_REQUEST)
        sieges = Siege.objects.filter(
            trajet=trajet, numero__in=siege_ids, statut=Siege.Statut.LIBRE)
        if sieges.count() != len(siege_ids):
            return error_response('Certains sieges ne sont plus disponibles.',
                                  status_code=status.HTTP_409_CONFLICT)
        expire = timezone.now() + timezone.timedelta(minutes=10)
        sieges.update(statut=Siege.Statut.RESERVE, reserve_jusqu=expire)
        return success_response(
            data={'siege_ids': siege_ids, 'expire_at': expire.isoformat()},
            message='Sieges reserves temporairement pour 10 minutes.')


# ── Helpers notifications ──────────────────────────────────────────────────

def _notifier_annulation(trajet):
    """Notifie tous les voyageurs d'une annulation de trajet."""
    try:
        from notifications.models import Notification
        reservations = trajet.reservations.filter(
            statut='confirmee').select_related('user')
        Notification.objects.bulk_create([
            Notification(
                user=r.user, type_notif='annulation', canal='push',
                titre='Trajet annule',
                message=(f'Le trajet {trajet.ligne} du '
                         f'{trajet.heure_depart.strftime("%d/%m a %Hh%M")} '
                         f'a ete annule. Vous serez rembourse.'),
                trajet_id=trajet.id,
            )
            for r in reservations
        ])
    except Exception:
        pass


def _notifier_retard(trajet, minutes):
    """Notifie tous les voyageurs d'un retard."""
    try:
        from notifications.models import Notification
        reservations = trajet.reservations.filter(
            statut='confirmee').select_related('user')
        Notification.objects.bulk_create([
            Notification(
                user=r.user, type_notif='retard', canal='push',
                titre=f'Retard de {minutes} min',
                message=(f'Le trajet {trajet.ligne} accuse un retard de {minutes} minutes. '
                         f'Nouveau depart estime : '
                         f'{trajet.heure_depart.strftime("%Hh%M")}.'),
                trajet_id=trajet.id,
            )
            for r in reservations
        ])
    except Exception:
        pass
