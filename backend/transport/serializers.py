from rest_framework import serializers
from .models import Ville, Gare, Transporteur, Bus, Ligne, Trajet, Siege, Horaire


class VilleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ville
        fields = ['id', 'nom', 'region', 'code_iata', 'latitude', 'longitude', 'est_active', 'ordre_affichage']


class GareSerializer(serializers.ModelSerializer):
    ville_nom = serializers.ReadOnlyField(source='ville.nom')
    compagnies = serializers.SerializerMethodField()
    lignes = serializers.SerializerMethodField()

    class Meta:
        model = Gare
        fields = ['id', 'nom', 'ville', 'ville_nom', 'adresse', 'latitude', 'longitude', 'telephone', 'heures_ouverture', 'est_principale', 'est_active', 'compagnies', 'lignes']

    def get_compagnies(self, obj):
        return list(Transporteur.objects.filter(trajets__ligne__gare_depart=obj, est_actif=True).distinct().values_list('nom', flat=True))

    def get_lignes(self, obj):
        return [str(l) for l in Ligne.objects.filter(gare_depart=obj, est_active=True).select_related('depart', 'arrivee')]


class SiegeSerializer(serializers.ModelSerializer):
    est_disponible = serializers.ReadOnlyField()

    class Meta:
        model = Siege
        fields = ['id', 'numero', 'rangee', 'colonne', 'statut', 'est_handicap', 'est_disponible']


class TrajetListSerializer(serializers.ModelSerializer):
    depart_nom = serializers.ReadOnlyField(source='ligne.depart.nom')
    arrivee_nom = serializers.ReadOnlyField(source='ligne.arrivee.nom')
    depart_region = serializers.ReadOnlyField(source='ligne.depart.region')
    arrivee_region = serializers.ReadOnlyField(source='ligne.arrivee.region')
    compagnie = serializers.ReadOnlyField(source='transporteur.nom')
    bus_immatriculation = serializers.ReadOnlyField(source='bus.immatriculation')
    bus_classe = serializers.ReadOnlyField(source='bus.classe')
    amenities = serializers.ReadOnlyField(source='bus.amenities')
    prix_actuel = serializers.ReadOnlyField()
    est_en_promo = serializers.ReadOnlyField()
    duree_label = serializers.ReadOnlyField()
    places_disponibles = serializers.SerializerMethodField()
    places_total = serializers.SerializerMethodField()
    depart = serializers.SerializerMethodField()
    arrivee = serializers.SerializerMethodField()
    gare_depart = serializers.SerializerMethodField()

    class Meta:
        model = Trajet
        fields = ['id', 'depart', 'arrivee', 'gare_depart', 'depart_nom', 'arrivee_nom', 'depart_region', 'arrivee_region', 'heure_depart', 'heure_arrivee_estimee', 'prix_fcfa', 'prix_promo_fcfa', 'prix_actuel', 'est_en_promo', 'duree_label', 'compagnie', 'bus_immatriculation', 'bus_classe', 'amenities', 'statut', 'retard_minutes', 'note_moyenne', 'nombre_avis', 'places_disponibles', 'places_total']

    @staticmethod
    def _ville(v):
        return {'id': str(v.id), 'nom': v.nom, 'region': v.region, 'code_iata': v.code_iata}

    def get_depart(self, obj):
        return self._ville(obj.ligne.depart)

    def get_arrivee(self, obj):
        return self._ville(obj.ligne.arrivee)

    def get_gare_depart(self, obj):
        g = obj.ligne.gare_depart
        return {'id': str(g.id), 'nom': g.nom} if g else None

    def get_places_disponibles(self, obj):
        return obj.sieges.filter(statut=Siege.Statut.LIBRE).count()

    def get_places_total(self, obj):
        return obj.sieges.count() or (obj.bus.capacite if obj.bus else 0)


class RechercheTrajetSerializer(serializers.Serializer):
    depart = serializers.UUIDField()
    arrivee = serializers.UUIDField()
    date = serializers.DateField()
    passagers = serializers.IntegerField(min_value=1, max_value=9, default=1)
    classe = serializers.ChoiceField(choices=['', 'standard', 'confort', 'vip'], required=False, allow_blank=True, default='')
    prix_max = serializers.IntegerField(required=False, min_value=0)
    tri = serializers.ChoiceField(choices=['horaire', 'prix', 'duree', 'note'], default='horaire')

    def validate(self, attrs):
        if str(attrs['depart']) == str(attrs['arrivee']):
            raise serializers.ValidationError('Les villes de depart et arrivee doivent etre differentes.')
        from django.utils import timezone
        if attrs['date'] < timezone.now().date():
            raise serializers.ValidationError({'date': 'La date ne peut pas etre dans le passe.'})
        return attrs
