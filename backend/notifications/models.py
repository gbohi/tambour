import uuid
from django.db import models
from django.utils.translation import gettext_lazy as _


class Notification(models.Model):
    class Type(models.TextChoices):
        CONFIRMATION = 'confirmation', 'Reservation confirmee'
        RAPPEL = 'rappel', 'Rappel de voyage'
        RETARD = 'retard', 'Retard signale'
        ANNULATION = 'annulation', 'Annulation'
        PROMOTION = 'promotion', 'Promotion'
        PAIEMENT = 'paiement', 'Paiement'
        REMBOURSEMENT = 'remboursement', 'Remboursement'
        INFO = 'info', 'Information'
        SYSTEME = 'systeme', 'Systeme'

    class Canal(models.TextChoices):
        IN_APP = 'in_app', 'In-App'
        SMS = 'sms', 'SMS'
        EMAIL = 'email', 'Email'
        PUSH = 'push', 'Push'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey('authentication.User', on_delete=models.CASCADE, related_name='notifications')
    type_notif = models.CharField(max_length=20, choices=Type.choices, db_index=True)
    canal = models.CharField(max_length=10, choices=Canal.choices, default=Canal.IN_APP)
    titre = models.CharField(max_length=200)
    message = models.TextField()
    lue = models.BooleanField(default=False, db_index=True)
    lue_le = models.DateTimeField(null=True, blank=True)
    reservation_id = models.UUIDField(null=True, blank=True)
    trajet_id = models.UUIDField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = _('notification')
        verbose_name_plural = _('notifications')
        ordering = ['-created_at']
        indexes = [models.Index(fields=['user', 'lue']), models.Index(fields=['user', 'type_notif'])]

    def __str__(self):
        return f'{self.user.email} - {self.titre}'

    def marquer_lue(self):
        from django.utils import timezone
        if not self.lue:
            self.lue = True
            self.lue_le = timezone.now()
            self.save(update_fields=['lue', 'lue_le'])


class TokenPush(models.Model):
    class Plateforme(models.TextChoices):
        ANDROID = 'android', 'Android'
        IOS = 'ios', 'iOS'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey('authentication.User', on_delete=models.CASCADE, related_name='tokens_push')
    token = models.TextField(unique=True)
    plateforme = models.CharField(max_length=10, choices=Plateforme.choices)
    est_actif = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('token push')
        verbose_name_plural = _('tokens push')

    def __str__(self):
        return f'{self.user.email} - {self.plateforme}'


class LogSMS(models.Model):
    class Statut(models.TextChoices):
        ENVOYE = 'envoye', 'Envoye'
        ECHEC = 'echec', 'Echec'
        EN_ATTENTE = 'en_attente', 'En attente'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey('authentication.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='logs_sms')
    telephone = models.CharField(max_length=20)
    message = models.TextField()
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.EN_ATTENTE)
    reference_at = models.CharField(max_length=100, blank=True, default='')
    cout = models.DecimalField(max_digits=10, decimal_places=6, null=True, blank=True)
    message_erreur = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('log SMS')
        verbose_name_plural = _('logs SMS')
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.telephone} - {self.statut}'
