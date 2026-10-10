import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/siege.dart';
import '../../../providers/siege_provider.dart';
import 'siege_widget.dart';

class PlanBus extends ConsumerWidget {
  final List<Siege> sieges;

  const PlanBus({super.key, required this.sieges});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<int, List<Siege>> parRangee = {};
    for (final s in sieges) {
      parRangee.putIfAbsent(s.rangee, () => []).add(s);
    }
    final rangees = parRangee.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: YoBusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YoBusColors.border, width: 0.5)),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(children: [
        // Cockpit
        Container(
          margin: const EdgeInsets.only(bottom: 6), height: 52,
          decoration: const BoxDecoration(
            color: YoBusColors.primary,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
          child: Center(child: Text('Chauffeur',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.white.withOpacity(0.75))))),
        // En-têtes colonnes
        Row(children: [
          const SizedBox(width: 20),
          ...['A', 'B', 'C', 'D'].map((c) => SizedBox(width: 40, child: Center(child: Text(c, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: YoBusColors.textHint))))),
          const Spacer(),
        ]),
        // Rangées
        ...rangees.map((r) {
          final sr = List<Siege>.from(parRangee[r]!)..sort((a, b) => a.colonne.compareTo(b.colonne));
          Siege? g(String col) {
            try { return sr.firstWhere((s) => s.colonne == col); } catch (_) { return null; }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              SizedBox(width: 20, child: Text('$r', style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: YoBusColors.textHint), textAlign: TextAlign.center)),
              for (final col in ['A', 'B'])
                if (g(col) != null)
                  SiegeWidget(siege: g(col)!, onTap: () => ref.read(siegeProvider.notifier).toggleSiege(g(col)!.id)),
              const Spacer(),
              for (final col in ['C', 'D'])
                if (g(col) != null)
                  SiegeWidget(siege: g(col)!, onTap: () => ref.read(siegeProvider.notifier).toggleSiege(g(col)!.id)),
            ]));
        }),
      ]),
    );
  }
}
