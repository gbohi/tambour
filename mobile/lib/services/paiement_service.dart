import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/paiement.dart';

class PaiementService {
  final Dio _dio;

  PaiementService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30)));

  String _methodeToApi(MethodePaiement methode) => switch (methode) {
    MethodePaiement.mtnMomo => 'mtn_momo',
    MethodePaiement.orangeMoney => 'orange_money',
    MethodePaiement.wave => 'wave',
    MethodePaiement.carte => 'carte',
  };

  Future<Map<String, dynamic>> initierPaiement({
    required String reservationId,
    required MethodePaiement methode,
    required String telephone,
    required String accessToken,
  }) async {
    final response = await _dio.post(
      '/paiements/initier/',
      data: {
        'reservation_id': reservationId,
        'methode': _methodeToApi(methode),
        'telephone': telephone,
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifierStatut({
    required String reference,
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/paiements/$reference/statut/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMesPaiements({
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/paiements/mes-paiements/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as List<dynamic>;
  }
}
