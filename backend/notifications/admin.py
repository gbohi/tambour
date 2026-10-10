from django.contrib import admin
from .models import Notification, TokenPush, LogSMS

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'type_notif', 'titre', 'lue', 'canal', 'created_at']
    list_filter = ['type_notif', 'lue', 'canal', 'created_at']
    search_fields = ['user__email', 'titre', 'message']
    readonly_fields = ['id', 'created_at', 'lue_le']
    ordering = ['-created_at']
    actions = ['marquer_toutes_lues']

    def marquer_toutes_lues(self, request, queryset):
        from django.utils import timezone
        queryset.update(lue=True, lue_le=timezone.now())
        self.message_user(request, 'Notifications marquees comme lues.')
    marquer_toutes_lues.short_description = 'Marquer comme lues'

@admin.register(TokenPush)
class TokenPushAdmin(admin.ModelAdmin):
    list_display = ['user', 'plateforme', 'est_actif', 'updated_at']
    list_filter = ['plateforme', 'est_actif']
    search_fields = ['user__email']

@admin.register(LogSMS)
class LogSMSAdmin(admin.ModelAdmin):
    list_display = ['telephone', 'statut', 'user', 'cout', 'created_at']
    list_filter = ['statut', 'created_at']
    search_fields = ['telephone', 'user__email']
    readonly_fields = ['id', 'reference_at', 'cout', 'created_at']
