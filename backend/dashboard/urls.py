from django.urls import path
from . import views
urlpatterns = [path('dashboard/stats/', views.DashboardStatsView.as_view(), name='dashboard-stats')]
