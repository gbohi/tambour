import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/gare.dart';

class MarqueurGare extends StatelessWidget {
  final Gare gare;
  final bool estSelectionne;
  final VoidCallback onTap;

  const MarqueurGare({
    super.key,
    required this.gare,
    required this.estSelectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taille = estSelectionne ? 44.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: taille, height: taille,
          decoration: BoxDecoration(
            color: estSelectionne || gare.estPrincipale ? YoBusColors.primary : YoBusColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: YoBusColors.primary, width: estSelectionne ? 3 : 2),
            boxShadow: [BoxShadow(
              color: YoBusColors.primary.withOpacity(estSelectionne ? 0.4 : 0.2),
              blurRadius: estSelectionne ? 12 : 6, offset: const Offset(0, 3))]),
          child: Center(child: Icon(Icons.directions_bus_rounded,
            size: estSelectionne ? 22 : 18,
            color: estSelectionne || gare.estPrincipale ? Colors.white : YoBusColors.primary))),
        Container(width: 2.5, height: 8, color: YoBusColors.primary),
        Container(width: 7, height: 7, decoration: const BoxDecoration(color: YoBusColors.primary, shape: BoxShape.circle)),
        if (estSelectionne)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: YoBusColors.primary, borderRadius: BorderRadius.circular(5)),
            child: Text(gare.ville, style: const TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    );
  }
}
