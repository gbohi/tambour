import 'package:flutter/material.dart';
import 'package:tambour_commun/services/suivi_service.dart';
import 'package:tambour_commun/widgets/suivi/ecran_suivi.dart';
import 'package:tambour_commun/widgets/suivi/suivi_controleur.dart';

/// Suivi en temps réel du car d'une réservation : position, temps restant, heure d'arrivée.
class SuiviTrajetScreen extends StatefulWidget {
  final String trajetId;
  final SuiviService? service;
  const SuiviTrajetScreen({super.key, required this.trajetId, this.service});

  static Future<void> ouvrir(BuildContext context, String trajetId) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => SuiviTrajetScreen(trajetId: trajetId)));

  @override
  State<SuiviTrajetScreen> createState() => _SuiviTrajetScreenState();
}

class _SuiviTrajetScreenState extends State<SuiviTrajetScreen> {
  late final SuiviControleur _controleur = SuiviControleur(widget.trajetId, service: widget.service);

  @override
  void dispose() { _controleur.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => EcranSuivi(controleur: _controleur);
}
