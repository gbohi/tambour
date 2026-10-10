import 'package:dio/dio.dart';
import '../models/support.dart';
import 'api_client.dart';

class SupportException implements Exception {
  final String message;
  const SupportException(this.message);
  @override String toString() => message;
}

class SupportService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<CategorieFAQ>> getFaq() async {
    try {
      final response = await _dio.get('/support/faq/');
      final cats = (response.data['data']['categories'] as List)
        .map((c) => CategorieFAQ.fromJson(c as Map<String, dynamic>)).toList();
      return cats.isEmpty ? CategorieFAQ.parDefaut : cats;
    } catch (_) {
      return CategorieFAQ.parDefaut;
    }
  }

  Future<InfosContact> getInfosContact() async {
    try {
      final response = await _dio.get('/support/contact/');
      return InfosContact.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return InfosContact.parDefaut;
    }
  }

  Future<String> envoyerMessage({required String sujet, required String message,
    String? nom, String? email, String? telephone}) =>
    _post('/support/contact/', {
      'sujet': sujet, 'message': message,
      if (nom != null && nom.isNotEmpty) 'nom': nom,
      if (email != null && email.isNotEmpty) 'email': email,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
    });

  Future<List<Reclamation>> getReclamations() async {
    try {
      final response = await _dio.get('/support/reclamations/');
      return (response.data['data']['results'] as List)
        .map((r) => Reclamation.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SupportException(_message(e));
    }
  }

  Future<String> creerReclamation({required String categorie, required String sujet,
    required String description, String referenceReservation = ''}) =>
    _post('/support/reclamations/', {
      'categorie': categorie, 'sujet': sujet, 'description': description,
      'reference_reservation': referenceReservation,
    });

  Future<int?> getMaNote() async {
    try {
      final response = await _dio.get('/support/avis-app/');
      final data = response.data['data'];
      return data is Map ? data['note'] as int? : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> noterApplication({required int note, String commentaire = '',
    String plateforme = '', String version = ''}) =>
    _post('/support/avis-app/', {
      'note': note, 'commentaire': commentaire, 'plateforme': plateforme, 'version_app': version,
    });

  Future<String> _post(String chemin, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(chemin, data: data);
      return response.data['message'] as String? ?? 'Envoyé';
    } on DioException catch (e) {
      throw SupportException(_message(e));
    }
  }

  String _message(DioException e) {
    if (e.response?.statusCode == 401) return 'Connectez-vous pour continuer.';
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final v in errors.values) {
          if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
        }
      }
      if (data['message'] is String) return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion. Vérifiez votre réseau.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}
