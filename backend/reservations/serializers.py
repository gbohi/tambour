from django.utils import timezone
from rest_framework import serializers
from .models import Reservation, Passager, Billet, Avis
from transport.models import Trajet, Siege


# ── Input passager — sans pièce d'identité, email facultatif ─────────────────

class PassagerInputSerializer(serializers.Serializer):
    prenom    = serializers.CharField(max_length=100)
    nom       = serializers.CharField(max_length=100)
    telephone = serializers.CharField(max_length=20)
    email     = serializers.EmailField(required=False, allow_blank=True, default='')


class CreerReservationSerializer(serializers.Serializer):
    trajet_id    = serializers.UUIDField()
    passagers    = PassagerInputSerializer(many=True)
    email_payeur = serializers.EmailField(required=False, allow_blank=True, default='')

    def validate_trajet_id(self, value):
        try:
            return Trajet.objects.get(
                id=value,
                statut__in=[Trajet.Statut.PLANIFIE, Trajet.Statut.EN_COURS],
                heure_depart__gt=timezone.now())
        except Trajet.DoesNotExist:
            raise serializers.ValidationError('Trajet introuvable ou non disponible.')

    def validate_passagers(self, value):
        if not value:
            raise serializers.ValidationError('Au moins un passager est requis.')
        if len(value) > 9:
            raise serializers.ValidationError('Maximum 9 passagers par réservation.')
        return value

    def validate(self, attrs):
        # Les sièges sont attribués automatiquement : on vérifie seulement qu'il reste assez de places.
        trajet = attrs['trajet_id']
        nb_libres = Siege.disponibles(trajet).count()
        if nb_libres < len(attrs['passagers']):
            raise serializers.ValidationError(
                {'passagers': f'Plus assez de places sur ce trajet ({nb_libres} disponible(s)).'})
        return attrs


# ── Sérialiseurs de lecture ───────────────────────────────────────────────────

class BilletSerializer(serializers.ModelSerializer):
    reference_billet = serializers.ReadOnlyField()

    class Meta:
        model  = Billet
        fields = ['id', 'reference_billet', 'numero', 'qr_data',
                  'est_valide', 'utilise_le', 'created_at']


class PassagerSerializer(serializers.ModelSerializer):
    siege_numero     = serializers.ReadOnlyField(source='siege.numero')
    billet           = BilletSerializer(read_only=True)

    class Meta:
        model  = Passager
        fields = ['id', 'prenom', 'nom', 'telephone', 'email',
                  'siege_numero', 'ordre', 'billet']


class ReservationListSerializer(serializers.ModelSerializer):
    peut_etre_annulee   = serializers.ReadOnlyField()
    montant_remboursable = serializers.SerializerMethodField()
    trajet_info         = serializers.SerializerMethodField()
    user_info           = serializers.SerializerMethodField()
    peut_etre_notee     = serializers.SerializerMethodField()
    avis_note           = serializers.SerializerMethodField()

    class Meta:
        model  = Reservation
        fields = [
            'id', 'reference', 'trajet', 'trajet_info', 'user_info',
            'statut', 'montant_total', 'montant_rembourse',
            'nb_passagers', 'email_payeur',
            'peut_etre_annulee', 'montant_remboursable', 'peut_etre_notee', 'avis_note',
            'created_at', 'updated_at',
        ]

    def get_peut_etre_notee(self, obj):
        return (obj.statut == Reservation.Statut.CONFIRMEE and not hasattr(obj, 'avis')
                and obj.trajet.heure_depart <= timezone.now())

    def get_avis_note(self, obj):
        return obj.avis.note if hasattr(obj, 'avis') else None

    def get_montant_remboursable(self, obj):
        return obj.calculer_remboursement() if obj.statut == Reservation.Statut.CONFIRMEE else 0

    def get_trajet_info(self, obj):
        t = obj.trajet
        return {
            'id':          str(t.id),
            'depart':      t.ligne.depart.nom,
            'arrivee':     t.ligne.arrivee.nom,
            'heure_depart': t.heure_depart.isoformat(),
            'compagnie':   t.transporteur.nom,
            'prix_fcfa':   t.prix_fcfa,
            'statut':      t.statut,
            'heure_arrivee_estimee': t.heure_arrivee_estimee.isoformat(),
        }

    def get_user_info(self, obj):
        u = obj.user
        return {'nom_complet': u.nom_complet, 'email': u.email, 'telephone': u.telephone}


class ReservationDetailSerializer(ReservationListSerializer):
    passagers = PassagerSerializer(many=True, read_only=True)

    class Meta(ReservationListSerializer.Meta):
        fields = ReservationListSerializer.Meta.fields + ['passagers', 'notes', 'expire_at']


# ── Avis ──────────────────────────────────────────────────────────────────────

class AvisSerializer(serializers.ModelSerializer):
    user_nom      = serializers.ReadOnlyField(source='user.nom_complet')
    user_initiales = serializers.ReadOnlyField(source='user.initiales')

    class Meta:
        model  = Avis
        fields = ['id', 'note', 'commentaire', 'note_ponctualite',
                  'note_confort', 'note_proprete',
                  'user_nom', 'user_initiales', 'est_publie', 'created_at']
        read_only_fields = ['id', 'user_nom', 'user_initiales', 'est_publie', 'created_at']


class CreerAvisSerializer(serializers.ModelSerializer):
    reservation_id = serializers.UUIDField(write_only=True)

    class Meta:
        model  = Avis
        fields = ['reservation_id', 'note', 'commentaire',
                  'note_ponctualite', 'note_confort', 'note_proprete']

    def validate_reservation_id(self, value):
        user = self.context['request'].user
        try:
            res = Reservation.objects.get(
                id=value, user=user, statut=Reservation.Statut.CONFIRMEE)
        except Reservation.DoesNotExist:
            raise serializers.ValidationError('Réservation introuvable ou non confirmée.')
        if hasattr(res, 'avis'):
            raise serializers.ValidationError('Avis déjà publié pour cette réservation.')
        if res.trajet.heure_depart > timezone.now():
            raise serializers.ValidationError('Avis possible uniquement après le trajet.')
        return res

    def create(self, validated_data):
        res = validated_data.pop('reservation_id')
        return Avis.objects.create(
            reservation=res, user=self.context['request'].user,
            trajet=res.trajet, **validated_data)
