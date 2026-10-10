import 'package:dio/dio.dart';
import '../core/constants.dart';

class NotificationService {
  final Dio _dio;

  NotificationService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15)));

  Future<Map<String, dynamic>> getNotifications({
    required String accessToken,
    bool nonLuesSeulement = false,
    String? type,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/notifications/',
      queryParameters: {
        if (nonLuesSeulement) 'non_lues': '1',
        if (type != null) 'type': type,
        'limit': limit,
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> marquerLues({
    required String accessToken,
    List<String>? ids,
  }) async {
    await _dio.post(
      '/notifications/lire/',
      data: ids != null ? {'notification_ids': ids} : {},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
  }

  Future<void> enregistrerTokenPush({
    required String token,
    required String plateforme,
    required String accessToken,
  }) async {
    await _dio.post(
      '/notifications/push-token/',
      data: {'token': token, 'plateforme': plateforme},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
  }
}
