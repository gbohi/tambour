// Rend chaque écran à plusieurs tailles de téléphone et échoue si un widget déborde
// (« A RenderFlex overflowed by N pixels »). Lancer : flutter test test/overflow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tambour_commun/testing/debordements.dart';
import 'package:tambour_commun/testing/faux_suivi.dart';
import 'package:tambour_passager/screens/suivi/suivi_trajet_screen.dart';

import 'package:tambour_passager/models/banniere.dart';
import 'package:tambour_passager/models/fidelite.dart';
import 'package:tambour_passager/providers/banniere_provider.dart';
import 'package:tambour_passager/models/paiement.dart';
import 'package:tambour_passager/models/support.dart';
import 'package:tambour_passager/models/trajet.dart';
import 'package:tambour_passager/models/ville.dart';
import 'package:tambour_passager/providers/fidelite_provider.dart';
import 'package:tambour_passager/providers/passager_provider.dart';
import 'package:tambour_passager/providers/recherche_provider.dart';
import 'package:tambour_passager/providers/support_provider.dart';
import 'package:tambour_passager/screens/auth/auth_screen.dart';
import 'package:tambour_passager/screens/billet/billet_screen.dart';
import 'package:tambour_passager/screens/billets/mes_billets_screen.dart';
import 'package:tambour_passager/screens/compte/compte_screen.dart';
import 'package:tambour_passager/screens/fidelite/fidelite_screen.dart';
import 'package:tambour_passager/models/gare.dart';
import 'package:tambour_passager/screens/gares/departs_gare_screen.dart';
import 'package:tambour_passager/screens/gares/gares_screen.dart';
import 'package:tambour_passager/screens/home/home_screen.dart';
import 'package:tambour_passager/screens/lignes/lignes_populaires_screen.dart';
import 'package:tambour_passager/screens/notifications/notifications_screen.dart';
import 'package:tambour_passager/screens/paiement/paiement_screen.dart';
import 'package:tambour_passager/screens/passagers/passagers_screen.dart';
import 'package:tambour_passager/screens/profil/profil_edit_screen.dart';
import 'package:tambour_passager/screens/resultats/resultats_screen.dart';
import 'package:tambour_passager/screens/support/centre_aide_screen.dart';
import 'package:tambour_passager/screens/support/contact_support_screen.dart';
import 'package:tambour_passager/screens/support/noter_app_screen.dart';
import 'package:tambour_passager/screens/support/reclamations_screen.dart';

final params = RechercheParams(
  villeDepart: Ville.mockVilles[2], villeArrivee: Ville.mockVilles[4],  // noms longs
  date: DateTime.now().add(const Duration(days: 1)), nbPassagers: 2);
final trajet = Trajet.mockTrajets('yam', 'san').first;

final fideliteDemo = FideliteInfo(points: 12450, nbVoyages: 37, codeParrainage: 'TB7K2QX9', nbFilleuls: 12,
  pointsParrainage: 6000, pointsParrain: 500, pointsFilleul: 200,
  messagePartage: 'Rejoins-moi sur TamBour', historique: [
    MouvementPoints(points: 500, motif: 'parrainage', motifLabel: 'Parrainage',
      description: 'Kouadio Jean-Baptiste s\'est inscrit avec votre code', date: DateTime(2026, 10, 2)),
    MouvementPoints(points: 35, motif: 'voyage', motifLabel: 'Voyage',
      description: 'Voyage Abidjan -> Yamoussoukro (TB202610123456)', date: DateTime(2026, 9, 28)),
  ]);

final reclamationsDemo = [
  Reclamation(id: '1', reference: 'REC20261012345', categorie: 'paiement', categorieLabel: 'Problème de paiement',
    sujet: 'Débité deux fois pour le même billet Abidjan – Bouaké', description: 'x',
    referenceReservation: 'TB202610123456', reponse: 'Nous avons remboursé le second paiement.',
    statut: StatutReclamation.resolue, statutLabel: 'Résolue', date: DateTime(2026, 10, 3)),
];



// Sans image (pas de réseau en test) : seul le texte superposé est rendu
const bannieresDemo = [
  Banniere(id: 1, titre: 'Abidjan → Yamoussoukro, départs toute la journée', sousTitre: 'Dès 2 600 F, réservez en deux minutes depuis votre téléphone',
    texteBouton: 'Voir les départs', action: 'recherche', departId: 'abj', departNom: 'Abidjan', arriveeId: 'yam', arriveeNom: 'Yamoussoukro'),
  Banniere(id: 2, titre: 'Parrainez vos amis', sousTitre: '500 points pour vous', texteBouton: 'Inviter', action: 'page', page: 'fidelite'),
];

final ecrans = <String, Widget Function()>{
  'Accueil': () => const HomeScreen(),
  'Connexion / inscription': () => const AuthScreen(),
  'Résultats': () => ResultatsScreen(params: params),
  'Passagers': () => PassagersScreen(trajet: trajet, params: params),
  'Paiement': () => PaiementScreen(trajet: trajet, params: params),
  'Billet': () => BilletScreen(trajet: trajet, params: params, result: PaiementResult(
    referenceTransaction: 'TB202610111234', statut: StatutPaiement.succes, timestamp: DateTime.now(),
    montantFcfa: 7000, methode: MethodePaiement.orangeMoney)),
  'Mes billets': () => const MesBilletsScreen(),
  'Mon compte': () => const CompteScreen(),
  'Profil': () => const ProfilEditScreen(),
  'Notifications': () => const NotificationsScreen(),
  'Gares': () => const GaresScreen(),
  'Départs d\'une gare': () => DepartsGareScreen(gare: Gare.mockGares().first),
  'Lignes populaires': () => const LignesPopulairesScreen(),
  'Fidélité': () => const FideliteScreen(),
  "Centre d'aide": () => const CentreAideScreen(),
  'Contact support': () => const ContactSupportScreen(),
  'Noter l\'app': () => const NoterAppScreen(),
  'Suivi du car (en route)': () => SuiviTrajetScreen(trajetId: 't1', service: FauxSuiviService()),
  'Suivi du car (avant le départ)': () => SuiviTrajetScreen(trajetId: 't1', service: FauxSuiviService(phase: 'a_venir')),
  'Réclamations': () => const ReclamationsScreen(),
  'Nouvelle réclamation': () => const NouvelleReclamationScreen(),
};

/// Écrans avec une action (ouverture d'une fenêtre, d'un onglet…) avant la vérification.
final interactions = <String, CasEcran>{
  'Accueil › calendrier': (() => const HomeScreen(), (t) async {
    await t.tap(find.text("Aujourd'hui"));
  }),
  'Accueil › choix de la ville': (() => const HomeScreen(), (t) async {
    await t.tap(find.text('Choisir une ville').first);
  }),
  'Mes billets › détail du billet': (() => const MesBilletsScreen(), (t) async {
    await t.tap(find.text('Voir le billet').first);
  }),
  'Gares › fiche de la gare': (() => const GaresScreen(), (t) async {
    await t.tap(find.text('Liste'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    await t.tap(find.text(Gare.mockGares().first.nom).first);
  }),
  'Mes billets › noter un trajet': (() => const MesBilletsScreen(), (t) async {
    await t.tap(find.textContaining('Passés'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    await t.tap(find.text('Noter ce trajet'));
  }),
  'Mes billets › passés': (() => const MesBilletsScreen(), (t) async {
    await t.tap(find.textContaining('Passés'));
  }),
};

void main() {
  testerDebordements({
    for (final e in ecrans.entries) e.key: (e.value, null),
    ...interactions,
  }, overrides: [
    passagerProvider.overrideWith((ref) => PassagerNotifier()..initialiser(2)..attribuerSieges(['1A', '1B'])),
    bannieresProvider.overrideWith((ref) async => bannieresDemo),
    fideliteProvider.overrideWith((ref) async => fideliteDemo),
    reclamationsProvider.overrideWith((ref) async => reclamationsDemo),
    faqProvider.overrideWith((ref) async => CategorieFAQ.parDefaut),
  ]);
}
