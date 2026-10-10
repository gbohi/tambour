import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/trajet.dart';
import '../models/siege.dart';
import '../models/ville.dart';

class TrajetService {
  final Dio _dio;

  TrajetService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Ville>> getVilles() async {
    final response = await _dio.get('/villes/');
    return (response.data['results'] as List)
      .map((v) => Ville.fromJson(v as Map<String, dynamic>))
      .toList();
  }

  Future<List<Trajet>> rechercherTrajets({
    required String villeDepart,
    required String villeArrivee,
    required DateTime date,
    required int passagers,
    String? classe,
    int? prixMax,
    String tri = 'horaire',
  }) async {
    final response = await _dio.post('/trajets/recherche/', data: {
      'depart': villeDepart,
      'arrivee': villeArrivee,
      'date': '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
      'passagers': passagers,
      if (classe != null && classe.isNotEmpty) 'classe': classe,
      if (prixMax != null) 'prix_max': prixMax,
      'tri': tri,
    });
    return (response.data['data']['results'] as List)
      .map((t) => Trajet.fromJson(t as Map<String, dynamic>))
      .toList();
  }

  Future<List<Siege>> getSiegesTrajet(String trajetId) async {
    final response = await _dio.get('/trajets/$trajetId/sieges/');
    return (response.data['data']['sieges'] as List)
      .map((s) => Siege.fromJson(s as Map<String, dynamic>))
      .toList();
  }
}
