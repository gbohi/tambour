from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

app_name = 'authentication'

urlpatterns = [
    # Public
    path('register/',        views.InscriptionView.as_view(),               name='register'),
    path('token/',           views.ConnexionView.as_view(),                  name='token_obtain'),
    path('token/refresh/',   TokenRefreshView.as_view(),                     name='token_refresh'),
    path('forgot-password/', views.ReinitialisationMotDePasseView.as_view(), name='forgot_password'),
    path('reset-password/',  views.NouveauMotDePasseView.as_view(),          name='reset_password'),
    # Authentifié
    path('logout/',          views.DeconnexionView.as_view(),                name='logout'),
    path('me/',              views.ProfilView.as_view(),                     name='profil'),
    path('change-password/', views.ChangementMotDePasseView.as_view(),       name='change_password'),
    path('verify-email/',    views.VerificationEmailView.as_view(),          name='verify_email'),
    path('resend-code/',     views.RenvoyerCodeView.as_view(),               name='resend_code'),
    path('sessions/',        views.SessionsAppareilView.as_view(),           name='sessions'),
    # Admin — gestion utilisateurs
    path('users/',                views.AdminUsersView.as_view(),       name='admin-users'),
    path('users/<uuid:user_id>/', views.AdminUserDetailView.as_view(),  name='admin-user-detail'),
]
