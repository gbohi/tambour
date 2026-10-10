from rest_framework import serializers
from .models import Notification, TokenPush


class NotificationSerializer(serializers.ModelSerializer):
    type_label = serializers.ReadOnlyField(source='get_type_notif_display')

    class Meta:
        model = Notification
        fields = ['id', 'type_notif', 'type_label', 'canal', 'titre', 'message', 'lue', 'lue_le', 'reservation_id', 'trajet_id', 'metadata', 'created_at']
        read_only_fields = fields


class MarquerLueSerializer(serializers.Serializer):
    notification_ids = serializers.ListField(child=serializers.UUIDField(), required=False, help_text='IDs des notifications a marquer. Vide = toutes.')


class TokenPushSerializer(serializers.ModelSerializer):
    class Meta:
        model = TokenPush
        fields = ['id', 'token', 'plateforme', 'est_actif']
        read_only_fields = ['id', 'est_actif']

    def create(self, validated_data):
        user = self.context['request'].user
        token, _ = TokenPush.objects.update_or_create(
            token=validated_data['token'],
            defaults={'user': user, 'plateforme': validated_data['plateforme'], 'est_actif': True})
        return token
