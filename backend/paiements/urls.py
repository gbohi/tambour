from django.urls import path
from . import views

urlpatterns = [
    # Voyageur
    path('paiements/initier/',                views.InitierPaiementView.as_view(),  name='paiement-initier'),
    path('paiements/<str:reference>/statut/', views.VerifierPaiementView.as_view(), name='paiement-statut'),
    path('paiements/mes-paiements/',          views.MesPaiementsView.as_view(),     name='mes-paiements'),
    path('paiements/rembourser/',             views.RemboursementView.as_view(),    name='paiement-rembourser'),
    path('paiements/webhook/',                views.WebhookCinetPayView.as_view(),  name='paiement-webhook'),
    # Admin
    path('paiements/',            views.AdminPaiementsView.as_view(), name='admin-paiements'),
    path('paiements/versements/', views.VersementsView.as_view(),     name='versements'),
]
