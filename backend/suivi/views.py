"""
Suivi en temps réel.
- POST /api/v1/chauffeur/trajets/<id>/position/ : le chauffeur envoie la position du car.
- GET  /api/v1/trajets/<id>/suivi/              : voyageur (réservation confirmée), chauffeur,
                                                  compagnie ou admin consultent la position et l'arrivée estimée.
"""
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from chauffeur.permissions import EstChauffeur
from reservations.models import Reservation
from tambour_backend.utils import success_response, error_response
from transport.models import Trajet
from .models import PositionGPS
from .services import etat_suivi


class PositionSerializer(serializers.Serializer):
    latitude = serializers.FloatField(min_value=-90, max_value=90)
    longitude = serializers.FloatField(min_value=-180, max_value=180)
    vitesse_kmh = serializers.FloatField(min_value=0, max_value=200, required=False, allow_null=True)
    cap = serializers.FloatField(min_value=0, max_value=360, required=False, allow_null=True)
    precision_m = serializers.FloatField(min_value=0, required=False, allow_null=True)


def _trajet_qs():
    return Trajet.objects.select_related('ligne__depart', 'ligne__arrivee', 'ligne__gare_depart',
                                         'ligne__gare_arrivee', 'bus', 'transporteur')


def peut_suivre(user, trajet):
    if not user.is_authenticated:
        return False
    if user.is_staff or getattr(user, 'role', '') == 'admin' or trajet.chauffeur_id == user.id:
        return True
    if getattr(user, 'role', '') == 'transporteur' and trajet.transporteur.user_id == user.id:
        return True
    return Reservation.objects.filter(trajet=trajet, user=user, statut=Reservation.Statut.CONFIRMEE).exists()


class PositionChauffeurView(APIView):
    permission_classes = [EstChauffeur]

    def post(self, request, pk):
        trajet = get_object_or_404(_trajet_qs(), pk=pk, chauffeur=request.user)
        if trajet.statut != Trajet.Statut.EN_COURS:
            return error_response('Démarrez le trajet pour partager la position du car.', status_code=status.HTTP_409_CONFLICT)
        s = PositionSerializer(data=request.data)
        if not s.is_valid():
            return error_response('Position invalide.', s.errors, status.HTTP_400_BAD_REQUEST)
        PositionGPS.objects.create(trajet=trajet, enregistre_le=timezone.now(), **s.validated_data)
        etat = etat_suivi(trajet, avec_trace=False)
        return success_response(data={k: etat[k] for k in (
            'phase', 'minutes_restantes', 'arrivee_estimee', 'distance_restante_km', 'progression', 'source')},
            status_code=status.HTTP_201_CREATED)


class SuiviTrajetView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        trajet = get_object_or_404(_trajet_qs(), pk=pk)
        if not peut_suivre(request.user, trajet):
            return error_response("Vous n'avez pas de billet pour ce trajet.", status_code=status.HTTP_403_FORBIDDEN)
        return success_response(data=etat_suivi(trajet))
