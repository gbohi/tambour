from rest_framework.permissions import BasePermission, SAFE_METHODS


class EstVoyageur(BasePermission):
    """Autorise uniquement les voyageurs."""
    def has_permission(self, request, view):
        return (request.user and request.user.is_authenticated and request.user.role == 'voyageur')


class EstTransporteur(BasePermission):
    """Autorise uniquement les transporteurs partenaires."""
    def has_permission(self, request, view):
        return (request.user and request.user.is_authenticated and request.user.role == 'transporteur')


class EstAdmin(BasePermission):
    """Autorise uniquement les administrateurs."""
    def has_permission(self, request, view):
        return (request.user and request.user.is_authenticated
                and request.user.role in ['admin', 'support'] and request.user.is_staff)


class EstAdminOuSupport(BasePermission):
    """Autorise les admins et le support."""
    def has_permission(self, request, view):
        return (request.user and request.user.is_authenticated and request.user.role in ['admin', 'support'])


class EstProprietaireOuAdmin(BasePermission):
    """Autorise le proprietaire de la ressource ou un admin. Le modele doit avoir un champ user."""
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.role in ['admin', 'support']:
            return True
        return getattr(obj, 'user', None) == request.user


class EstTransporteurProprietaire(BasePermission):
    """Autorise le transporteur proprietaire de la ressource. Le modele doit avoir un champ transporteur."""
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.role == 'admin':
            return True
        transporteur = getattr(obj, 'transporteur', None)
        if transporteur is None:
            return False
        return hasattr(request.user, 'transporteur') and request.user.transporteur == transporteur


class LecturePubliqueEcritureAuthentifiee(BasePermission):
    """GET/HEAD/OPTIONS libre pour tous. Autres methodes necessitent une authentification."""
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return request.user and request.user.is_authenticated


class EstEmailVerifie(BasePermission):
    """Autorise uniquement les utilisateurs avec email verifie."""
    message = 'Veuillez verifier votre adresse email avant de continuer.'
    def has_permission(self, request, view):
        return (request.user and request.user.is_authenticated and request.user.is_verified)


class EstTransporteurVerifie(BasePermission):
    """Autorise uniquement les transporteurs verifies par YoBus."""
    message = 'Votre compte transporteur est en attente de verification.'
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.role != 'transporteur':
            return False
        try:
            return request.user.transporteur.est_verifie
        except Exception:
            return False
