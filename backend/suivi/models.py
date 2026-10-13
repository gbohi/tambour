from django.db import models


class PositionGPS(models.Model):
    """Position du car envoyée par l'application chauffeur pendant le trajet."""
    trajet = models.ForeignKey('transport.Trajet', on_delete=models.CASCADE, related_name='positions')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    vitesse_kmh = models.FloatField(null=True, blank=True)
    cap = models.FloatField(null=True, blank=True, help_text='Direction en degrés (0 = nord)')
    precision_m = models.FloatField(null=True, blank=True)
    enregistre_le = models.DateTimeField(db_index=True)

    class Meta:
        verbose_name = 'Position GPS'
        verbose_name_plural = 'Positions GPS'
        ordering = ['-enregistre_le']
        indexes = [models.Index(fields=['trajet', '-enregistre_le'])]

    def __str__(self):
        return f'{self.trajet_id} @ {self.enregistre_le:%H:%M:%S}'
