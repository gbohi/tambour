# TamBour (TamBour)

Réservation de transport interurbain en Côte d'Ivoire.

| Dossier | Techno | Rôle |
|---|---|---|
| `backend/` | Python 3.12 · Django 5 · DRF · JWT · PostgreSQL · Celery/Redis | API REST (`/api/v1/`, documentation sur `/api/docs/`) |
| `web_admin/` | Angular 17 | Back-office d'administration |
| `mobile/` | Flutter | Application voyageurs |

## Fonctionnalités récentes

- **Sièges attribués automatiquement** : plus de choix de siège ; à la réservation, l'API attribue les premières
  places libres du car (passagers côte à côte), avec verrouillage pour éviter les doubles attributions.
- **Lignes populaires** : `GET /api/v1/lignes/populaires/` et page « Voir tout » dans l'application.
- **Fidélité & parrainage** : chaque utilisateur a un code (ex. `TB7K2QX9`). À l'inscription avec ce code, le parrain
  et le filleul gagnent des points (`POINTS_PARRAIN`, `POINTS_FILLEUL` dans `.env`). Historique des points
  (`GET /api/v1/auth/fidelite/`).
- **Support** (`/api/v1/support/…`) : centre d'aide (FAQ modifiable dans l'admin Django), contact du support,
  réclamations suivies par référence, note de l'application. Traitement dans le web admin, page « Support client ».

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
python manage.py test --settings=tambour_backend.settings.base   # tests
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
