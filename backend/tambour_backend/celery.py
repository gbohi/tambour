import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tambour_backend.settings.development')

app = Celery('tambour_backend')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

app.conf.beat_schedule = {
    'rappels-voyages': {
        'task': 'notifications.envoyer_rappels_voyages',
        'schedule': crontab(minute=0),
    },
    'expirer-reservations': {
        'task': 'notifications.expirer_reservations',
        'schedule': crontab(minute='*/5'),
    },
    'generer-trajets': {
        'task': 'notifications.generer_trajets_depuis_horaires',
        'schedule': crontab(hour=23, minute=0),
    },
    'versements-mensuels': {
        'task': 'notifications.calculer_versements_mensuels',
        'schedule': crontab(hour=0, minute=30, day_of_month=1),
    },
    'nettoyer-tokens': {
        'task': 'notifications.nettoyer_tokens_push_invalides',
        'schedule': crontab(hour=3, minute=0, day_of_week=0),
    },
}
app.conf.timezone = 'Africa/Abidjan'
