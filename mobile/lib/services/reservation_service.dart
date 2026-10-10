import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/passager.dart';

class ReservationService {
  final Dio _dio;

  ReservationService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15)));

  Future<Map<String, dynamic>> creerReservation({
    required String trajetId,
    required List<Passager> passagers,
    required String accessToken,
  }) async {
    final response = await _dio.post(
      '/reservations/',
      data: {
        'trajet_id': trajetId,
        'passagers': passagers.map((p) => p.toJson()).toList(),
        'email_payeur': passagers.isNotEmpty ? passagers.first.email : '',
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMesReservations({
    required String accessToken,
    String? section,
  }) async {
    final response = await _dio.get(
      '/reservations/',
      queryParameters: section != null ? {'section': section} : null,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getReservation({
    required String id,
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/reservations/$id/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> annuler({
    required String id,
    required String accessToken,
    String? motif,
  }) async {
    final response = await _dio.post(
      '/reservations/$id/annuler/',
      data: {'motif': motif ?? ''},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBillet({
    required String reservationId,
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/reservations/$reservationId/billet/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }
}
