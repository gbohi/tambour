from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register('villes',        views.VilleViewSet,        basename='ville')
router.register('gares',         views.GareViewSet,         basename='gare')
router.register('trajets',       views.TrajetViewSet,       basename='trajet')
router.register('transporteurs', views.TransporteurViewSet, basename='transporteur')

urlpatterns = [
    path('lignes/populaires/', views.LignesPopulairesView.as_view(), name='lignes-populaires'),
    path('', include(router.urls)),
    path('trajets/recherche/', views.RechercheTrajetView.as_view(), name='trajets-recherche'),
]
