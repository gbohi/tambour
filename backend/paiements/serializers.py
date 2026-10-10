from rest_framework import serializers
from .models import Paiement, Versement


class InitierPaiementSerializer(serializers.Serializer):
    reservation_id = serializers.UUIDField()
    methode = serializers.ChoiceField(choices=Paiement.Methode.choices)
    telephone = serializers.CharField(max_length=20)

    def validate_telephone(self, value):
        tel = value.replace(' ', '').replace('-', '')
        if not tel.replace('+', '').isdigit():
            raise serializers.ValidationError('Numero de telephone invalide.')
        return tel


class PaiementSerializer(serializers.ModelSerializer):
    methode_label = serializers.ReadOnlyField(source='get_methode_display')
    statut_label = serializers.ReadOnlyField(source='get_statut_display')

    class Meta:
        model = Paiement
        fields = [
            'id', 'reference', 'methode', 'methode_label', 'montant',
            'montant_rembourse', 'telephone', 'statut', 'statut_label',
            'reference_operateur', 'url_paiement', 'message_erreur',
            'created_at', 'confirme_le',
        ]
        read_only_fields = fields


class WebhookCinetPaySerializer(serializers.Serializer):
    cpm_trans_id = serializers.CharField()
    cpm_site_id = serializers.CharField()
    cpm_amount = serializers.CharField()
    cpm_currency = serializers.CharField()
    payment_method = serializers.CharField()
    signature = serializers.CharField(required=False, default='')
    cel_phone_num = serializers.CharField(required=False, default='')
    cpm_error_message = serializers.CharField(required=False, default='')


class VersementSerializer(serializers.ModelSerializer):
    transporteur_nom = serializers.ReadOnlyField(source='transporteur.nom')
    statut_label = serializers.ReadOnlyField(source='get_statut_display')

    class Meta:
        model = Versement
        fields = [
            'id', 'transporteur', 'transporteur_nom', 'periode_debut', 'periode_fin',
            'montant_brut', 'commission_yobus', 'montant_net', 'statut', 'statut_label',
            'reference_virement', 'created_at', 'traite_le',
        ]
        read_only_fields = fields
