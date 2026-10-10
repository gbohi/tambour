from django.urls import path
from . import views

urlpatterns = [
    path('notifications/',           views.NotificationsView.as_view(),   name='notifications'),
    path('notifications/lire/',      views.MarquerLueView.as_view(),      name='notifications-lire'),
    path('notifications/bulk/',      views.EnvoiNotifBulkView.as_view(),  name='notifications-bulk'),
    path('notifications/push-token/', views.TokenPushView.as_view(),      name='push-token'),
]
