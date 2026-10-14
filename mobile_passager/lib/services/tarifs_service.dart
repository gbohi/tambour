import 'package:tambour_passager/models/tarifs.dart';
import 'package:tambour_commun/services/api_client.dart';

class TarifsService {
  Future<TarifsPlateforme> getTarifs() async {
    try {
      final response = await ApiClient.instance.dio.get('/plateforme/tarifs/');
      return TarifsPlateforme.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return TarifsPlateforme.parDefaut;
    }
  }
}
