// Vérifie qu'aucun écran de TamBour Pro ne déborde, à plusieurs tailles de téléphone.
// Lancer : flutter test test/overflow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tambour_chauffeur/models/chauffeur.dart';
import 'package:tambour_chauffeur/screens/chauffeur_accueil_screen.dart';
import 'package:tambour_chauffeur/screens/chauffeur_trajet_screen.dart';
import 'package:tambour_chauffeur/services/chauffeur_service.dart';
import 'package:tambour_chauffeur/screens/connexion_chauffeur_screen.dart';
import 'package:tambour_commun/testing/debordements.dart';

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

void main() {
  testerDebordements({
    'Connexion': (() => const ConnexionChauffeurScreen(), null),
    'Mes trajets': (() => ChauffeurAccueilScreen(service: FauxChauffeurService()), null),
    'Mes trajets › historique': (() => ChauffeurAccueilScreen(service: FauxChauffeurService()), (WidgetTester t) async {
      await t.tap(find.text('Historique'));
    }),
    'Trajet': (() => ChauffeurTrajetScreen(trajetId: 't1', service: FauxChauffeurService()), null),
  });
}
