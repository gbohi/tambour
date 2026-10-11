# Identité TamBour

Logo vectorisé à partir du logo fourni : tambour (djembé) dont le pied est une route.
Devise : **Voyagez au bon rythme**.

| Fichier | Usage |
|---|---|
| `tambour-logo.svg` | Logo complet (symbole, nom, devise) sur fond clair. Grand format uniquement : la devise devient illisible sous ~150 px de haut. |
| `tambour-logo-blanc.svg` | Logo complet pour fonds verts ou sombres. |
| `tambour-symbole.svg` | Symbole seul (favicon, en-têtes, petits formats). |
| `tambour-symbole-clair.svg` | Symbole pour fonds verts ou sombres. |
| `icone-passager.svg` | Icône de l'application **TamBour** (fond crème). |
| `icone-chauffeur.svg` | Icône de l'application **TamBour Pro** (fond vert, pastille PRO). |
| `png/` | Exports PNG (icônes 512 px pour les stores, logos). |
| `apercus/` | Captures d'écrans des applications mobiles. |
| `paiements/` | Logos des moyens de paiement (Orange Money, Wave, MTN MoMo, Moov Money), 256 px. Marques de leurs propriétaires respectifs. |

Aux petites tailles, composer **symbole + « TamBour » + devise en texte** (police Outfit) plutôt que d'utiliser le logo complet.

## Couleurs

| | Hex | Usage |
|---|---|---|
| Vert TamBour | `#0F4A3B` | Couleur principale (boutons, liens, en-têtes) |
| Vert foncé | `#0B3A2E` | Survol, états appuyés |
| Vert nuit | `#072A21` | Dégradés, fonds sombres |
| Vert vif | `#2E8466` | Fin de dégradés, accents |
| Vert pâle | `#E7F0EC` | Fonds de pastilles et de sélection |
| Or | `#F2A93B` | Appels à l'action secondaires, prix, points |
| Crème | `#FAF7EF` | Fond de l'icône TamBour, écran de lancement |

Ces valeurs sont appliquées au site (`web/src/styles.scss`), à l'admin (`web_admin/src/styles.scss`),
à l'app mobile (`mobile/lib/core/theme.dart`), aux billets PDF et aux emails.

Police : **Outfit** (SIL Open Font License), embarquée dans l'application mobile (`mobile/assets/fonts`).
