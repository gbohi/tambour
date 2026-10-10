from django.conf import settings
from django.contrib.auth import get_user_model
from django.db.models import Sum
from django.utils import timezone
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .models import CodeVerification, SessionAppareil, MouvementPoints
from .permissions import EstAdminOuSupport
from .serializers import (
    InscriptionSerializer, ConnexionSerializer, UserDetailSerializer,
    MiseAJourProfilSerializer, ChangementMotDePasseSerializer,
    VerificationCodeSerializer, ReinitialisationMotDePasseSerializer,
    NouveauMotDePasseSerializer, MouvementPointsSerializer,
)
from tambour_backend.utils import success_response, error_response

User = get_user_model()


class StandardPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


# ── Helpers ────────────────────────────────────────────────────────────────

def _generer_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {'refresh': str(refresh), 'access': str(refresh.access_token)}


def _enregistrer_session(user, request, refresh_token):
    try:
        token_obj = RefreshToken(refresh_token)
        jti = token_obj['jti']
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        ip = (request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0]
              or request.META.get('REMOTE_ADDR', ''))
        SessionAppareil.objects.update_or_create(
            token_jti=jti,
            defaults={
                'user': user, 'appareil': user_agent[:200],
                'adresse_ip': ip or None, 'est_actif': True,
            })
    except Exception:
        pass


# ── Auth publique ──────────────────────────────────────────────────────────

class InscriptionView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = InscriptionSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Donnees invalides.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        tokens = _generer_tokens(user)
        _enregistrer_session(user, request, tokens['refresh'])
        CodeVerification.generer(user=user, type_code=CodeVerification.TypeCode.EMAIL)
        return success_response(
            data={**tokens, 'user': UserDetailSerializer(user, context={'request': request}).data},
            message='Compte cree avec succes. Verifiez votre email.',
            status_code=status.HTTP_201_CREATED)


class ConnexionView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ConnexionSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return error_response(
                serializer.errors.get('non_field_errors', ['Identifiants incorrects.'])[0],
                status_code=status.HTTP_401_UNAUTHORIZED)
        user = serializer.validated_data['user']
        tokens = _generer_tokens(user)
        _enregistrer_session(user, request, tokens['refresh'])
        return success_response(
            data={**tokens, 'user': UserDetailSerializer(user, context={'request': request}).data},
            message='Connexion reussie.')


class DeconnexionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return error_response('Token de rafraichissement requis.', status_code=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(refresh_token)
            SessionAppareil.objects.filter(token_jti=token['jti']).update(est_actif=False)
            token.blacklist()
        except TokenError:
            pass
        return success_response(message='Deconnexion reussie.')


class ReinitialisationMotDePasseView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ReinitialisationMotDePasseSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Email invalide.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        email = serializer.validated_data['email']
        try:
            user = User.objects.get(email=email)
            CodeVerification.generer(user=user, type_code=CodeVerification.TypeCode.MOT_DE_PASSE)
        except User.DoesNotExist:
            pass
        return success_response(message='Si un compte existe avec cet email, un code a ete envoye.')


class NouveauMotDePasseView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = NouveauMotDePasseSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Donnees invalides.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        user = serializer.validated_data['user']
        code_obj = serializer.validated_data['code_obj']
        user.set_password(serializer.validated_data['nouveau_mot_de_passe'])
        user.save(update_fields=['password'])
        code_obj.est_utilise = True
        code_obj.save(update_fields=['est_utilise'])
        return success_response(message='Mot de passe reinitialise avec succes.')


# ── Utilisateur connecté ───────────────────────────────────────────────────

class ProfilView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return success_response(
            data=UserDetailSerializer(request.user, context={'request': request}).data)

    def patch(self, request):
        serializer = MiseAJourProfilSerializer(
            request.user, data=request.data, partial=True, context={'request': request})
        if not serializer.is_valid():
            return error_response('Donnees invalides.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        return success_response(
            data=UserDetailSerializer(user, context={'request': request}).data,
            message='Profil mis a jour avec succes.')


class ChangementMotDePasseView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangementMotDePasseSerializer(
            data=request.data, context={'request': request})
        if not serializer.is_valid():
            return error_response('Donnees invalides.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return success_response(message='Mot de passe modifie avec succes.')


class VerificationEmailView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = VerificationCodeSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response('Code invalide.', serializer.errors, status.HTTP_400_BAD_REQUEST)
        code_obj = CodeVerification.objects.filter(
            user=request.user, code=serializer.validated_data['code'],
            type_code=CodeVerification.TypeCode.EMAIL, est_utilise=False).first()
        if not code_obj or not code_obj.est_valide:
            return error_response('Code invalide ou expire.', status_code=status.HTTP_400_BAD_REQUEST)
        code_obj.est_utilise = True
        code_obj.save(update_fields=['est_utilise'])
        request.user.is_verified = True
        request.user.save(update_fields=['is_verified'])
        return success_response(message='Email verifie avec succes.')


class RenvoyerCodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.is_verified:
            return error_response('Votre email est deja verifie.', status_code=status.HTTP_400_BAD_REQUEST)
        CodeVerification.generer(user=request.user, type_code=CodeVerification.TypeCode.EMAIL)
        return success_response(message='Un nouveau code a ete envoye a votre email.')


class SessionsAppareilView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sessions = SessionAppareil.objects.filter(
            user=request.user, est_actif=True).order_by('-last_active')
        data = [{
            'id': str(s.id),
            'appareil': s.appareil or 'Appareil inconnu',
            'adresse_ip': s.adresse_ip,
            'last_active': s.last_active.isoformat(),
            'created_at': s.created_at.isoformat(),
        } for s in sessions]
        return success_response(data=data)

    def delete(self, request):
        SessionAppareil.objects.filter(
            user=request.user, est_actif=True
        ).exclude(token_jti=request.auth.get('jti', '')).update(est_actif=False)
        return success_response(message='Tous les autres appareils ont ete deconnectes.')


# ── Admin — Gestion utilisateurs ───────────────────────────────────────────

class AdminUsersView(APIView):
    """
    Liste paginée des utilisateurs.
    GET /api/v1/auth/users/
    Filtres : role, search, is_verified, is_active
    Accès   : admin, support
    """
    permission_classes = [IsAuthenticated, EstAdminOuSupport]

    def get(self, request):
        qs = User.objects.all().order_by('-date_joined')

        role        = request.query_params.get('role')
        search      = request.query_params.get('search')
        is_verified = request.query_params.get('is_verified')
        is_active   = request.query_params.get('is_active')

        if role:
            qs = qs.filter(role=role)
        if search:
            from django.db.models import Q
            qs = qs.filter(
                Q(email__icontains=search) |
                Q(prenom__icontains=search) |
                Q(nom__icontains=search) |
                Q(telephone__icontains=search)
            )
        if is_verified is not None:
            qs = qs.filter(is_verified=(is_verified == 'true'))
        if is_active is not None:
            qs = qs.filter(is_active=(is_active == 'true'))

        paginator = StandardPagination()
        page = paginator.paginate_queryset(qs, request)
        data = UserDetailSerializer(page, many=True, context={'request': request}).data
        return success_response(data={
            'count':    paginator.page.paginator.count,
            'next':     paginator.get_next_link(),
            'previous': paginator.get_previous_link(),
            'results':  data,
        })


class AdminUserDetailView(APIView):
    """
    Détail et modification d'un utilisateur.
    GET   /api/v1/auth/users/<uuid>/
    PATCH /api/v1/auth/users/<uuid>/
    Accès : admin (tout), support (lecture + is_active)
    """
    permission_classes = [IsAuthenticated, EstAdminOuSupport]

    def _get_user(self, user_id):
        try:
            return User.objects.get(id=user_id), None
        except User.DoesNotExist:
            return None, error_response('Utilisateur introuvable.', status_code=status.HTTP_404_NOT_FOUND)

    def get(self, request, user_id):
        user, err = self._get_user(user_id)
        if err:
            return err
        return success_response(
            data=UserDetailSerializer(user, context={'request': request}).data)

    def patch(self, request, user_id):
        user, err = self._get_user(user_id)
        if err:
            return err

        # Admin peut tout modifier ; support ne peut que (dés)activer
        allowed = ['is_active']
        if request.user.role == 'admin':
            allowed += ['role', 'is_staff', 'is_verified']

        data = {k: v for k, v in request.data.items() if k in allowed}
        if not data:
            return error_response(
                'Aucun champ modifiable fourni.', status_code=status.HTTP_400_BAD_REQUEST)

        for field, value in data.items():
            setattr(user, field, value)
        user.save(update_fields=list(data.keys()) + ['updated_at'])

        return success_response(
            data=UserDetailSerializer(user, context={'request': request}).data,
            message='Utilisateur mis a jour.')


# ── Fidélité & parrainage ────────────────────────────────────────────────────

class FideliteView(APIView):
    """GET /api/v1/auth/fidelite/ — points, code de parrainage, filleuls et historique."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if not user.code_parrainage:
            user.save()
        mouvements = user.mouvements_points.all()
        points_parrainage = mouvements.filter(
            motif=MouvementPoints.Motif.PARRAINAGE).aggregate(t=Sum('points'))['t'] or 0
        message = (
            f"Rejoins-moi sur TamBour pour réserver tes billets de car en Côte d'Ivoire ! "
            f"Inscris-toi avec mon code {user.code_parrainage} et gagne {settings.POINTS_FILLEUL} points : "
            f"{settings.LIEN_TELECHARGEMENT_APP}")
        return success_response(data={
            'points': user.points_fidelite,
            'nb_voyages': user.nb_voyages,
            'code_parrainage': user.code_parrainage,
            'nb_filleuls': user.filleuls.count(),
            'points_parrainage': points_parrainage,
            'points_parrain': settings.POINTS_PARRAIN,
            'points_filleul': settings.POINTS_FILLEUL,
            'lien_telechargement': settings.LIEN_TELECHARGEMENT_APP,
            'message_partage': message,
            'historique': MouvementPointsSerializer(mouvements[:30], many=True).data,
        })


class VerifierCodeParrainageView(APIView):
    """GET /api/v1/auth/parrainage/verifier/?code=TBXXXXXX — utilisé à l'inscription."""
    permission_classes = [AllowAny]

    def get(self, request):
        code = (request.query_params.get('code') or '').strip().upper()
        parrain = User.objects.filter(code_parrainage=code, is_active=True).first() if code else None
        if not parrain:
            return error_response('Code de parrainage invalide.', status_code=status.HTTP_404_NOT_FOUND)
        return success_response(data={
            'valide': True, 'parrain_prenom': parrain.prenom, 'points_filleul': settings.POINTS_FILLEUL})
