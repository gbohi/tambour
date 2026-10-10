import uuid
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.utils.translation import gettext_lazy as _


class Reservation(models.Model):
    class Statut(models.TextChoices):
        EN_ATTENTE  = 'en_attente',  'En attente de paiement'
        CONFIRMEE   = 'confirmee',   'Confirmée'
        ANNULEE     = 'annulee',     'Annulée'
        EXPIREE     = 'expiree',     'Expirée'
        REMBOURSEE  = 'remboursee',  'Remboursée'

    id             = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reference      = models.CharField(max_length=20, unique=True, db_index=True, editable=False)
    user           = models.ForeignKey('authentication.User', on_delete=models.CASCADE, related_name='reservations')
    trajet         = models.ForeignKey('transport.Trajet',    on_delete=models.CASCADE, related_name='reservations')
    statut         = models.CharField(max_length=20, choices=Statut.choices, default=Statut.EN_ATTENTE, db_index=True)
    montant_total  = models.PositiveIntegerField()
    montant_rembourse = models.PositiveIntegerField(default=0)
    nb_passagers   = models.PositiveSmallIntegerField(default=1, validators=[MinValueValidator(1), MaxValueValidator(9)])
    # Email du payeur — reçoit tous les billets PDF
    email_payeur   = models.EmailField(blank=True, default='')
    expire_at      = models.DateTimeField(null=True, blank=True)
    notes          = models.TextField(blank=True, default='')
    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = _('reservation')
        verbose_name_plural = _('reservations')
        ordering = ['-created_at']
        indexes  = [
            models.Index(fields=['user', 'statut']),
            models.Index(fields=['trajet', 'statut']),
            models.Index(fields=['reference']),
        ]

    def __str__(self):
        return f'{self.reference} - {self.user.nom_complet}'

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = self._generer_reference()
        if not self.expire_at:
            self.expire_at = timezone.now() + timezone.timedelta(minutes=15)
        super().save(*args, **kwargs)

    def _generer_reference(self):
        import random, string
        now    = timezone.now()
        prefix = f'TB{now.year}{str(now.month).zfill(2)}'
        suffix = ''.join(random.choices(string.digits, k=6))
        return f'{prefix}{suffix}'

    @property
    def est_expiree(self):
        if self.statut == self.Statut.EN_ATTENTE:
            return bool(self.expire_at and timezone.now() > self.expire_at)
        return False

    @property
    def peut_etre_annulee(self):
        if self.statut != self.Statut.CONFIRMEE:
            return False
        heures = (self.trajet.heure_depart - timezone.now()).total_seconds() / 3600
        return heures >= 2

    def calculer_remboursement(self):
        heures = (self.trajet.heure_depart - timezone.now()).total_seconds() / 3600
        if heures >= 24: return self.montant_total
        if heures >= 12: return int(self.montant_total * 0.75)
        if heures >= 2:  return int(self.montant_total * 0.50)
        return 0

    def confirmer(self):
        self.statut   = self.Statut.CONFIRMEE
        self.expire_at = None
        self.save(update_fields=['statut', 'expire_at', 'updated_at'])

    def annuler(self, motif=''):
        self.statut = self.Statut.ANNULEE
        self.notes  = motif
        self.save(update_fields=['statut', 'notes', 'updated_at'])


class Passager(models.Model):
    """
    Un passager par siège — sans pièce d'identité.
    email facultatif : le billet individuel lui est envoyé si renseigné.
    """
    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reservation = models.ForeignKey(Reservation, on_delete=models.CASCADE, related_name='passagers')
    # Siège attribué automatiquement. Un siège peut être réattribué après expiration ou
    # annulation d'une réservation, d'où une ForeignKey (l'historique des passagers est conservé).
    siege       = models.ForeignKey('transport.Siege', on_delete=models.CASCADE,
                                    related_name='passagers', related_query_name='passager')
    prenom      = models.CharField(max_length=100)
    nom         = models.CharField(max_length=100)
    telephone   = models.CharField(max_length=20)
    email       = models.EmailField(blank=True, default='')  # facultatif
    ordre       = models.PositiveSmallIntegerField(default=1)  # position dans la réservation
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name        = _('passager')
        verbose_name_plural = _('passagers')
        ordering            = ['ordre']

    def __str__(self):
        return f'{self.prenom} {self.nom} — Siège {self.siege.numero}'

    @property
    def nom_complet(self):
        return f'{self.prenom} {self.nom}'.strip()


class Billet(models.Model):
    """
    UN billet par passager (OneToOne sur Passager).
    QR unique contenant : REF|PASSAGER_ID|SIEGE|NOM_COMPLET
    """
    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    passager   = models.OneToOneField(Passager,    on_delete=models.CASCADE, related_name='billet')
    reservation = models.ForeignKey(Reservation,  on_delete=models.CASCADE, related_name='billets')
    qr_data    = models.TextField()
    numero     = models.PositiveSmallIntegerField(default=1)  # 1/3, 2/3...
    est_valide = models.BooleanField(default=True)
    utilise_le = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name        = _('billet')
        verbose_name_plural = _('billets')
        ordering            = ['numero']

    def __str__(self):
        return f'Billet {self.reservation.reference}-P{self.numero}'

    def save(self, *args, **kwargs):
        if not self.qr_data:
            self.qr_data = self._generer_qr_data()
        super().save(*args, **kwargs)

    def _generer_qr_data(self):
        res = self.reservation
        p   = self.passager
        return (
            f'TAMBOUR|{res.reference}|{self.numero}'
            f'|{res.trajet_id}'
            f'|{res.trajet.ligne.depart.id}|{res.trajet.ligne.arrivee.id}'
            f'|{res.trajet.heure_depart.isoformat()}'
            f'|{p.siege.numero}|{p.nom_complet}'
        )

    @property
    def reference_billet(self):
        return f'{self.reservation.reference}-P{self.numero}'

    def valider(self):
        self.utilise_le = timezone.now()
        self.est_valide = False
        self.save(update_fields=['utilise_le', 'est_valide'])


class Avis(models.Model):
    id               = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reservation      = models.OneToOneField(Reservation, on_delete=models.CASCADE, related_name='avis')
    user             = models.ForeignKey('authentication.User', on_delete=models.CASCADE, related_name='avis')
    trajet           = models.ForeignKey('transport.Trajet',    on_delete=models.CASCADE, related_name='avis')
    note             = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    commentaire      = models.TextField(blank=True, default='')
    note_ponctualite = models.PositiveSmallIntegerField(null=True, blank=True, validators=[MinValueValidator(1), MaxValueValidator(5)])
    note_confort     = models.PositiveSmallIntegerField(null=True, blank=True, validators=[MinValueValidator(1), MaxValueValidator(5)])
    note_proprete    = models.PositiveSmallIntegerField(null=True, blank=True, validators=[MinValueValidator(1), MaxValueValidator(5)])
    est_publie       = models.BooleanField(default=True)
    created_at       = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name        = _('avis')
        verbose_name_plural = _('avis')
        ordering            = ['-created_at']

    def __str__(self):
        return f'Avis {self.note}/5 — {self.reservation.reference}'
