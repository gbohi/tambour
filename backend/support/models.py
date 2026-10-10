import uuid
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _


class QuestionFAQ(models.Model):
    """Questions fréquentes affichées dans le centre d'aide de l'application."""
    class Categorie(models.TextChoices):
        RESERVATION = 'reservation', 'Réservation'
        PAIEMENT = 'paiement', 'Paiement'
        BILLET = 'billet', 'Billets & embarquement'
        ANNULATION = 'annulation', 'Annulation & remboursement'
        FIDELITE = 'fidelite', 'Fidélité & parrainage'
        COMPTE = 'compte', 'Mon compte'

    categorie = models.CharField(max_length=20, choices=Categorie.choices)
    question = models.CharField(max_length=255)
    reponse = models.TextField()
    ordre = models.PositiveSmallIntegerField(default=0)
    est_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = _('question fréquente')
        verbose_name_plural = _('questions fréquentes')
        ordering = ['categorie', 'ordre', 'id']

    def __str__(self):
        return self.question


class MessageSupport(models.Model):
    """Message envoyé depuis « Contacter le support »."""
    class Statut(models.TextChoices):
        NOUVEAU = 'nouveau', 'Nouveau'
        EN_COURS = 'en_cours', 'En cours'
        TRAITE = 'traite', 'Traité'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                             null=True, blank=True, related_name='messages_support')
    nom = models.CharField(max_length=200)
    email = models.EmailField(blank=True, default='')
    telephone = models.CharField(max_length=20, blank=True, default='')
    sujet = models.CharField(max_length=200)
    message = models.TextField()
    statut = models.CharField(max_length=10, choices=Statut.choices, default=Statut.NOUVEAU)
    reponse = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('message au support')
        verbose_name_plural = _('messages au support')
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.nom} — {self.sujet}'


class Reclamation(models.Model):
    """Réclamation d'un voyageur, éventuellement liée à une réservation."""
    class Categorie(models.TextChoices):
        PAIEMENT = 'paiement', 'Problème de paiement'
        BILLET = 'billet', 'Billet non reçu ou invalide'
        REMBOURSEMENT = 'remboursement', 'Annulation / remboursement'
        RETARD = 'retard', 'Retard ou annulation du car'
        BAGAGE = 'bagage', 'Bagage perdu ou endommagé'
        SERVICE = 'service', 'Accueil ou comportement du personnel'
        AUTRE = 'autre', 'Autre'

    class Statut(models.TextChoices):
        OUVERTE = 'ouverte', 'Ouverte'
        EN_COURS = 'en_cours', 'En cours de traitement'
        RESOLUE = 'resolue', 'Résolue'
        REJETEE = 'rejetee', 'Rejetée'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reference = models.CharField(max_length=20, unique=True, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reclamations')
    reservation = models.ForeignKey('reservations.Reservation', on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='reclamations')
    reference_reservation = models.CharField(max_length=30, blank=True, default='')
    categorie = models.CharField(max_length=20, choices=Categorie.choices)
    sujet = models.CharField(max_length=200)
    description = models.TextField()
    statut = models.CharField(max_length=10, choices=Statut.choices, default=Statut.OUVERTE)
    reponse = models.TextField(blank=True, default='')
    traitee_le = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('réclamation')
        verbose_name_plural = _('réclamations')
        ordering = ['-created_at']
        indexes = [models.Index(fields=['statut'])]

    def __str__(self):
        return f'{self.reference} — {self.sujet}'

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = self._generer_reference()
        if self.statut in (self.Statut.RESOLUE, self.Statut.REJETEE) and not self.traitee_le:
            self.traitee_le = timezone.now()
        super().save(*args, **kwargs)

    @staticmethod
    def _generer_reference():
        import secrets
        now = timezone.now()
        while True:
            ref = f'REC{now.year}{now.month:02d}{secrets.randbelow(10**5):05d}'
            if not Reclamation.objects.filter(reference=ref).exists():
                return ref


class AvisApplication(models.Model):
    """Note donnée à l'application (une par utilisateur, modifiable)."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='avis_application')
    note = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    commentaire = models.TextField(blank=True, default='')
    plateforme = models.CharField(max_length=20, blank=True, default='')
    version_app = models.CharField(max_length=20, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("avis sur l'application")
        verbose_name_plural = _("avis sur l'application")
        ordering = ['-updated_at']

    def __str__(self):
        return f'{self.user} — {self.note}/5'
