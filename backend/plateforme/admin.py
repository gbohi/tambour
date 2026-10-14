from django.contrib import admin
from .models import ParametresPlateforme, Banniere


@admin.register(ParametresPlateforme)
class ParametresAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'frais_service_mode', 'frais_service_valeur', 'frais_remboursables', 'updated_at')


@admin.register(Banniere)
class BanniereAdmin(admin.ModelAdmin):
    list_display = ('titre', 'action', 'ordre', 'est_active', 'debut', 'fin')
    list_editable = ('ordre', 'est_active')
