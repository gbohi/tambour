from django.db import migrations

ANCIENNE = 'MTN Mobile Money, Orange Money, Wave et carte bancaire.'
NOUVELLE = 'Orange Money, MTN Mobile Money, Moov Money, Wave et carte bancaire (Visa, Mastercard).'


def maj(apps, schema_editor, de, vers):
    apps.get_model('support', 'QuestionFAQ').objects.filter(reponse=de).update(reponse=vers)


class Migration(migrations.Migration):
    dependencies = [('support', '0002_faq_initiale')]
    operations = [migrations.RunPython(
        lambda a, s: maj(a, s, ANCIENNE, NOUVELLE),
        lambda a, s: maj(a, s, NOUVELLE, ANCIENNE))]
