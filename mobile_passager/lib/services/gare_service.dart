import 'package:tambour_passager/models/gare.dart';
import 'package:tambour_passager/models/trajet.dart';
import 'package:tambour_passager/models/ville.dart';
import 'package:tambour_commun/services/api_client.dart';

class GareService {
  Future<List<Gare>> getGares() async {
    try {
      final res = await ApiClient.instance.dio.get('/gares/', queryParameters: {'page_size': 200});
      final liste = res.data['data']['results'] as List;
      final gares = liste.map((g) => Gare.fromJson(g as Map<String, dynamic>)).toList();
      return gares.isEmpty ? Gare.mockGares() : gares;
    } catch (_) {
      return Gare.mockGares();
    }
  }

  /// Départs des 7 prochains jours depuis la gare (API, sinon données de démonstration).
  Future<List<Trajet>> getDeparts(Gare gare) async {
    try {
      final res = await ApiClient.instance.dio.get('/gares/${gare.id}/departs/');
      return (res.data['data']['results'] as List)
        .map((t) => Trajet.fromJson(t as Map<String, dynamic>)).toList();
    } catch (_) {
      return _departsDemo(gare);
    }
  }

  List<Trajet> _departsDemo(Gare gare) {
    String id(String nom) {
      final n = nom.toLowerCase();
      return Ville.mockVilles.firstWhere((v) => v.nom.toLowerCase() == n,
        orElse: () => Ville.mockVilles.first).id;
    }
    final departId = id(gare.ville);
    final destinations = gare.lignes
      .map((l) => l.split('→').last.trim())
      .where((d) => d.isNotEmpty && d.toLowerCase() != gare.ville.toLowerCase())
      .toList();
    final trajets = <Trajet>[
      for (final d in destinations) ...Trajet.mockTrajets(departId, id(d)),
    ]..sort((a, b) => a.heureDepart.compareTo(b.heureDepart));
    return trajets;
  }
}
