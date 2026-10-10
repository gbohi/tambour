# Migration initiale — générée par makemigrations
# Lancez : python manage.py makemigrations reservations
from django.db import migrations

class Migration(migrations.Migration):
    initial = True
    dependencies = [
        ('authentication', '0001_initial'),
        ('transport', '0001_initial'),
    ]
    operations = []
