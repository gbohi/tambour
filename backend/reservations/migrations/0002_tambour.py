"""
Migration TamBour :
- Passager : suppression type_piece/numero_piece, ajout email + ordre
- Reservation : ajout email_payeur
- Billet : OneToOne Passager (au lieu de Reservation), ajout numero
"""
import uuid
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('reservations', '0001_initial'),
    ]

    operations = [
        # 1. Passager : supprimer pièce d'identité, ajouter email + ordre
        migrations.AddField(model_name='passager', name='email',
            field=models.EmailField(blank=True, default='', max_length=254)),
        migrations.AddField(model_name='passager', name='ordre',
            field=models.PositiveSmallIntegerField(default=1)),
        migrations.RemoveField(model_name='passager', name='type_piece'),
        migrations.RemoveField(model_name='passager', name='numero_piece'),

        # 2. Reservation : ajouter email_payeur
        migrations.AddField(model_name='reservation', name='email_payeur',
            field=models.EmailField(blank=True, default='', max_length=254)),

        # 3. Billet : restructurer (1 billet par passager)
        migrations.DeleteModel(name='Billet'),
        migrations.CreateModel(
            name='Billet',
            fields=[
                ('id',         models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True)),
                ('qr_data',    models.TextField()),
                ('numero',     models.PositiveSmallIntegerField(default=1)),
                ('est_valide', models.BooleanField(default=True)),
                ('utilise_le', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('passager',   models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='billet', to='reservations.passager')),
                ('reservation', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='billets', to='reservations.reservation')),
            ],
            options={'verbose_name': 'billet', 'verbose_name_plural': 'billets',
                     'ordering': ['numero']},
        ),
    ]
