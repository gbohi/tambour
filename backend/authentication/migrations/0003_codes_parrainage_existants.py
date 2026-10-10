import secrets
from django.db import migrations

ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'


def attribuer_codes(apps, schema_editor):
    User = apps.get_model('authentication', 'User')
    pris = set(User.objects.exclude(code_parrainage=None).values_list('code_parrainage', flat=True))
    for user in User.objects.filter(code_parrainage=None):
        code = None
        while not code or code in pris:
            code = 'TB' + ''.join(secrets.choice(ALPHABET) for _ in range(6))
        pris.add(code)
        user.code_parrainage = code
        user.save(update_fields=['code_parrainage'])


class Migration(migrations.Migration):
    dependencies = [('authentication', '0002_parrainage_et_historique_points')]
    operations = [migrations.RunPython(attribuer_codes, migrations.RunPython.noop)]
