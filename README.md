# TamBour

Réservation de transport interurbain en Côte d'Ivoire.

| Dossier | Techno | Rôle |
|---|---|---|
| `backend/` | Python 3.12 · Django 5 · DRF · JWT · PostgreSQL · Celery/Redis | API REST (`/api/v1/`, documentation sur `/api/docs/`) |
| `web/` | Angular 17 | Site voyageurs (recherche, réservation, billets, compte) |
| `web_admin/` | Angular 17 | Back-office d'administration |
| `mobile/` | Flutter | Deux applications : **TamBour** (voyageurs) et **TamBour Pro** (chauffeurs) |
| `branding/` | SVG / PNG | Logo, icônes et couleurs (voir `branding/README.md`) |

## Fonctionnalités récentes

- **Sièges attribués automatiquement** : plus de choix de siège ; à la réservation, l'API attribue les premières
  places libres du car (passagers côte à côte), avec verrouillage pour éviter les doubles attributions.
- **Lignes populaires** : `GET /api/v1/lignes/populaires/` et page « Voir tout » dans l'application.
- **Fidélité & parrainage** : chaque utilisateur a un code (ex. `TB7K2QX9`). À l'inscription avec ce code, le parrain
  et le filleul gagnent des points (`POINTS_PARRAIN`, `POINTS_FILLEUL` dans `.env`). Historique des points
  (`GET /api/v1/auth/fidelite/`).
- **Support** (`/api/v1/support/…`) : centre d'aide (FAQ modifiable dans l'admin Django), contact du support,
  réclamations suivies par référence, note de l'application. Traitement dans le web admin, page « Support client ».

- **TamBour Pro, l'application chauffeur** (réservée aux comptes au rôle `chauffeur`) : trajets du jour et à venir,
  historique, liste des passagers, scan du QR code des billets (`/api/v1/chauffeur/scanner/`), démarrer / terminer un trajet.
  L'admin affecte un chauffeur à un trajet depuis la page « Trajets ».
- **Carte des gares** (mobile et web) : départs de la gare sélectionnée, itinéraire « Y aller » depuis la position
  de l'utilisateur avec distance et durée estimées.
- **Noter un trajet** : une fois le voyage effectué, depuis « Mes billets » (mobile et web).

## Comptes de démonstration

`python manage.py seed_demo` crée compagnies, cars, ~600 trajets (J-2 à J+7), réservations et les comptes :

| Rôle | Email | Mot de passe |
|---|---|---|
| Admin | admin@tambour.ci | Admin2026! |
| Chauffeur | chauffeur@tambour.ci | Chauffeur2026! |
| Voyageur | voyageur@tambour.ci | Voyageur2026! |

Moyens de paiement : Orange Money, Wave, MTN MoMo, Moov Money (via CinetPay) et carte bancaire (site web).
Sans clé CinetPay, `PAIEMENT_SIMULATION` (actif par défaut) confirme les paiements immédiatement.

## Backend

```bash
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env               # puis renseigner les valeurs
python manage.py migrate
python manage.py seed_donnees      # villes, gares, lignes de démo
python manage.py seed_demo         # trajets, réservations, comptes de démo
python manage.py createsuperuser
python manage.py runserver
python manage.py test --settings=tambour_backend.settings.base   # tests
```

PostgreSQL et Redis doivent tourner en local (voir `.env`).

## Site voyageurs

```bash
cd web && npm install && npm start          # http://localhost:4300 (proxy vers l'API)
```

## Web admin

```bash
cd web_admin && npm install && npm start    # http://localhost:4200 (proxy vers l'API)
```

## Mobile : deux applications, un seul code

| Application | Public | Identifiant Android | Lancer |
|---|---|---|---|
| **TamBour** | Voyageurs | `ci.tambour.app` | `flutter run` (saveur `passager` par défaut) |
| **TamBour Pro** | Chauffeurs | `ci.tambour.pro` | `flutter run --flavor chauffeur -t lib/main_chauffeur.dart` |

```bash
cd mobile && flutter pub get
flutter build apk --flavor passager                                   # TamBour
flutter build apk --flavor chauffeur -t lib/main_chauffeur.dart       # TamBour Pro
```

- Chaque application refuse les comptes de l'autre, avec un message qui oriente vers la bonne app.
- TamBour Pro n'a pas d'inscription : les comptes chauffeurs sont créés depuis le back-office.
- Permissions : caméra uniquement dans TamBour Pro (scan des billets), localisation uniquement dans TamBour (itinéraire vers une gare).
- Nom, icône et couleur de lancement propres à chaque application (`android/app/src/chauffeur/`).
- iOS : le dossier `ios/` du dépôt ne contient pas de projet Xcode (`Runner.xcodeproj`). Après `flutter create .`,
  créer deux schemes (`passager`, `chauffeur`) avec des Bundle ID distincts (`ci.tambour.app`, `ci.tambour.pro`).
