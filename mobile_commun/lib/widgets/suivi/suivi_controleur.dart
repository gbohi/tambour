import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tambour_commun/models/suivi.dart';
import 'package:tambour_commun/services/suivi_service.dart';

/// Récupère l'état du trajet à intervalle régulier (15 s en route, 1 min avant le départ).
class SuiviControleur extends ChangeNotifier {
  final String trajetId;
  final SuiviService service;
  SuiviTrajet? suivi;
  String? erreur;
  bool _ferme = false;
  Timer? _minuteur;

  SuiviControleur(this.trajetId, {SuiviService? service}) : service = service ?? SuiviService();

  bool get chargement => suivi == null && erreur == null;

  Future<void> rafraichir() async {
    _minuteur?.cancel();
    try {
      suivi = await service.suivi(trajetId);
      erreur = null;
    } on SuiviException catch (e) {
      erreur = e.message;
    }
    if (_ferme) return;
    notifyListeners();
    final s = suivi;
    if (s != null && (s.estArrive || s.phase == 'annule')) return;   // plus rien à suivre
    final delai = s == null || s.enRoute ? (s?.rafraichirDansSecondes ?? 15) : 60;
    _minuteur = Timer(Duration(seconds: delai), rafraichir);
  }

  @override
  void dispose() {
    _ferme = true;
    _minuteur?.cancel();
    super.dispose();
  }
}
