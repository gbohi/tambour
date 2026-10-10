from django.contrib import admin
from django.utils.html import format_html
from .models import Paiement, Versement

@admin.register(Paiement)
class PaiementAdmin(admin.ModelAdmin):
    list_display = ['reference', 'user', 'methode', 'montant_fcfa', 'statut_badge', 'telephone', 'created_at', 'confirme_le']
    list_filter = ['statut', 'methode', 'created_at']
    search_fields = ['reference', 'user__email', 'telephone', 'reservation__reference']
    readonly_fields = ['id', 'reference', 'reference_operateur', 'transaction_id_operateur', 'donnees_operateur', 'created_at', 'updated_at', 'confirme_le']

    def montant_fcfa(self, obj):
        return f'{obj.montant:,} FCFA'
    montant_fcfa.short_description = 'Montant'

    def statut_badge(self, obj):
        colors = {'succes': 'green', 'en_attente': 'orange', 'initie': 'blue', 'echec': 'red', 'rembourse': 'purple', 'annule': 'gray'}
        color = colors.get(obj.statut, 'gray')
        return format_html('<span style="color:{}; font-weight:bold">{}</span>', color, obj.get_statut_display())
    statut_badge.short_description = 'Statut'

@admin.register(Versement)
class VersementAdmin(admin.ModelAdmin):
    list_display = ['transporteur', 'periode_debut', 'periode_fin', 'montant_net_fcfa', 'statut', 'traite_le']
    list_filter = ['statut', 'transporteur']

    def montant_net_fcfa(self, obj):
        return f'{obj.montant_net:,} FCFA'
    montant_net_fcfa.short_description = 'Net transporteur'
