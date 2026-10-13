import 'package:dio/dio.dart';
import 'package:tambour_commun/models/suivi.dart';
import 'package:tambour_commun/services/api_client.dart';

class SuiviException implements Exception {
  final String message;
  const SuiviException(this.message);
  @override String toString() => message;
}

/// Suivi en temps réel : lecture de l'état du trajet et, pour TamBour Pro, envoi de la position du car.
class SuiviService {
  final Dio _dio = ApiClient.instance.dio;

  Future<SuiviTrajet> suivi(String trajetId) async {
    try {
      final r = await _dio.get('/trajets/$trajetId/suivi/');
      return SuiviTrajet.fromJson(r.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SuiviException(_message(e, 'Suivi indisponible pour le moment.'));
    }
  }

  /// Renvoie le temps restant recalculé par le serveur (minutes), ou null.
  Future<int?> envoyerPosition(String trajetId, {required double latitude, required double longitude,
      double? vitesseKmh, double? cap, double? precisionM}) async {
    try {
      final r = await _dio.post('/chauffeur/trajets/$trajetId/position/', data: {
        'latitude': double.parse(latitude.toStringAsFixed(6)), 'longitude': double.parse(longitude.toStringAsFixed(6)),
        if (vitesseKmh != null) 'vitesse_kmh': vitesseKmh,
        if (cap != null && cap >= 0) 'cap': cap,
        if (precisionM != null) 'precision_m': precisionM,
      });
      return (r.data['data']?['minutes_restantes'] as num?)?.toInt();
    } on DioException catch (e) {
      throw SuiviException(_message(e, "La position n'a pas pu être envoyée."));
    }
  }

  String _message(DioException e, String defaut) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Pas de connexion internet.';
    }
    return defaut;
  }
}
