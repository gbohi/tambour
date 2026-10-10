from django.urls import path
from . import views
urlpatterns = [path('rapports/export/', views.ExportCsvView.as_view(), name='rapports-export')]
