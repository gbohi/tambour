from django.contrib import admin
from .models import Ville, Gare, Transporteur, Bus, Ligne, Trajet, Siege, Horaire

@admin.register(Ville)
class VilleAdmin(admin.ModelAdmin):
    list_display = ['nom', 'region', 'est_active', 'ordre_affichage']
    list_filter = ['region', 'est_active']
    search_fields = ['nom', 'region']

@admin.register(Gare)
class GareAdmin(admin.ModelAdmin):
    list_display = ['nom', 'ville', 'est_principale', 'est_active']
    list_filter = ['ville', 'est_principale', 'est_active']
    search_fields = ['nom', 'ville__nom']

@admin.register(Transporteur)
class TransporteurAdmin(admin.ModelAdmin):
    list_display = ['nom', 'email', 'taux_commission', 'note_moyenne', 'est_actif', 'est_verifie']
    list_filter = ['est_actif', 'est_verifie']
    search_fields = ['nom', 'email']

@admin.register(Bus)
class BusAdmin(admin.ModelAdmin):
    list_display = ['immatriculation', 'modele', 'transporteur', 'capacite', 'classe', 'statut']
    list_filter = ['transporteur', 'classe', 'statut']
    search_fields = ['immatriculation', 'modele']

@admin.register(Ligne)
class LigneAdmin(admin.ModelAdmin):
    list_display = ['depart', 'arrivee', 'distance_km', 'duree_label', 'est_active', 'est_populaire']
    list_filter = ['est_active', 'est_populaire']
    search_fields = ['depart__nom', 'arrivee__nom']

@admin.register(Trajet)
class TrajetAdmin(admin.ModelAdmin):
    list_display = ['ligne', 'transporteur', 'heure_depart', 'prix_fcfa', 'statut', 'note_moyenne']
    list_filter = ['statut', 'transporteur', 'heure_depart']
    search_fields = ['ligne__depart__nom', 'ligne__arrivee__nom', 'bus__immatriculation']
