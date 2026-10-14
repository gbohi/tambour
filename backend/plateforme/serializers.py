from rest_framework import serializers
from .models import ParametresPlateforme, Banniere


class ParametresSerializer(serializers.ModelSerializer):
    libelle_frais = serializers.ReadOnlyField()

    class Meta:
        model = ParametresPlateforme
        fields = ['frais_service_mode', 'frais_service_valeur', 'frais_service_minimum',
                  'frais_remboursables', 'libelle_frais', 'updated_at']
        read_only_fields = ['updated_at']

    def validate(self, attrs):
        mode = attrs.get('frais_service_mode', getattr(self.instance, 'frais_service_mode', None))
        valeur = attrs.get('frais_service_valeur', getattr(self.instance, 'frais_service_valeur', 0))
        if mode == ParametresPlateforme.ModeFrais.POURCENTAGE and valeur > 50:
            raise serializers.ValidationError({'frais_service_valeur': 'Un pourcentage ne peut pas dépasser 50 %.'})
        return attrs


class BanniereSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    depart_nom = serializers.ReadOnlyField(source='depart.nom')
    arrivee_nom = serializers.ReadOnlyField(source='arrivee.nom')
    # En multipart, un booléen absent vaut « faux » : on garde « active » par défaut.
    est_active = serializers.BooleanField(default=True)

    class Meta:
        model = Banniere
        fields = ['id', 'titre', 'sous_titre', 'image', 'image_url', 'couleur_fond', 'texte_bouton',
                  'action', 'depart', 'depart_nom', 'arrivee', 'arrivee_nom', 'page', 'lien',
                  'ordre', 'est_active', 'debut', 'fin', 'created_at']
        read_only_fields = ['created_at']
        extra_kwargs = {'image': {'write_only': True, 'required': False}}

    def get_image_url(self, obj):
        if not obj.image:
            return None
        requete = self.context.get('request')
        return requete.build_absolute_uri(obj.image.url) if requete else obj.image.url

    def validate(self, attrs):
        action = attrs.get('action', getattr(self.instance, 'action', Banniere.Action.AUCUNE))
        valeur = lambda k: attrs.get(k, getattr(self.instance, k, None))   # noqa: E731
        if action == Banniere.Action.RECHERCHE and not (valeur('depart') and valeur('arrivee')):
            raise serializers.ValidationError({'depart': 'Choisissez les villes de départ et d\'arrivée.'})
        if action == Banniere.Action.PAGE and not valeur('page'):
            raise serializers.ValidationError({'page': 'Choisissez la page à ouvrir.'})
        if action == Banniere.Action.LIEN and not valeur('lien'):
            raise serializers.ValidationError({'lien': 'Indiquez le lien à ouvrir.'})
        couleur = valeur('couleur_fond') or ''
        if couleur and not (len(couleur) == 7 and couleur.startswith('#')):
            raise serializers.ValidationError({'couleur_fond': 'Couleur au format #RRGGBB.'})
        return attrs
