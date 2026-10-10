from django.urls import path
from . import views

urlpatterns = [
    path('support/faq/',                       views.FAQView.as_view(),                       name='support-faq'),
    path('support/contact/',                   views.ContactView.as_view(),                   name='support-contact'),
    path('support/messages/',                  views.MessagesSupportAdminView.as_view(),      name='support-messages'),
    path('support/messages/<uuid:pk>/',        views.MessageSupportAdminDetailView.as_view(), name='support-message-detail'),
    path('support/reclamations/',              views.ReclamationsView.as_view(),              name='support-reclamations'),
    path('support/reclamations/<uuid:pk>/',    views.ReclamationDetailView.as_view(),         name='support-reclamation-detail'),
    path('support/avis-app/',                  views.AvisApplicationView.as_view(),           name='support-avis-app'),
]
