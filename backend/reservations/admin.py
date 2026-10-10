from django.contrib import admin
from .models import Reservation, Passager, Billet, Avis


class PassagerInline(admin.TabularInline):
    model  = Passager
    extra  = 0
    fields = ['ordre', 'prenom', 'nom', 'telephone', 'email', 'siege']
    readonly_fields = ['siege']
    ordering = ['ordre']


class BilletInline(admin.TabularInline):
    model  = Billet
    extra  = 0
    fields = ['passager', 'numero', 'est_valide', 'utilise_le']
    readonly_fields = ['passager', 'numero', 'qr_data', 'utilise_le']
    can_delete = False


@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
    list_display   = ['reference', 'user', 'trajet_info', 'statut',
                      'montant_total', 'nb_passagers', 'email_payeur', 'created_at']
    list_filter    = ['statut', 'created_at']
    search_fields  = ['reference', 'user__email', 'email_payeur']
    readonly_fields = ['id', 'reference', 'created_at', 'updated_at']
    inlines        = [PassagerInline, BilletInline]

    def trajet_info(self, obj):
        t = obj.trajet
        return f'{t.ligne.depart.nom} -> {t.ligne.arrivee.nom} ({t.heure_depart.strftime("%d/%m %H:%M")})'
    trajet_info.short_description = 'Trajet'


@admin.register(Passager)
class PassagerAdmin(admin.ModelAdmin):
    list_display  = ['nom_complet', 'reservation', 'telephone', 'email', 'siege']
    list_filter   = []
    search_fields = ['prenom', 'nom', 'telephone', 'email', 'reservation__reference']
    ordering      = ['reservation__reference', 'ordre']

    def nom_complet(self, obj):
        return obj.nom_complet
    nom_complet.short_description = 'Nom'


@admin.register(Billet)
class BilletAdmin(admin.ModelAdmin):
    list_display  = ['reference_billet', 'passager_nom', 'reservation', 'numero',
                     'est_valide', 'utilise_le', 'created_at']
    list_filter   = ['est_valide']
    search_fields = ['reservation__reference', 'passager__nom', 'passager__prenom']
    readonly_fields = ['id', 'qr_data', 'created_at']

    def reference_billet(self, obj):
        return obj.reference_billet
    reference_billet.short_description = 'Référence'

    def passager_nom(self, obj):
        return obj.passager.nom_complet
    passager_nom.short_description = 'Passager'


@admin.register(Avis)
class AvisAdmin(admin.ModelAdmin):
    list_display  = ['reservation', 'user', 'note', 'est_publie', 'created_at']
    list_filter   = ['note', 'est_publie']
    search_fields = ['user__email', 'reservation__reference', 'commentaire']
    readonly_fields = ['id', 'created_at']
    actions = ['publier', 'depublier']

    def publier(self, request, queryset):
        queryset.update(est_publie=True)
        self.message_user(request, f'{queryset.count()} avis publié(s).')
    publier.short_description = 'Publier les avis sélectionnés'

    def depublier(self, request, queryset):
        queryset.update(est_publie=False)
        self.message_user(request, f'{queryset.count()} avis dépublié(s).')
    depublier.short_description = 'Dépublier les avis sélectionnés'
