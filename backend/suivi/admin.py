from django.contrib import admin
from .models import PositionGPS


@admin.register(PositionGPS)
class PositionGPSAdmin(admin.ModelAdmin):
    list_display = ('trajet', 'latitude', 'longitude', 'vitesse_kmh', 'enregistre_le')
    list_filter = ('enregistre_le',)
    raw_id_fields = ('trajet',)
