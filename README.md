# TamBour (TamBour)

Réservation de transport interurbain en Côte d'Ivoire.

| Dossier | Techno | Rôle |
|---|---|---|
| `backend/` | Python 3.12 · Django 5 · DRF · JWT · PostgreSQL · Celery/Redis | API REST (`/api/v1/`, documentation sur `/api/docs/`) |
| `web_admin/` | Angular 17 | Back-office d'administration |
| `mobile/` | Flutter | Application voyageurs |

## Backend

```bash
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env               # puis renseigner les valeurs
python manage.py migrate
python manage.py seed_donnees      # villes, gares, lignes de démo
python manage.py createsuperuser
python manage.py runserver
```

PostgreSQL et Redis doivent tourner en local (voir `.env`).

## Web admin

```bash
cd web_admin && npm install && npm start    # http://localhost:4200 (proxy vers l'API)
```

## Mobile

```bash
cd mobile && flutter pub get && flutter run
```
