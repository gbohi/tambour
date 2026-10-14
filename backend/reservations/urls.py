from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register('reservations', views.ReservationViewSet, basename='reservation')
router.register('avis',         views.AvisViewSet,        basename='avis')

urlpatterns = [
    # Avant le routeur : sinon « devis » serait pris pour un identifiant de réservation
    path('reservations/devis/', views.DevisView.as_view(), name='reservation-devis'),
    path('', include(router.urls)),
]
