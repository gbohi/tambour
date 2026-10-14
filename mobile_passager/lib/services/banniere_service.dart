import 'package:tambour_passager/models/banniere.dart';
import 'package:tambour_commun/services/api_client.dart';

class BanniereService {
  /// Bannières actives, dans l'ordre défini par l'administrateur. Liste vide hors ligne.
  Future<List<Banniere>> getBannieres() async {
    try {
      final response = await ApiClient.instance.dio.get('/bannieres/');
      return (response.data['data']['results'] as List)
        .map((b) => Banniere.fromJson(b as Map<String, dynamic>))
        .toList();
    } catch (_) {
      return const [];
    }
  }
}
