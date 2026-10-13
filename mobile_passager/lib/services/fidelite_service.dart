import 'package:tambour_passager/models/fidelite.dart';
import 'package:tambour_commun/services/api_client.dart';

class FideliteService {
  Future<FideliteInfo> getFidelite() async {
    final response = await ApiClient.instance.dio.get('/auth/fidelite/');
    return FideliteInfo.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
