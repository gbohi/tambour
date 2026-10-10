from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register('reservations', views.ReservationViewSet, basename='reservation')
router.register('avis',         views.AvisViewSet,        basename='avis')

urlpatterns = [path('', include(router.urls))]
