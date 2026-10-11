import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ItineraireException implements Exception {
  final String message;
  const ItineraireException(this.message);
  @override String toString() => message;
}

class Itineraire {
  final List<LatLng> points;
  final double distanceMetres;
  final Duration dureeVoiture;
  final bool estimation;  // true si le calcul routier a échoué (trajet à vol d'oiseau)

  const Itineraire({required this.points, required this.distanceMetres,
    required this.dureeVoiture, this.estimation = false});

  /// Marche à ~4,5 km/h
  Duration get dureeMarche => Duration(seconds: (distanceMetres / 1.25).round());

  String get distanceLabel => distanceMetres >= 1000
    ? '${(distanceMetres / 1000).toStringAsFixed(distanceMetres >= 10000 ? 0 : 1).replaceAll('.', ',')} km'
    : '${distanceMetres.round()} m';

  static String dureeLabel(Duration d) {
    if (d.inMinutes < 1) return '1 min';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final m = d.inMinutes.remainder(60);
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h ${m.toString().padLeft(2, '0')}';
  }
}

/// Position de l'utilisateur et calcul d'itinéraire routier (OSRM, gratuit, sans clé).
class ItineraireService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15)));

  Future<LatLng> positionActuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ItineraireException('Activez la localisation de votre téléphone pour calculer l\'itinéraire.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const ItineraireException('Autorisez TamBour à accéder à votre position pour vous guider jusqu\'à la gare.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<Itineraire> calculer(LatLng depart, LatLng arrivee) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${depart.longitude},${depart.latitude};${arrivee.longitude},${arrivee.latitude}';
      final res = await _dio.get(url, queryParameters: {'overview': 'full', 'geometries': 'geojson'});
      final route = (res.data['routes'] as List).first as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
      return Itineraire(points: coords,
        distanceMetres: (route['distance'] as num).toDouble(),
        dureeVoiture: Duration(seconds: (route['duration'] as num).round()));
    } catch (_) {
      // Repli : ligne droite et durée estimée (~35 km/h en ville, détours inclus)
      final metres = const Distance().as(LengthUnit.Meter, depart, arrivee) * 1.3;
      return Itineraire(points: [depart, arrivee], distanceMetres: metres,
        dureeVoiture: Duration(seconds: (metres / 9.7).round()), estimation: true);
    }
  }
}
