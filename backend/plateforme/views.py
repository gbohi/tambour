"""
Paramètres de la plateforme et bannières d'accueil.
- GET  /api/v1/plateforme/tarifs/          (public) frais de service en vigueur
- GET  /api/v1/bannieres/                  (public) bannières visibles, dans l'ordre
- GET/PATCH /api/v1/admin/parametres/      (admin)
- CRUD /api/v1/admin/bannieres/            (admin, image en multipart)
"""
from rest_framework import viewsets, status
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView

from authentication.permissions import EstAdmin
from tambour_backend.utils import success_response, error_response, EnveloppeMixin
from .models import ParametresPlateforme, Banniere
from .serializers import ParametresSerializer, BanniereSerializer


class TarifsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        p = ParametresPlateforme.actuels()
        return success_response(data={
            'frais_service_mode': p.frais_service_mode,
            'frais_service_valeur': float(p.frais_service_valeur),
            'frais_service_minimum': p.frais_service_minimum,
            'frais_remboursables': p.frais_remboursables,
            'libelle_frais': p.libelle_frais,
        })


class BannieresPubliquesView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        data = BanniereSerializer(Banniere.visibles(), many=True, context={'request': request}).data
        return success_response(data={'results': data})


class ParametresAdminView(APIView):
    permission_classes = [EstAdmin]

    def get(self, request):
        return success_response(data=ParametresSerializer(ParametresPlateforme.actuels()).data)

    def patch(self, request):
        s = ParametresSerializer(ParametresPlateforme.actuels(), data=request.data, partial=True)
        if not s.is_valid():
            return error_response('Paramètres invalides.', s.errors, status.HTTP_400_BAD_REQUEST)
        s.save()
        return success_response(data=s.data, message='Paramètres enregistrés.')


class BanniereAdminViewSet(EnveloppeMixin, viewsets.ModelViewSet):
    permission_classes = [EstAdmin]
    serializer_class = BanniereSerializer
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    queryset = Banniere.objects.select_related('depart', 'arrivee').all()
