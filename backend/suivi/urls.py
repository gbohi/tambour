from django.urls import path
from . import views

urlpatterns = [
    path('chauffeur/trajets/<uuid:pk>/position/', views.PositionChauffeurView.as_view(), name='chauffeur-position'),
    path('trajets/<uuid:pk>/suivi/',              views.SuiviTrajetView.as_view(),       name='trajet-suivi'),
]
