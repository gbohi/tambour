import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        VOYAGEUR = 'voyageur', 'Voyageur'
        TRANSPORTEUR = 'transporteur', 'Transporteur'
        ADMIN = 'admin', 'Administrateur'
        SUPPORT = 'support', 'Support'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(_('adresse email'), unique=True, db_index=True)
    prenom = models.CharField(_('prenom'), max_length=100)
    nom = models.CharField(_('nom'), max_length=100)
    telephone = models.CharField(_('telephone'), max_length=20, blank=True, default='')
    avatar = models.ImageField(_('avatar'), upload_to='avatars/', blank=True, null=True)
    role = models.CharField(_('role'), max_length=20, choices=Role.choices, default=Role.VOYAGEUR)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(_('email verifie'), default=False)
    notif_sms = models.BooleanField(default=True)
    notif_push = models.BooleanField(default=True)
    notif_email = models.BooleanField(default=True)
    notif_promotions = models.BooleanField(default=True)
    points_fidelite = models.PositiveIntegerField(default=0)
    nb_voyages = models.PositiveIntegerField(default=0)
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['prenom', 'nom']

    class Meta:
        verbose_name = _('utilisateur')
        verbose_name_plural = _('utilisateurs')
        ordering = ['-date_joined']
        indexes = [models.Index(fields=['email']), models.Index(fields=['role'])]

    def __str__(self):
        return f'{self.prenom} {self.nom} <{self.email}>'

    @property
    def nom_complet(self):
        return f'{self.prenom} {self.nom}'.strip()

    @property
    def initiales(self):
        p = self.prenom[0].upper() if self.prenom else ''
        n = self.nom[0].upper() if self.nom else ''
        return f'{p}{n}'

    def ajouter_points(self, points):
        self.points_fidelite += points
        self.save(update_fields=['points_fidelite'])

    def incrementer_voyages(self):
        self.nb_voyages += 1
        self.save(update_fields=['nb_voyages'])


class CodeVerification(models.Model):
    class TypeCode(models.TextChoices):
        EMAIL = 'email', 'Verification email'
        TELEPHONE = 'telephone', 'Verification telephone'
        MOT_DE_PASSE = 'mot_de_passe', 'Reinitialisation mot de passe'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='codes_verification')
    code = models.CharField(max_length=6)
    type_code = models.CharField(max_length=20, choices=TypeCode.choices)
    est_utilise = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expire_at = models.DateTimeField()

    class Meta:
        verbose_name = _('code de verification')
        verbose_name_plural = _('codes de verification')
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user.email} - {self.type_code} - {self.code}'

    @property
    def est_expire(self):
        return timezone.now() > self.expire_at

    @property
    def est_valide(self):
        return not self.est_utilise and not self.est_expire

    @classmethod
    def generer(cls, user, type_code):
        import random
        from datetime import timedelta
        cls.objects.filter(user=user, type_code=type_code, est_utilise=False).update(est_utilise=True)
        code = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        expire_at = timezone.now() + timedelta(minutes=15)
        return cls.objects.create(user=user, code=code, type_code=type_code, expire_at=expire_at)


class SessionAppareil(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sessions_appareils')
    token_jti = models.CharField(max_length=255, unique=True, db_index=True)
    appareil = models.CharField(max_length=200, blank=True, default='')
    systeme = models.CharField(max_length=100, blank=True, default='')
    adresse_ip = models.GenericIPAddressField(null=True, blank=True)
    est_actif = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_active = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('session appareil')
        verbose_name_plural = _('sessions appareils')
        ordering = ['-last_active']

    def __str__(self):
        return f'{self.user.email} - {self.appareil}'
