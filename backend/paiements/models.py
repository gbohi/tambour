import uuid
from django.db import models
from django.utils.translation import gettext_lazy as _


class Paiement(models.Model):
    class Methode(models.TextChoices):
        MTN_MOMO = 'mtn_momo', 'MTN Mobile Money'
        ORANGE_MONEY = 'orange_money', 'Orange Money'
        WAVE = 'wave', 'Wave'
        CARTE = 'carte', 'Carte bancaire'

    class Statut(models.TextChoices):
        INITIE = 'initie', 'Initie'
        EN_ATTENTE = 'en_attente', 'En attente de confirmation'
        SUCCES = 'succes', 'Succes'
        ECHEC = 'echec', 'Echec'
        REMBOURSE = 'rembourse', 'Rembourse'
        ANNULE = 'annule', 'Annule'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reservation = models.ForeignKey('reservations.Reservation', on_delete=models.CASCADE, related_name='paiements')
    user = models.ForeignKey('authentication.User', on_delete=models.CASCADE, related_name='paiements')
    methode = models.CharField(max_length=20, choices=Methode.choices)
    montant = models.PositiveIntegerField()
    montant_rembourse = models.PositiveIntegerField(default=0)
    telephone = models.CharField(max_length=20)
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.INITIE, db_index=True)
    reference = models.CharField(max_length=50, unique=True, db_index=True)
    reference_operateur = models.CharField(max_length=100, blank=True, default='')
    transaction_id_operateur = models.CharField(max_length=200, blank=True, default='')
    url_paiement = models.URLField(blank=True, default='')
    donnees_operateur = models.JSONField(default=dict, blank=True)
    message_erreur = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    confirme_le = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _('paiement')
        verbose_name_plural = _('paiements')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reservation', 'statut']),
            models.Index(fields=['reference']),
            models.Index(fields=['user', 'statut']),
        ]

    def __str__(self):
        return f'{self.reference} - {self.montant} FCFA - {self.get_statut_display()}'

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = self._generer_reference()
        super().save(*args, **kwargs)

    def _generer_reference(self):
        from django.utils import timezone
        import random, string
        now = timezone.now()
        suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        return f'PAY-{now.strftime("%Y%m%d")}-{suffix}'


class Versement(models.Model):
    class Statut(models.TextChoices):
        EN_ATTENTE = 'en_attente', 'En attente'
        TRAITE = 'traite', 'Traite'
        ECHEC = 'echec', 'Echec'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transporteur = models.ForeignKey('transport.Transporteur', on_delete=models.CASCADE, related_name='versements')
    periode_debut = models.DateField()
    periode_fin = models.DateField()
    montant_brut = models.PositiveIntegerField()
    commission_yobus = models.PositiveIntegerField()
    montant_net = models.PositiveIntegerField()
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.EN_ATTENTE)
    reference_virement = models.CharField(max_length=100, blank=True, default='')
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    traite_le = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _('versement')
        verbose_name_plural = _('versements')
        ordering = ['-periode_fin']

    def __str__(self):
        return f'{self.transporteur.nom} - {self.periode_debut} - {self.montant_net:,} FCFA'
