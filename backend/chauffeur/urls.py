from django.urls import path
from . import views

urlpatterns = [
    path('chauffeur/trajets/',                        views.MesTrajetsView.as_view(),     name='chauffeur-trajets'),
    path('chauffeur/trajets/<uuid:pk>/',              views.TrajetDetailView.as_view(),   name='chauffeur-trajet'),
    path('chauffeur/trajets/<uuid:pk>/demarrer/',     views.DemarrerTrajetView.as_view(), name='chauffeur-demarrer'),
    path('chauffeur/trajets/<uuid:pk>/terminer/',     views.TerminerTrajetView.as_view(), name='chauffeur-terminer'),
    path('chauffeur/scanner/',                        views.ScannerBilletView.as_view(),  name='chauffeur-scanner'),
]
