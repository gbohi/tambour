from decimal import Decimal, ROUND_HALF_UP
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone


class ParametresPlateforme(models.Model):
    """Réglages modifiables par l'administrateur (une seule ligne en base)."""

    class ModeFrais(models.TextChoices):
        PAR_RESERVATION = 'par_reservation', 'Montant fixe par réservation'
        PAR_PASSAGER = 'par_passager', 'Montant fixe par passager'
        POURCENTAGE = 'pourcentage', 'Pourcentage du prix des billets'

    frais_service_mode = models.CharField(max_length=20, choices=ModeFrais.choices, default=ModeFrais.PAR_RESERVATION)
    frais_service_valeur = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal('500'), validators=[MinValueValidator(0)],
        help_text='En FCFA (montant fixe) ou en % selon le mode')
    frais_service_minimum = models.PositiveIntegerField(default=0, help_text='En FCFA, pour le mode pourcentage')
    frais_remboursables = models.BooleanField(
        default=False, help_text="Si non, les frais de service sont conservés en cas d'annulation")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Paramètres de la plateforme'
        verbose_name_plural = 'Paramètres de la plateforme'

    def __str__(self):
        return 'Paramètres de la plateforme'

    def save(self, *args, **kwargs):
        self.pk = 1   # une seule ligne
        super().save(*args, **kwargs)

    @classmethod
    def actuels(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def calculer_frais(self, montant_billets: int, nb_passagers: int) -> int:
        v = Decimal(str(self.frais_service_valeur))
        if self.frais_service_mode == self.ModeFrais.PAR_PASSAGER:
            frais = v * nb_passagers
        elif self.frais_service_mode == self.ModeFrais.POURCENTAGE:
            frais = max(Decimal(montant_billets) * v / 100, Decimal(self.frais_service_minimum))
        else:
            frais = v
        # Arrondi à 5 FCFA, la plus petite pièce en circulation
        return int((frais / 5).quantize(Decimal('1'), rounding=ROUND_HALF_UP) * 5)

    @property
    def libelle_frais(self):
        v = self.frais_service_valeur.normalize()
        montant = f'{int(v):,}'.replace(',', ' ')
        if self.frais_service_mode == self.ModeFrais.PAR_PASSAGER:
            return f'{montant} FCFA par passager'
        if self.frais_service_mode == self.ModeFrais.POURCENTAGE:
            return f'{v} % du prix des billets'
        return f'{montant} FCFA par réservation'


class Banniere(models.Model):
    """Visuel du carrousel de la page d'accueil (app et site), géré depuis l'admin."""

    class Action(models.TextChoices):
        AUCUNE = 'aucune', 'Aucune (visuel seul)'
        RECHERCHE = 'recherche', 'Rechercher une ligne'
        PAGE = 'page', "Ouvrir une page de l'application"
        LIEN = 'lien', 'Ouvrir un lien web'

    class Page(models.TextChoices):
        FIDELITE = 'fidelite', 'Fidélité & parrainage'
        GARES = 'gares', 'Carte des gares'
        LIGNES = 'lignes', 'Lignes populaires'
        AIDE = 'aide', "Centre d'aide"

    titre = models.CharField(max_length=80)
    sous_titre = models.CharField(max_length=140, blank=True, default='')
    image = models.ImageField(upload_to='bannieres/', null=True, blank=True,
                              help_text='Format paysage conseillé : 1200 × 600 px')
    couleur_fond = models.CharField(max_length=7, default='#0F4A3B', help_text='Utilisée sans image ou pendant le chargement')
    texte_bouton = models.CharField(max_length=30, blank=True, default='')
    action = models.CharField(max_length=12, choices=Action.choices, default=Action.AUCUNE)
    depart = models.ForeignKey('transport.Ville', on_delete=models.SET_NULL, null=True, blank=True, related_name='+')
    arrivee = models.ForeignKey('transport.Ville', on_delete=models.SET_NULL, null=True, blank=True, related_name='+')
    page = models.CharField(max_length=12, choices=Page.choices, blank=True, default='')
    lien = models.URLField(blank=True, default='')
    ordre = models.PositiveSmallIntegerField(default=0)
    est_active = models.BooleanField(default=True)
    debut = models.DateTimeField(null=True, blank=True, help_text='Affichée à partir de cette date (facultatif)')
    fin = models.DateTimeField(null=True, blank=True, help_text="Retirée après cette date (facultatif)")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Bannière d'accueil"
        verbose_name_plural = "Bannières d'accueil"
        ordering = ['ordre', '-created_at']

    def __str__(self):
        return self.titre

    @classmethod
    def visibles(cls):
        maintenant = timezone.now()
        return (cls.objects.filter(est_active=True)
                .filter(models.Q(debut__isnull=True) | models.Q(debut__lte=maintenant))
                .filter(models.Q(fin__isnull=True) | models.Q(fin__gte=maintenant))
                .select_related('depart', 'arrivee'))
