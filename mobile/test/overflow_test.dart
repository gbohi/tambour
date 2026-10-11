// Rend chaque écran à plusieurs tailles de téléphone et échoue si un widget déborde
// (« A RenderFlex overflowed by N pixels »). Lancer : flutter test test/overflow_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:tambour/models/fidelite.dart';
import 'package:tambour/models/paiement.dart';
import 'package:tambour/models/support.dart';
import 'package:tambour/models/trajet.dart';
import 'package:tambour/models/ville.dart';
import 'package:tambour/providers/fidelite_provider.dart';
import 'package:tambour/providers/passager_provider.dart';
import 'package:tambour/providers/recherche_provider.dart';
import 'package:tambour/providers/support_provider.dart';
import 'package:tambour/screens/auth/auth_screen.dart';
import 'package:tambour/screens/billet/billet_screen.dart';
import 'package:tambour/screens/billets/mes_billets_screen.dart';
import 'package:tambour/screens/compte/compte_screen.dart';
import 'package:tambour/screens/fidelite/fidelite_screen.dart';
import 'package:tambour/models/chauffeur.dart';
import 'package:tambour/models/gare.dart';
import 'package:tambour/screens/chauffeur/chauffeur_accueil_screen.dart';
import 'package:tambour/screens/chauffeur/chauffeur_trajet_screen.dart';
import 'package:tambour/services/chauffeur_service.dart';
import 'package:tambour/screens/gares/departs_gare_screen.dart';
import 'package:tambour/screens/gares/gares_screen.dart';
import 'package:tambour/screens/home/home_screen.dart';
import 'package:tambour/screens/lignes/lignes_populaires_screen.dart';
import 'package:tambour/screens/notifications/notifications_screen.dart';
import 'package:tambour/screens/paiement/paiement_screen.dart';
import 'package:tambour/screens/passagers/passagers_screen.dart';
import 'package:tambour/screens/profil/profil_edit_screen.dart';
import 'package:tambour/screens/resultats/resultats_screen.dart';
import 'package:tambour/screens/support/centre_aide_screen.dart';
import 'package:tambour/screens/support/contact_support_screen.dart';
import 'package:tambour/screens/support/noter_app_screen.dart';
import 'package:tambour/screens/support/reclamations_screen.dart';
import 'package:tambour/screens/chauffeur/connexion_chauffeur_screen.dart';

class Config {
  final Size taille;
  final double texte;    // facteur de taille du texte (réglage d'accessibilité du téléphone)
  final double clavier;  // hauteur du clavier ouvert
  const Config(this.taille, {this.texte = 1, this.clavier = 0});
}

const tailles = <String, Config>{
  'petit 320x568': Config(Size(320, 568)),
  'moyen 360x640': Config(Size(360, 640)),
  'grand 393x852': Config(Size(393, 852)),
  'texte agrandi 1.3 360x640': Config(Size(360, 640), texte: 1.3),
  'clavier ouvert 360x640': Config(Size(360, 640), clavier: 290),
};

Future<void> chargerPolices() async {
  final dossier = '${Platform.environment['FLUTTER_ROOT'] ?? '/home/user/sdk/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  // Roboto a des métriques proches d'Outfit (police de l'application)
  for (final famille in ['Outfit', 'Roboto']) {
    final loader = FontLoader(famille);
    for (final f in ['Regular', 'Medium', 'Bold', 'Black', 'Light']) {
      loader.addFont(Future.value(ByteData.sublistView(File('$dossier/Roboto-$f.ttf').readAsBytesSync())));
    }
    await loader.load();
  }
  final icones = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$dossier/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icones.load();
}

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

TrajetChauffeur trajetChauffeur(String statut) => TrajetChauffeur(
  id: 't1', depart: 'Yamoussoukro', arrivee: 'San-Pédro', gareDepart: 'Gare Routière de Yamoussoukro Centre',
  heureDepart: DateTime.now().add(const Duration(hours: 2)),
  heureArriveeEstimee: DateTime.now().add(const Duration(hours: 6)),
  statut: statut, statutLabel: statut == 'termine' ? 'Terminé' : statut == 'en_cours' ? 'En cours' : 'Planifié',
  compagnie: 'Trans Ivoire', busImmatriculation: 'AB-2341-CI', placesTotal: 54, nbPassagers: 38, nbEmbarques: 12,
  passagers: [
    for (var i = 0; i < 10; i++)
      PassagerChauffeur(id: '$i', nomComplet: 'Kouadio Jean-Baptiste N\'Guessan $i', telephone: '0707070707',
        siege: '${i + 1}A', reservation: 'TB202610123456', referenceBillet: 'TB202610123456-P${i + 1}',
        embarque: i.isEven, embarqueLe: i.isEven ? DateTime.now() : null),
  ]);

class FauxChauffeurService extends ChauffeurService {
  @override
  Future<List<TrajetChauffeur>> mesTrajets({bool historique = false}) async =>
    historique ? [trajetChauffeur('termine'), trajetChauffeur('annule')] : [trajetChauffeur('planifie'), trajetChauffeur('en_cours')];
  @override
  Future<TrajetChauffeur> trajet(String id) async => trajetChauffeur('en_cours');
}

final ecrans = <String, Widget Function()>{
  'Chauffeur › mes trajets': () => ChauffeurAccueilScreen(service: FauxChauffeurService()),
  'TamBour Pro › connexion': () => const ConnexionChauffeurScreen(),
  'Chauffeur › trajet': () => ChauffeurTrajetScreen(trajetId: 't1', service: FauxChauffeurService()),
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
  'Réclamations': () => const ReclamationsScreen(),
  'Nouvelle réclamation': () => const NouvelleReclamationScreen(),
};

/// Écrans avec une action (ouverture d'une fenêtre, d'un onglet…) avant la vérification.
final interactions = <String, (Widget Function(), Future<void> Function(WidgetTester))>{
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
  'Chauffeur › historique': (() => ChauffeurAccueilScreen(service: FauxChauffeurService()), (t) async {
    await t.tap(find.text('Historique'));
  }),
  'Mes billets › passés': (() => const MesBilletsScreen(), (t) async {
    await t.tap(find.textContaining('Passés'));
  }),
};

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
    await chargerPolices();
  });

  final cas = <String, (Widget Function(), Future<void> Function(WidgetTester)?)>{
    for (final e in ecrans.entries) e.key: (e.value, null),
    ...interactions,
  };
  for (final ecran in cas.entries) {
    for (final taille in tailles.entries) {
      testWidgets('${ecran.key} — ${taille.key}', (tester) async {
        final debordements = <String>[];
        final ancien = FlutterError.onError;
        addTearDown(() => FlutterError.onError = ancien);
        FlutterError.onError = (details) {
          final texte = details.toString();
          if (texte.contains('overflowed')) {
            final source = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(texte)?.group(0) ?? '?';
            debordements.add('${details.exceptionAsString().split('\n').first} ← $source');
          } else if (!texte.contains('tile.openstreetmap.org')) {
            ancien?.call(details);  // autres erreurs : signalées normalement
          }
        };
        final c = taille.value;
        tester.view.physicalSize = c.taille * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.viewInsets = FakeViewPadding(bottom: c.clavier * 3);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ProviderScope(
          overrides: [
            passagerProvider.overrideWith((ref) => PassagerNotifier()..initialiser(['1A', '1B'])),
            fideliteProvider.overrideWith((ref) async => fideliteDemo),
            reclamationsProvider.overrideWith((ref) async => reclamationsDemo),
            faqProvider.overrideWith((ref) async => CategorieFAQ.parDefaut),
          ],
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Outfit', useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7C4E))),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.texte)),
              child: child!),
            home: ecran.value.$1()),
        ));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        final action = ecran.value.$2;
        if (action != null) {
          await action(tester);
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
        FlutterError.onError = ancien;
        expect(debordements, isEmpty, reason: debordements.toSet().join('\n'));
      });
    }
  }
}
