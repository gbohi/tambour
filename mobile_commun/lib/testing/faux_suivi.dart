import 'package:latlong2/latlong.dart';
import 'package:tambour_commun/models/suivi.dart';
import 'package:tambour_commun/services/suivi_service.dart';

/// Suivi de démonstration (car à mi-chemin entre Abidjan et Bouaké), pour les tests.
SuiviTrajet suiviDemo({String phase = 'en_route'}) => SuiviTrajet(
  phase: phase, source: phase == 'en_route' ? 'gps' : 'horaire',
  depart: 'Abidjan', arrivee: 'Bouaké', compagnie: 'Trans Ivoire Express', busImmatriculation: 'AB-2341-CI',
  statutLabel: phase == 'a_venir' ? 'Planifié' : 'En cours',
  heureDepart: DateTime.now().subtract(const Duration(hours: 2)),
  arriveeEstimee: DateTime.now().add(const Duration(minutes: 95)),
  minutesRestantes: 95, departDansMinutes: phase == 'a_venir' ? 45 : null,
  distanceRestanteKm: 128, distanceTotaleKm: 350, progression: 58, retardMinutes: 10,
  position: const PositionCar(LatLng(6.62, -4.62), vitesseKmh: 72, ilYaSecondes: 9),
  pointDepart: const PointSuivi("Gare d'Adjamé", LatLng(5.36, -4.0083)),
  pointArrivee: const PointSuivi('Gare de Bouaké', LatLng(7.6899, -5.0317)),
  trace: const [LatLng(5.36, -4.0083), LatLng(5.9, -4.3), LatLng(6.62, -4.62)],
);

class FauxSuiviService extends SuiviService {
  final String phase;
  FauxSuiviService({this.phase = 'en_route'});
  @override
  Future<SuiviTrajet> suivi(String trajetId) async => suiviDemo(phase: phase);
  @override
  Future<int?> envoyerPosition(String trajetId, {required double latitude, required double longitude,
      double? vitesseKmh, double? cap, double? precisionM}) async => 95;
}
