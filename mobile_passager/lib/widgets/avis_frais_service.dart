import 'package:flutter/material.dart';
import 'package:tambour_commun/core/theme.dart';

/// Bandeau d'information sur les frais de service (même style que l'avis « 1er passager »).
class AvisFraisService extends StatelessWidget {
  const AvisFraisService({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TamBourColors.goldLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TamBourColors.gold.withOpacity(0.3))),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 16, color: TamBourColors.gold),
        SizedBox(width: 8),
        Expanded(child: Text(
          "Des frais de service s'appliquent à chaque réservation.",
          style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF7A4F00), height: 1.4))),
      ]));
  }
}
