from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, CodeVerification, SessionAppareil


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'prenom', 'nom', 'role', 'is_verified', 'is_active', 'points_fidelite', 'nb_voyages', 'date_joined']
    list_filter = ['role', 'is_verified', 'is_active', 'is_staff']
    search_fields = ['email', 'prenom', 'nom', 'telephone']
    ordering = ['-date_joined']
    readonly_fields = ['id', 'date_joined', 'last_login', 'updated_at']
    fieldsets = (
        (None, {'fields': ('id', 'email', 'password')}),
        ('Informations personnelles', {'fields': ('prenom', 'nom', 'telephone', 'avatar')}),
        ('Role & statut', {'fields': ('role', 'is_active', 'is_verified', 'is_staff', 'is_superuser')}),
        ('Fidelite', {'fields': ('points_fidelite', 'nb_voyages')}),
        ('Notifications', {'fields': ('notif_sms', 'notif_push', 'notif_email', 'notif_promotions')}),
        ('Dates', {'fields': ('date_joined', 'last_login', 'updated_at')}),
    )
    add_fieldsets = ((None, {'classes': ('wide',), 'fields': ('email', 'prenom', 'nom', 'telephone', 'role', 'password1', 'password2')}),)


@admin.register(CodeVerification)
class CodeVerificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'type_code', 'code', 'est_utilise', 'created_at']
    list_filter = ['type_code', 'est_utilise']
    search_fields = ['user__email', 'code']


@admin.register(SessionAppareil)
class SessionAppareilAdmin(admin.ModelAdmin):
    list_display = ['user', 'appareil', 'adresse_ip', 'est_actif', 'last_active']
    list_filter = ['est_actif']
    search_fields = ['user__email', 'appareil']
