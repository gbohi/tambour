from django.contrib import admin
from .models import QuestionFAQ, MessageSupport, Reclamation, AvisApplication


@admin.register(QuestionFAQ)
class QuestionFAQAdmin(admin.ModelAdmin):
    list_display = ['question', 'categorie', 'ordre', 'est_active']
    list_filter = ['categorie', 'est_active']
    list_editable = ['ordre', 'est_active']
    search_fields = ['question', 'reponse']


@admin.register(MessageSupport)
class MessageSupportAdmin(admin.ModelAdmin):
    list_display = ['sujet', 'nom', 'email', 'telephone', 'statut', 'created_at']
    list_filter = ['statut']
    search_fields = ['sujet', 'nom', 'email', 'telephone', 'message']
    raw_id_fields = ['user']


@admin.register(Reclamation)
class ReclamationAdmin(admin.ModelAdmin):
    list_display = ['reference', 'user', 'categorie', 'sujet', 'statut', 'created_at']
    list_filter = ['statut', 'categorie']
    search_fields = ['reference', 'sujet', 'user__email', 'reference_reservation']
    readonly_fields = ['reference', 'traitee_le', 'created_at', 'updated_at']
    raw_id_fields = ['user', 'reservation']


@admin.register(AvisApplication)
class AvisApplicationAdmin(admin.ModelAdmin):
    list_display = ['user', 'note', 'plateforme', 'version_app', 'updated_at']
    list_filter = ['note', 'plateforme']
    search_fields = ['user__email', 'commentaire']
