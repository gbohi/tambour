from rest_framework import serializers
from .models import QuestionFAQ, MessageSupport, Reclamation, AvisApplication


class QuestionFAQSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuestionFAQ
        fields = ['id', 'categorie', 'question', 'reponse']


class MessageSupportSerializer(serializers.ModelSerializer):
    statut_label = serializers.CharField(source='get_statut_display', read_only=True)

    class Meta:
        model = MessageSupport
        fields = ['id', 'nom', 'email', 'telephone', 'sujet', 'message',
                  'statut', 'statut_label', 'reponse', 'created_at', 'updated_at']
        read_only_fields = ['id', 'statut', 'reponse', 'created_at', 'updated_at']

    def validate(self, attrs):
        if not attrs.get('email') and not attrs.get('telephone'):
            raise serializers.ValidationError('Indiquez un email ou un numéro de téléphone pour vous répondre.')
        return attrs


class MessageSupportAdminSerializer(MessageSupportSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True, default=None)

    class Meta(MessageSupportSerializer.Meta):
        fields = MessageSupportSerializer.Meta.fields + ['user_email']
        read_only_fields = ['id', 'nom', 'email', 'telephone', 'sujet', 'message', 'created_at', 'updated_at']

    def validate(self, attrs):
        return attrs


class ReclamationSerializer(serializers.ModelSerializer):
    categorie_label = serializers.CharField(source='get_categorie_display', read_only=True)
    statut_label = serializers.CharField(source='get_statut_display', read_only=True)

    class Meta:
        model = Reclamation
        fields = ['id', 'reference', 'categorie', 'categorie_label', 'sujet', 'description',
                  'reference_reservation', 'statut', 'statut_label', 'reponse',
                  'traitee_le', 'created_at', 'updated_at']
        read_only_fields = ['id', 'reference', 'statut', 'reponse', 'traitee_le', 'created_at', 'updated_at']


class ReclamationAdminSerializer(ReclamationSerializer):
    user_nom = serializers.CharField(source='user.nom_complet', read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_telephone = serializers.CharField(source='user.telephone', read_only=True)

    class Meta(ReclamationSerializer.Meta):
        fields = ReclamationSerializer.Meta.fields + ['user_nom', 'user_email', 'user_telephone']
        read_only_fields = ['id', 'reference', 'categorie', 'sujet', 'description',
                            'reference_reservation', 'traitee_le', 'created_at', 'updated_at']


class AvisApplicationSerializer(serializers.ModelSerializer):
    user_nom = serializers.CharField(source='user.nom_complet', read_only=True)

    class Meta:
        model = AvisApplication
        fields = ['id', 'note', 'commentaire', 'plateforme', 'version_app', 'user_nom', 'created_at', 'updated_at']
        read_only_fields = ['id', 'user_nom', 'created_at', 'updated_at']
