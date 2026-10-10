from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from django.conf import settings
from django.db import transaction
from .models import CodeVerification, SessionAppareil, MouvementPoints

User = get_user_model()


class InscriptionSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password], style={'input_type': 'password'})
    password_confirm = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    code_parrainage = serializers.CharField(write_only=True, required=False, allow_blank=True, max_length=12)

    class Meta:
        model = User
        fields = ['prenom', 'nom', 'email', 'telephone', 'password', 'password_confirm', 'code_parrainage']

    def validate_code_parrainage(self, value):
        code = (value or '').strip().upper()
        if not code:
            return None
        parrain = User.objects.filter(code_parrainage=code, is_active=True).first()
        if not parrain:
            raise serializers.ValidationError('Code de parrainage invalide.')
        return parrain

    def validate_email(self, value):
        if User.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError('Un compte avec cet email existe deja.')
        return value.lower()

    def validate_telephone(self, value):
        tel = value.replace(' ', '').replace('-', '')
        if not tel.isdigit():
            raise serializers.ValidationError('Le numero ne doit contenir que des chiffres.')
        if len(tel) not in [10, 13]:
            raise serializers.ValidationError('Numero ivoirien invalide (10 ou 13 chiffres avec indicatif).')
        return tel

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Les mots de passe ne correspondent pas.'})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        parrain = validated_data.pop('code_parrainage', None)
        with transaction.atomic():
            user = User(**validated_data, parrain=parrain)
            user.set_password(password)
            user.save()
            if parrain:
                parrain.ajouter_points(settings.POINTS_PARRAIN, MouvementPoints.Motif.PARRAINAGE,
                                       f'{user.prenom} s\'est inscrit avec votre code')
                user.ajouter_points(settings.POINTS_FILLEUL, MouvementPoints.Motif.BIENVENUE,
                                    f'Inscription avec le code de {parrain.prenom}')
        return user


class ConnexionSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate(self, attrs):
        from django.contrib.auth import authenticate
        email = attrs.get('email', '').lower()
        password = attrs.get('password', '')
        user = authenticate(request=self.context.get('request'), username=email, password=password)
        if not user:
            raise serializers.ValidationError('Email ou mot de passe incorrect.')
        if not user.is_active:
            raise serializers.ValidationError('Ce compte a ete desactive.')
        attrs['user'] = user
        return attrs


class UserDetailSerializer(serializers.ModelSerializer):
    nom_complet = serializers.ReadOnlyField()
    initiales = serializers.ReadOnlyField()
    avatar_url = serializers.SerializerMethodField()
    date_inscription = serializers.DateTimeField(source='date_joined', read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'prenom', 'nom', 'nom_complet', 'initiales', 'email', 'telephone',
            'avatar_url', 'role', 'is_verified', 'points_fidelite', 'nb_voyages', 'code_parrainage',
            'notif_sms', 'notif_push', 'notif_email', 'notif_promotions',
            'date_inscription', 'updated_at',
        ]
        read_only_fields = ['id', 'role', 'is_verified', 'points_fidelite', 'nb_voyages', 'code_parrainage', 'date_inscription']

    def get_avatar_url(self, obj):
        request = self.context.get('request')
        if obj.avatar and request:
            return request.build_absolute_uri(obj.avatar.url)
        return None


class MiseAJourProfilSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['prenom', 'nom', 'telephone', 'avatar', 'notif_sms', 'notif_push', 'notif_email', 'notif_promotions']

    def validate_telephone(self, value):
        tel = value.replace(' ', '').replace('-', '')
        if not tel.isdigit():
            raise serializers.ValidationError('Le numero ne doit contenir que des chiffres.')
        return tel


class ChangementMotDePasseSerializer(serializers.Serializer):
    mot_de_passe_actuel = serializers.CharField(write_only=True, style={'input_type': 'password'})
    nouveau_mot_de_passe = serializers.CharField(write_only=True, validators=[validate_password], style={'input_type': 'password'})
    confirmation = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate_mot_de_passe_actuel(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Mot de passe actuel incorrect.')
        return value

    def validate(self, attrs):
        if attrs['nouveau_mot_de_passe'] != attrs['confirmation']:
            raise serializers.ValidationError({'confirmation': 'Les mots de passe ne correspondent pas.'})
        return attrs

    def save(self):
        user = self.context['request'].user
        user.set_password(self.validated_data['nouveau_mot_de_passe'])
        user.save(update_fields=['password'])
        return user


class VerificationCodeSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=6, min_length=6)

    def validate_code(self, value):
        if not value.isdigit():
            raise serializers.ValidationError('Le code doit contenir 6 chiffres.')
        return value


class ReinitialisationMotDePasseSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        return value.lower()


class NouveauMotDePasseSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=6)
    email = serializers.EmailField()
    nouveau_mot_de_passe = serializers.CharField(validators=[validate_password], style={'input_type': 'password'})
    confirmation = serializers.CharField(style={'input_type': 'password'})

    def validate(self, attrs):
        if attrs['nouveau_mot_de_passe'] != attrs['confirmation']:
            raise serializers.ValidationError({'confirmation': 'Les mots de passe ne correspondent pas.'})
        try:
            user = User.objects.get(email=attrs['email'].lower())
        except User.DoesNotExist:
            raise serializers.ValidationError({'email': 'Aucun compte trouve avec cet email.'})
        code_obj = CodeVerification.objects.filter(
            user=user, code=attrs['code'],
            type_code=CodeVerification.TypeCode.MOT_DE_PASSE,
            est_utilise=False).first()
        if not code_obj or not code_obj.est_valide:
            raise serializers.ValidationError({'code': 'Code invalide ou expire.'})
        attrs['user'] = user
        attrs['code_obj'] = code_obj
        return attrs


class MouvementPointsSerializer(serializers.ModelSerializer):
    motif_label = serializers.CharField(source='get_motif_display', read_only=True)

    class Meta:
        model = MouvementPoints
        fields = ['id', 'points', 'motif', 'motif_label', 'description', 'created_at']
