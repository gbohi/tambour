import 'package:tambour_passager/models/ligne_populaire.dart';
import 'package:tambour_commun/services/api_client.dart';

class LigneService {
  Future<List<LignePopulaire>> getLignesPopulaires() async {
    try {
      final response = await ApiClient.instance.dio.get('/lignes/populaires/');
      final lignes = (response.data['data']['results'] as List)
        .map((l) => LignePopulaire.fromJson(l as Map<String, dynamic>))
        .toList();
      return lignes.isEmpty ? LignePopulaire.parDefaut : lignes;
    } catch (_) {
      return LignePopulaire.parDefaut;
    }
  }
}
