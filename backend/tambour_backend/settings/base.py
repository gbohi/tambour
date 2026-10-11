from pathlib import Path
from datetime import timedelta
from decouple import config, Csv

BASE_DIR = Path(__file__).resolve().parent.parent.parent
SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', cast=Csv())

DJANGO_APPS = [
    'django.contrib.admin', 'django.contrib.auth',
    'django.contrib.contenttypes', 'django.contrib.sessions',
    'django.contrib.messages', 'django.contrib.staticfiles',
]
THIRD_PARTY_APPS = [
    'rest_framework', 'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders', 'django_filters', 'drf_spectacular',
]
LOCAL_APPS = [
    'authentication', 'transport', 'reservations',
    'paiements', 'notifications',
    'dashboard',   # KPI temps réel
    'rapports',    # Exports CSV admin
    'support',     # Centre d'aide, contact, réclamations, avis sur l'app
    'chauffeur',   # Espace chauffeur : trajets, scan des billets
]
INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF     = 'tambour_backend.urls'
WSGI_APPLICATION = 'tambour_backend.wsgi.application'
AUTH_USER_MODEL  = 'authentication.User'

TEMPLATES = [{
    'BACKEND': 'django.template.backends.django.DjangoTemplates',
    'DIRS': [BASE_DIR / 'templates'],
    'APP_DIRS': True,
    'OPTIONS': {'context_processors': [
        'django.template.context_processors.debug',
        'django.template.context_processors.request',
        'django.contrib.auth.context_processors.auth',
        'django.contrib.messages.context_processors.messages',
    ]},
}]

DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.postgresql',
        'NAME':     config('DB_NAME'),
        'USER':     config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST':     config('DB_HOST', default='localhost'),
        'PORT':     config('DB_PORT', default='5432'),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 8}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE     = 'Africa/Abidjan'
USE_I18N      = True
USE_TZ        = True

STATIC_URL  = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL   = '/media/'
MEDIA_ROOT  = BASE_DIR / 'media'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ['rest_framework_simplejwt.authentication.JWTAuthentication'],
    'DEFAULT_PERMISSION_CLASSES':     ['rest_framework.permissions.IsAuthenticated'],
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    'DEFAULT_PAGINATION_CLASS': 'tambour_backend.utils.EnveloppePagination',
    'PAGE_SIZE': 20,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'EXCEPTION_HANDLER': 'tambour_backend.utils.custom_exception_handler',
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME':  timedelta(minutes=config('JWT_ACCESS_MINUTES', default=60, cast=int)),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=config('JWT_REFRESH_DAYS', default=30, cast=int)),
    'ROTATE_REFRESH_TOKENS':  True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'AUTH_HEADER_TYPES': ('Bearer',),
}

CORS_ALLOWED_ORIGINS = ['http://localhost:4200', 'http://localhost:3000']
CORS_ALLOW_CREDENTIALS = True

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': config('REDIS_URL', default='redis://localhost:6379/0'),
        'OPTIONS': {'CLIENT_CLASS': 'django_redis.client.DefaultClient'},
    }
}

CELERY_BROKER_URL   = config('REDIS_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND = config('REDIS_URL', default='redis://localhost:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Africa/Abidjan'

EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST          = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT          = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS       = True
EMAIL_HOST_USER     = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL  = config('DEFAULT_FROM_EMAIL', default='TamBour <noreply@tambour.ci>')

CINETPAY_API_KEY   = config('CINETPAY_API_KEY', default='')
CINETPAY_SITE_ID   = config('CINETPAY_SITE_ID', default='')
CINETPAY_SECRET_KEY = config('CINETPAY_SECRET_KEY', default='')
CINETPAY_BASE_URL  = config('CINETPAY_BASE_URL', default='https://api-checkout.cinetpay.com/v2')

AT_USERNAME  = config('AT_USERNAME', default='sandbox')
AT_API_KEY   = config('AT_API_KEY', default='')
AT_SENDER_ID = config('AT_SENDER_ID', default='TamBour')

# Parrainage : points offerts au parrain et au nouvel inscrit (filleul)
POINTS_PARRAIN = config('POINTS_PARRAIN', default=500, cast=int)
POINTS_FILLEUL = config('POINTS_FILLEUL', default=200, cast=int)
LIEN_TELECHARGEMENT_APP = config('LIEN_TELECHARGEMENT_APP', default='https://tambour.ci/app')

# Support client (affiché dans l'application)
SUPPORT_TELEPHONE = config('SUPPORT_TELEPHONE', default='+225 07 00 00 00 00')
SUPPORT_WHATSAPP  = config('SUPPORT_WHATSAPP', default='+2250700000000')
SUPPORT_EMAIL     = config('SUPPORT_EMAIL', default='support@tambour.ci')
SUPPORT_HORAIRES  = config('SUPPORT_HORAIRES', default='Tous les jours, 6h – 22h')

FRONTEND_URL = config('FRONTEND_URL', default='http://localhost:4200')

SPECTACULAR_SETTINGS = {
    'TITLE': 'TamBour API',
    'DESCRIPTION': "API REST TamBour — Transport interurbain Côte d'Ivoire",
    'VERSION': '2.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}
