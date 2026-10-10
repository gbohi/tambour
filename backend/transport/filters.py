import django_filters
from .models import Trajet, Bus

class TrajetFilter(django_filters.FilterSet):
    date = django_filters.DateFilter(field_name='heure_depart', lookup_expr='date')
    prix_min = django_filters.NumberFilter(field_name='prix_fcfa', lookup_expr='gte')
    prix_max = django_filters.NumberFilter(field_name='prix_fcfa', lookup_expr='lte')
    classe = django_filters.CharFilter(field_name='bus__classe')

    class Meta:
        model = Trajet
        fields = ['date', 'prix_min', 'prix_max', 'classe', 'statut', 'transporteur']
