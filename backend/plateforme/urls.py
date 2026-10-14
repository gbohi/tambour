from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

routeur = DefaultRouter()
routeur.register('admin/bannieres', views.BanniereAdminViewSet, basename='admin-banniere')

urlpatterns = [
    path('plateforme/tarifs/', views.TarifsView.as_view(), name='plateforme-tarifs'),
    path('bannieres/', views.BannieresPubliquesView.as_view(), name='bannieres'),
    path('admin/parametres/', views.ParametresAdminView.as_view(), name='admin-parametres'),
    path('', include(routeur.urls)),
]
