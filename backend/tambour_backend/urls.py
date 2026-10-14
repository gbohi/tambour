from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/',       include('authentication.urls')),
    path('api/v1/',            include('transport.urls')),
    path('api/v1/',            include('reservations.urls')),
    path('api/v1/',            include('paiements.urls')),
    path('api/v1/',            include('notifications.urls')),
    path('api/v1/',            include('dashboard.urls')),
    path('api/v1/',            include('rapports.urls')),
    path('api/v1/',            include('support.urls')),
    path('api/v1/',            include('chauffeur.urls')),
    path('api/v1/',            include('suivi.urls')),
    path('api/v1/',            include('plateforme.urls')),
    path('api/schema/',        SpectacularAPIView.as_view(),                        name='schema'),
    path('api/docs/',          SpectacularSwaggerView.as_view(url_name='schema'),   name='swagger-ui'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL,  document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
