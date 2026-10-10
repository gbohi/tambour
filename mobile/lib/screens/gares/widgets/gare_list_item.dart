import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../../models/gare.dart';

class GareListItem extends StatelessWidget {
  final Gare gare;
  final bool estSelectionnee;
  final VoidCallback onTap;
  final int index;

  const GareListItem({
    super.key,
    required this.gare,
    required this.estSelectionnee,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: estSelectionnee ? TamBourColors.primaryLight : TamBourColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionnee ? TamBourColors.primary : TamBourColors.border,
            width: estSelectionnee ? 1.5 : 0.5)),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: estSelectionnee ? TamBourColors.primary : TamBourColors.primaryLight,
              borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.directions_bus_rounded,
              color: estSelectionnee ? Colors.white : TamBourColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(gare.nom,
                style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700,
                  color: estSelectionnee ? TamBourColors.primaryDark : TamBourColors.textPrimary))),
              if (gare.estPrincipale)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: TamBourColors.goldLight, borderRadius: BorderRadius.circular(5)),
                  child: const Text('Principale', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w700, color: TamBourColors.gold))),
            ]),
            const SizedBox(height: 3),
            Text(gare.ville, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(gare.adresse, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (gare.compagnies.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${gare.compagnies.length} compagnie${gare.compagnies.length > 1 ? 's' : ''} · ${gare.heuresOuverture}',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textSecondary)),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, color: TamBourColors.textHint, size: 20),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 60 + index * 50), duration: 300.ms).slideX(begin: 0.04, end: 0),
    );
  }
}
