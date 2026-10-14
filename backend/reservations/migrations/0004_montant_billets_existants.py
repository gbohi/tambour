from django.db import migrations
from django.db.models import F


def reprendre(apps, schema_editor):
    # Réservations antérieures aux frais de service : le total correspondait au prix des billets.
    apps.get_model('reservations', 'Reservation').objects.filter(montant_billets=0).update(
        montant_billets=F('montant_total'), frais_service=0)


class Migration(migrations.Migration):
    dependencies = [('reservations', '0003_reservation_frais_service_and_more')]
    operations = [migrations.RunPython(reprendre, migrations.RunPython.noop)]
