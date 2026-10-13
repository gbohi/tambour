import 'package:latlong2/latlong.dart';

/// Extrémité d'une ligne (gare ou ville) pour la carte de suivi.
class PointSuivi {
  final String nom;
  final LatLng position;
  const PointSuivi(this.nom, this.position);

  static PointSuivi? fromJson(Map<String, dynamic>? j) => j == null ? null
    : PointSuivi(j['nom'] as String, LatLng((j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble()));
}

/// Dernière position connue du car.
class PositionCar {
  final LatLng position;
  final double? vitesseKmh;
  final int ilYaSecondes;
  const PositionCar(this.position, {this.vitesseKmh, this.ilYaSecondes = 0});

  factory PositionCar.fromJson(Map<String, dynamic> j) => PositionCar(
    LatLng((j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble()),
    vitesseKmh: (j['vitesse_kmh'] as num?)?.toDouble(),
    ilYaSecondes: (j['il_y_a_secondes'] as num?)?.toInt() ?? 0);
}

/// État du trajet renvoyé par GET /trajets/<id>/suivi/.
class SuiviTrajet {
  /// a_venir, en_route, arrivee_imminente, arrive, annule
  final String phase;
  /// gps (position réelle), horaire (estimation sur l'horaire), chauffeur (arrivée confirmée)
  final String source;
  final String depart, arrivee, compagnie, busImmatriculation, statutLabel;
  final DateTime heureDepart;
  final DateTime? arriveeEstimee;
  final int? minutesRestantes, departDansMinutes;
  final double? distanceRestanteKm, distanceTotaleKm;
  final int progression;
  final int retardMinutes;
  final PositionCar? position;
  final PointSuivi? pointDepart, pointArrivee;
  final List<LatLng> trace;
  final int rafraichirDansSecondes;

  const SuiviTrajet({
    required this.phase, required this.source, required this.depart, required this.arrivee,
    required this.compagnie, required this.busImmatriculation, required this.statutLabel,
    required this.heureDepart, this.arriveeEstimee, this.minutesRestantes, this.departDansMinutes,
    this.distanceRestanteKm, this.distanceTotaleKm, this.progression = 0, this.retardMinutes = 0,
    this.position, this.pointDepart, this.pointArrivee, this.trace = const [], this.rafraichirDansSecondes = 15,
  });

  factory SuiviTrajet.fromJson(Map<String, dynamic> j) {
    final t = j['trajet'] as Map<String, dynamic>;
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();
    return SuiviTrajet(
      phase: j['phase'] as String, source: j['source'] as String,
      depart: t['depart'] as String, arrivee: t['arrivee'] as String,
      compagnie: t['compagnie'] as String? ?? '', busImmatriculation: t['bus_immatriculation'] as String? ?? '',
      statutLabel: t['statut_label'] as String? ?? '',
      heureDepart: date(t['heure_depart'])!,
      arriveeEstimee: date(j['arrivee_estimee']),
      minutesRestantes: (j['minutes_restantes'] as num?)?.toInt(),
      departDansMinutes: (j['depart_dans_minutes'] as num?)?.toInt(),
      distanceRestanteKm: (j['distance_restante_km'] as num?)?.toDouble(),
      distanceTotaleKm: (j['distance_totale_km'] as num?)?.toDouble(),
      progression: (j['progression'] as num?)?.toInt() ?? 0,
      retardMinutes: (t['retard_minutes'] as num?)?.toInt() ?? 0,
      position: j['position'] == null ? null : PositionCar.fromJson(j['position'] as Map<String, dynamic>),
      pointDepart: PointSuivi.fromJson(j['point_depart'] as Map<String, dynamic>?),
      pointArrivee: PointSuivi.fromJson(j['point_arrivee'] as Map<String, dynamic>?),
      trace: [for (final p in (j['trace'] as List? ?? [])) LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())],
      rafraichirDansSecondes: (j['rafraichir_dans_secondes'] as num?)?.toInt() ?? 15,
    );
  }

  bool get enRoute => phase == 'en_route' || phase == 'arrivee_imminente';
  bool get estArrive => phase == 'arrive';

  /// « 1 h 25 », « 45 min », « 2 j 3 h »
  static String duree(int minutes) {
    if (minutes < 1) return "moins d'1 min";
    if (minutes < 60) return '$minutes min';
    final j = minutes ~/ 1440, h = (minutes % 1440) ~/ 60, m = minutes % 60;
    if (j > 0) return h > 0 ? '$j j $h h' : '$j j';
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
  }

  /// « il y a 12 s », « il y a 3 min »
  static String ilYa(int secondes) =>
    secondes < 60 ? 'il y a $secondes s' : 'il y a ${secondes ~/ 60} min';
}
