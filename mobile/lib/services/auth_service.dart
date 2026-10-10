import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override String toString() => message;
}

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService()
    : _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl, connectTimeout: const Duration(seconds: 10))),
      _storage = const FlutterSecureStorage();

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<bool> get estConnecte async => (await getAccessToken()) != null;

  Future<Map<String, dynamic>> login({required String email, required String motDePasse}) async {
    try {
      final response = await _dio.post('/auth/token/', data: {'email': email, 'password': motDePasse});
      final data = response.data['data'] as Map<String, dynamic>;
      await _saveTokens(access: data['access'] as String, refresh: data['refresh'] as String);
      return data;
    } on DioException catch (e) { throw AuthException(_parseError(e)); }
  }

  Future<Map<String, dynamic>> inscrire({required String prenom, required String nom,
    required String email, required String telephone, required String motDePasse,
    String? codeParrainage}) async {
    try {
      final response = await _dio.post('/auth/register/', data: {
        'prenom': prenom, 'nom': nom, 'email': email, 'telephone': telephone,
        'password': motDePasse, 'password_confirm': motDePasse,
        if (codeParrainage != null && codeParrainage.isNotEmpty) 'code_parrainage': codeParrainage,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      await _saveTokens(access: data['access'] as String, refresh: data['refresh'] as String);
      return data;
    } on DioException catch (e) { throw AuthException(_parseError(e)); }
  }

  /// Retourne le prénom du parrain si le code existe, sinon null.
  Future<String?> verifierCodeParrainage(String code) async {
    try {
      final response = await _dio.get('/auth/parrainage/verifier/', queryParameters: {'code': code});
      return response.data['data']['parrain_prenom'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final token = await getAccessToken();
      final response = await _dio.get('/auth/me/',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw AuthException(_parseError(e)); }
  }

  Future<UserModel> mettreAJourProfil(Map<String, dynamic> data) async {
    try {
      final token = await getAccessToken();
      final response = await _dio.patch('/auth/me/', data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw AuthException(_parseError(e)); }
  }

  Future<void> deconnecter() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<void> _saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  String _parseError(DioException e) {
    if (e.response?.statusCode == 401) return 'Email ou mot de passe incorrect.';
    if (e.response?.statusCode == 400) {
      // Préférer le premier message de champ (ex. « Code de parrainage invalide. »)
      final errors = e.response?.data?['errors'];
      if (errors is Map) {
        for (final v in errors.values) {
          if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
        }
      }
      final msg = e.response?.data?['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    if (e.type == DioExceptionType.connectionTimeout) return 'Connexion lente. Vérifiez votre réseau.';
    return 'Une erreur est survenue. Réessayez.';
  }
}
