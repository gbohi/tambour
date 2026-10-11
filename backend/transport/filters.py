import django_filters
from .models import Trajet, Bus

class TrajetFilter(django_filters.FilterSet):
    date = django_filters.DateFilter(field_name='heure_depart', lookup_expr='date')
    prix_min = django_filters.NumberFilter(field_name='prix_fcfa', lookup_expr='gte')
    prix_max = django_filters.NumberFilter(field_name='prix_fcfa', lookup_expr='lte')
    classe = django_filters.CharFilter(field_name='bus__classe')
    sans_chauffeur = django_filters.BooleanFilter(field_name='chauffeur', lookup_expr='isnull')
    a_venir = django_filters.BooleanFilter(method='filtrer_a_venir')

    def filtrer_a_venir(self, queryset, name, value):
        from django.utils import timezone
        return queryset.filter(heure_depart__gte=timezone.now()) if value else queryset

    class Meta:
        model = Trajet
        fields = ['date', 'prix_min', 'prix_max', 'classe', 'statut', 'transporteur', 'chauffeur']
