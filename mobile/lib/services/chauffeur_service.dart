import 'package:dio/dio.dart';
import '../models/chauffeur.dart';
import 'api_client.dart';

class ChauffeurException implements Exception {
  final String message;
  const ChauffeurException(this.message);
  @override String toString() => message;
}

class ChauffeurService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<TrajetChauffeur>> mesTrajets({bool historique = false}) async {
    try {
      final res = await _dio.get('/chauffeur/trajets/',
        queryParameters: {if (historique) 'periode': 'historique'});
      return (res.data['data']['results'] as List)
        .map((t) => TrajetChauffeur.fromJson(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ChauffeurException(_message(e));
    }
  }

  Future<TrajetChauffeur> trajet(String id) async {
    try {
      final res = await _dio.get('/chauffeur/trajets/$id/');
      return TrajetChauffeur.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChauffeurException(_message(e));
    }
  }

  Future<String> demarrer(String id) => _action('/chauffeur/trajets/$id/demarrer/');
  Future<String> terminer(String id) => _action('/chauffeur/trajets/$id/terminer/');

  Future<ResultatScan> scanner(String trajetId, {String? qrData, String? referenceBillet}) async {
    try {
      final res = await _dio.post('/chauffeur/scanner/', data: {
        'trajet_id': trajetId,
        if (qrData != null) 'qr_data': qrData,
        if (referenceBillet != null) 'reference_billet': referenceBillet,
      });
      return ResultatScan(ok: true, message: res.data['message'] as String? ?? 'Billet validé',
        passager: PassagerChauffeur.fromJson(res.data['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map && data['errors'] is Map && (data['errors'] as Map)['code'] is List
        ? ((data['errors'] as Map)['code'] as List).first as String : null;
      return ResultatScan(ok: false, message: _message(e), code: code);
    }
  }

  Future<String> _action(String chemin) async {
    try {
      final res = await _dio.post(chemin);
      return res.data['message'] as String? ?? 'OK';
    } on DioException catch (e) {
      throw ChauffeurException(_message(e));
    }
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (e.response?.statusCode == 401) return 'Session expirée. Reconnectez-vous.';
    if (e.response?.statusCode == 403) return 'Espace réservé aux chauffeurs.';
    return 'Pas de connexion. Vérifiez votre réseau.';
  }
}
