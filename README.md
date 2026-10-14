# TamBour

Réservation de transport interurbain en Côte d'Ivoire.

| Dossier | Techno | Rôle |
|---|---|---|
| `backend/` | Python 3.12 · Django 5 · DRF · JWT · PostgreSQL · Celery/Redis | API REST (`/api/v1/`, documentation sur `/api/docs/`) |
| `web/` | Angular 17 | Site voyageurs (recherche, réservation, billets, compte) |
| `web_admin/` | Angular 17 | Back-office d'administration |
| `mobile_passager/` | Flutter | Application **TamBour** (voyageurs) |
| `mobile_chauffeur/` | Flutter | Application **TamBour Pro** (chauffeurs) |
| `mobile_commun/` | Dart (package) | Code partagé par les deux applications |
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
- **Suivi du car en temps réel** :
  - TamBour Pro partage automatiquement la position GPS du car pendant le trajet (toutes les 15 s) et affiche
    au chauffeur le temps restant jusqu'à destination ;
  - le voyageur suit son car sur une carte (app TamBour et site web, bouton « Suivre le car ») :
    « Arrivée dans 1 h 25 », heure d'arrivée estimée, progression, distance restante ;
  - API : `POST /api/v1/chauffeur/trajets/<id>/position/` et `GET /api/v1/trajets/<id>/suivi/` (voyageurs ayant
    une réservation confirmée, chauffeur, compagnie, admin) ; sans GPS récent, estimation selon l'horaire ;
  - démonstration sans téléphone : `python manage.py simuler_suivi` fait rouler un car réservé.

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

## Mobile : deux applications et un package commun

| Dossier | Application | Identifiant Android | Contenu |
|---|---|---|---|
| `mobile_passager/` | **TamBour** | `ci.tambour.app` | Recherche, réservation, paiement, billets, fidélité, gares, suivi du car |
| `mobile_chauffeur/` | **TamBour Pro** | `ci.tambour.pro` | Trajets, passagers, scan des billets, partage de la position, fin de trajet |
| `mobile_commun/` | package `tambour_commun` | — | Thème, police, logo, connexion, client API, widgets, carte de suivi, banc de test |

Prérequis :
- **Flutter stable récent** (3.44 minimum, testé avec 3.47) : `flutter upgrade` ;
- **Java 17 ou plus** (JDK 17 ou 21 ; celui fourni avec Android Studio convient : `flutter config --jdk-dir <chemin>`
  si plusieurs Java sont installés) ;
- configuration Android générée par Flutter 3.47 : Gradle 9.3, Android Gradle Plugin 9.1, Kotlin 2.4, fichiers `.gradle.kts`.

```bash
cd mobile_passager  && flutter pub get && flutter run    # TamBour
cd mobile_chauffeur && flutter pub get && flutter run    # TamBour Pro
flutter test                                              # dans chaque dossier
```

- Chaque application a son propre projet Android/iOS, son nom, son icône et ses autorisations
  (caméra et localisation pour TamBour Pro, localisation pour TamBour).
- Chaque application refuse les comptes de l'autre, avec un message qui oriente vers la bonne app.
- TamBour Pro n'a pas d'inscription : les comptes chauffeurs sont créés depuis le back-office.
- Partage de position en arrière-plan (écran éteint, autre app ouverte) :
  - Android : service de premier plan avec notification permanente « Trajet en cours » tant que le trajet dure ;
  - iOS : mode `location` en arrière-plan (barre d'état bleue) ;
  - le partage s'arrête si le chauffeur ferme l'app depuis les apps récentes ; sur certains téléphones (Tecno,
    Infinix, itel…), autoriser TamBour Pro dans les réglages de la batterie (bouton « Réglages » dans l'app).
- iOS : le dossier `ios/` ne contient pas de projet Xcode (`Runner.xcodeproj`) ; le générer avec `flutter create .`
  dans chaque application, puis renseigner les Bundle ID (`ci.tambour.app`, `ci.tambour.pro`).
