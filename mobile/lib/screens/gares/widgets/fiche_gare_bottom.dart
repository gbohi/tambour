import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/gare.dart';

class FicheGareBottom extends StatelessWidget {
  final Gare gare;
  final VoidCallback onNaviguer;
  final VoidCallback? onVoirTrajets;

  const FicheGareBottom({
    super.key,
    required this.gare,
    required this.onNaviguer,
    this.onVoirTrajets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YoBusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YoBusColors.primary, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(color: YoBusColors.primary, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gare.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 12, color: YoBusColors.textHint), const SizedBox(width: 4),
              Text(gare.heuresOuverture, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary)),
            ]),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 13, color: YoBusColors.textHint), const SizedBox(width: 4),
          Expanded(child: Text(gare.adresse,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        if (gare.compagnies.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: gare.compagnies.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: YoBusColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
            child: Text(c, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600, color: YoBusColors.textSecondary)))).toList()),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: onVoirTrajets,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Voir les trajets'),
            style: OutlinedButton.styleFrom(
              foregroundColor: YoBusColors.primary,
              side: const BorderSide(color: YoBusColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: onNaviguer,
            icon: const Icon(Icons.navigation_rounded, size: 16),
            label: const Text('Y aller'),
            style: ElevatedButton.styleFrom(
              backgroundColor: YoBusColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700)))),
        ]),
      ]),
    );
  }
}
