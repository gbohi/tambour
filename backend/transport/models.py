import uuid
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
from django.utils import timezone


class Ville(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=100, unique=True)
    region = models.CharField(max_length=100)
    code_iata = models.CharField(max_length=5, blank=True, default='')
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    est_active = models.BooleanField(default=True)
    ordre_affichage = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('ville')
        verbose_name_plural = _('villes')
        ordering = ['ordre_affichage', 'nom']

    def __str__(self):
        return f'{self.nom} ({self.region})'


class Gare(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=200)
    ville = models.ForeignKey(Ville, on_delete=models.CASCADE, related_name='gares')
    adresse = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    telephone = models.CharField(max_length=20, blank=True, default='')
    heures_ouverture = models.CharField(max_length=50, default='05h00 - 22h00')
    est_principale = models.BooleanField(default=False)
    est_active = models.BooleanField(default=True)
    photo = models.ImageField(upload_to='gares/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('gare')
        verbose_name_plural = _('gares')
        ordering = ['-est_principale', 'nom']

    def __str__(self):
        return f'{self.nom} - {self.ville.nom}'


class Transporteur(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField('authentication.User', on_delete=models.CASCADE, related_name='transporteur', null=True, blank=True)
    nom = models.CharField(max_length=200, unique=True)
    logo = models.ImageField(upload_to='transporteurs/logos/', null=True, blank=True)
    email = models.EmailField(unique=True)
    telephone = models.CharField(max_length=20)
    adresse = models.TextField(blank=True, default='')
    rccm = models.CharField(max_length=50, blank=True, default='')
    taux_commission = models.DecimalField(max_digits=5, decimal_places=2, default=10.00, validators=[MinValueValidator(0), MaxValueValidator(100)])
    note_moyenne = models.DecimalField(max_digits=3, decimal_places=2, default=0.00, validators=[MinValueValidator(0), MaxValueValidator(5)])
    nombre_avis = models.PositiveIntegerField(default=0)
    est_actif = models.BooleanField(default=True)
    est_verifie = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('transporteur')
        verbose_name_plural = _('transporteurs')
        ordering = ['-note_moyenne', 'nom']

    def __str__(self):
        return self.nom


class Bus(models.Model):
    class Statut(models.TextChoices):
        ACTIF = 'actif', 'En service'
        MAINTENANCE = 'maintenance', 'En maintenance'
        HORS_SERVICE = 'hors_service', 'Hors service'

    class Classe(models.TextChoices):
        STANDARD = 'standard', 'Standard'
        CONFORT = 'confort', 'Confort'
        VIP = 'vip', 'VIP'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transporteur = models.ForeignKey(Transporteur, on_delete=models.CASCADE, related_name='bus')
    immatriculation = models.CharField(max_length=20, unique=True, db_index=True)
    modele = models.CharField(max_length=100)
    marque = models.CharField(max_length=100, blank=True, default='')
    capacite = models.PositiveSmallIntegerField(validators=[MinValueValidator(10), MaxValueValidator(100)])
    classe = models.CharField(max_length=20, choices=Classe.choices, default=Classe.STANDARD)
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.ACTIF)
    a_wifi = models.BooleanField(default=False)
    a_clim = models.BooleanField(default=True)
    a_usb = models.BooleanField(default=False)
    a_eau = models.BooleanField(default=False)
    a_snack = models.BooleanField(default=False)
    a_siege_large = models.BooleanField(default=False)
    a_toilet = models.BooleanField(default=False)
    assurance_expiration = models.DateField()
    visite_technique_expiration = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('bus')
        verbose_name_plural = _('bus')

    def __str__(self):
        return f'{self.immatriculation} - {self.modele} ({self.transporteur.nom})'

    @property
    def amenities(self):
        items = []
        if self.a_wifi: items.append('wifi')
        if self.a_clim: items.append('clim')
        if self.a_usb: items.append('usb')
        if self.a_eau: items.append('eau')
        if self.a_snack: items.append('snack')
        if self.a_siege_large: items.append('siege_large')
        if self.a_toilet: items.append('toilet')
        return items

    @property
    def assurance_valide(self):
        return self.assurance_expiration >= timezone.now().date()

    @property
    def visite_technique_valide(self):
        return self.visite_technique_expiration >= timezone.now().date()

    @property
    def est_operationnel(self):
        return self.statut == self.Statut.ACTIF and self.assurance_valide and self.visite_technique_valide


class Ligne(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    depart = models.ForeignKey(Ville, on_delete=models.CASCADE, related_name='lignes_depart')
    arrivee = models.ForeignKey(Ville, on_delete=models.CASCADE, related_name='lignes_arrivee')
    gare_depart = models.ForeignKey(Gare, on_delete=models.SET_NULL, null=True, blank=True, related_name='lignes_depart')
    gare_arrivee = models.ForeignKey(Gare, on_delete=models.SET_NULL, null=True, blank=True, related_name='lignes_arrivee')
    distance_km = models.PositiveSmallIntegerField(null=True, blank=True)
    duree_estimee_minutes = models.PositiveSmallIntegerField(null=True, blank=True)
    est_active = models.BooleanField(default=True)
    est_populaire = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('ligne')
        verbose_name_plural = _('lignes')
        unique_together = [['depart', 'arrivee']]
        ordering = ['-est_populaire', 'depart__nom']

    def __str__(self):
        return f'{self.depart.nom} → {self.arrivee.nom}'

    @property
    def duree_label(self):
        if not self.duree_estimee_minutes:
            return None
        h = self.duree_estimee_minutes // 60
        m = self.duree_estimee_minutes % 60
        return f'{h}h{str(m).zfill(2)}' if m else f'{h}h'


class Trajet(models.Model):
    class Statut(models.TextChoices):
        PLANIFIE = 'planifie', 'Planifie'
        EN_COURS = 'en_cours', 'En cours'
        TERMINE = 'termine', 'Termine'
        ANNULE = 'annule', 'Annule'
        RETARDE = 'retarde', 'Retarde'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ligne = models.ForeignKey(Ligne, on_delete=models.CASCADE, related_name='trajets')
    bus = models.ForeignKey(Bus, on_delete=models.SET_NULL, null=True, related_name='trajets')
    transporteur = models.ForeignKey(Transporteur, on_delete=models.CASCADE, related_name='trajets')
    heure_depart = models.DateTimeField()
    heure_arrivee_estimee = models.DateTimeField()
    heure_arrivee_reelle = models.DateTimeField(null=True, blank=True)
    prix_fcfa = models.PositiveIntegerField()
    prix_promo_fcfa = models.PositiveIntegerField(null=True, blank=True)
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.PLANIFIE, db_index=True)
    motif_annulation = models.TextField(blank=True, default='')
    retard_minutes = models.PositiveSmallIntegerField(default=0)
    chauffeur = models.ForeignKey('authentication.User', on_delete=models.SET_NULL, null=True, blank=True,
                                  related_name='trajets_chauffeur', limit_choices_to={'role': 'chauffeur'})
    demarre_le = models.DateTimeField(null=True, blank=True)
    note_moyenne = models.DecimalField(max_digits=3, decimal_places=2, default=0.00, validators=[MinValueValidator(0), MaxValueValidator(5)])
    nombre_avis = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('trajet')
        verbose_name_plural = _('trajets')
        ordering = ['heure_depart']
        indexes = [models.Index(fields=['ligne', 'heure_depart', 'statut']), models.Index(fields=['statut'])]

    def __str__(self):
        return f'{self.ligne} - {self.heure_depart.strftime("%d/%m/%Y %H:%M")}'

    @property
    def prix_actuel(self):
        return self.prix_promo_fcfa or self.prix_fcfa

    @property
    def est_en_promo(self):
        return bool(self.prix_promo_fcfa)

    @property
    def duree_minutes(self):
        diff = self.heure_arrivee_estimee - self.heure_depart
        return int(diff.total_seconds() // 60)

    @property
    def duree_label(self):
        h = self.duree_minutes // 60
        m = self.duree_minutes % 60
        return f'{h}h{str(m).zfill(2)}' if m else f'{h}h'


class Siege(models.Model):
    class Statut(models.TextChoices):
        LIBRE = 'libre', 'Libre'
        RESERVE = 'reserve', 'Reserve'
        OCCUPE = 'occupe', 'Occupe'
        BLOQUE = 'bloque', 'Bloque'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trajet = models.ForeignKey(Trajet, on_delete=models.CASCADE, related_name='sieges')
    numero = models.CharField(max_length=5)
    rangee = models.PositiveSmallIntegerField()
    colonne = models.CharField(max_length=2)
    statut = models.CharField(max_length=10, choices=Statut.choices, default=Statut.LIBRE)
    est_handicap = models.BooleanField(default=False)
    reserve_jusqu = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _('siege')
        verbose_name_plural = _('sieges')
        unique_together = [['trajet', 'numero']]
        ordering = ['rangee', 'colonne']
        indexes = [models.Index(fields=['trajet', 'statut'])]

    def __str__(self):
        return f'Siege {self.numero} - {self.trajet}'

    @property
    def est_disponible(self):
        if self.statut == self.Statut.LIBRE:
            return True
        if self.statut == self.Statut.RESERVE and self.reserve_jusqu and timezone.now() > self.reserve_jusqu:
            return True
        return False

    @classmethod
    def disponibles(cls, trajet):
        """Sièges libres, ou réservés dont la réservation temporaire a expiré."""
        return cls.objects.filter(trajet=trajet).filter(
            models.Q(statut=cls.Statut.LIBRE)
            | models.Q(statut=cls.Statut.RESERVE, reserve_jusqu__lt=timezone.now())
        ).order_by('rangee', 'colonne')

    @classmethod
    def attribuer(cls, trajet, nombre):
        """
        Choisit automatiquement `nombre` sièges disponibles, les uns à côté des autres autant que
        possible (premiers sièges libres dans l'ordre du car). À appeler dans une transaction :
        les sièges retenus sont verrouillés pour éviter une double attribution.
        Retourne None s'il n'y a pas assez de places.
        """
        sieges = list(cls.disponibles(trajet).select_for_update(skip_locked=True)[:nombre])
        return sieges if len(sieges) == nombre else None

    @classmethod
    def generer_pour_trajet(cls, trajet):
        if not trajet.bus:
            return
        colonnes = ['A', 'B', 'C', 'D']
        capacite = trajet.bus.capacite
        rangees_completes = capacite // 4
        reste = capacite % 4
        sieges = []
        for r in range(1, rangees_completes + 1):
            for col in colonnes:
                sieges.append(cls(trajet=trajet, numero=f'{r}{col}', rangee=r, colonne=col))
        if reste > 0:
            for col in colonnes[:reste]:
                r = rangees_completes + 1
                sieges.append(cls(trajet=trajet, numero=f'{r}{col}', rangee=r, colonne=col))
        cls.objects.bulk_create(sieges)
        return sieges


class Horaire(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ligne = models.ForeignKey(Ligne, on_delete=models.CASCADE, related_name='horaires')
    transporteur = models.ForeignKey(Transporteur, on_delete=models.CASCADE, related_name='horaires')
    bus = models.ForeignKey(Bus, on_delete=models.SET_NULL, null=True, blank=True, related_name='horaires')
    heure_depart = models.TimeField()
    prix_fcfa = models.PositiveIntegerField()
    jours = models.JSONField(default=list, help_text='Liste des jours [0=Lundi ... 6=Dimanche]')
    est_actif = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('horaire')
        verbose_name_plural = _('horaires')
        ordering = ['heure_depart']

    def __str__(self):
        return f'{self.ligne} - {self.heure_depart.strftime("%H:%M")}'
