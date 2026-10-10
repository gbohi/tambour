import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../widgets/section_header.dart';

class LignesPopulaires extends StatelessWidget {
  const LignesPopulaires({super.key});

  static const List<Map<String, dynamic>> _lignes = [
    {'depart': 'Abidjan', 'arrivee': 'Bouaké', 'duree': '3h30', 'prix': 3500, 'trajets': 8},
    {'depart': 'Abidjan', 'arrivee': 'Yamoussoukro', 'duree': '2h45', 'prix': 2800, 'trajets': 6},
    {'depart': 'Abidjan', 'arrivee': 'San-Pédro', 'duree': '4h15', 'prix': 4200, 'trajets': 4},
    {'depart': 'Abidjan', 'arrivee': 'Daloa', 'duree': '4h00', 'prix': 4000, 'trajets': 5},
    {'depart': 'Bouaké', 'arrivee': 'Korhogo', 'duree': '3h00', 'prix': 2500, 'trajets': 3},
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(titre: 'Lignes populaires', actionLabel: 'Voir tout'),
      const SizedBox(height: 16),
      SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _lignes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final l = _lignes[i];
            return Container(
              width: 190, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: YoBusColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: YoBusColors.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(l['depart'] as String, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary))),
                  const Icon(Icons.arrow_forward_rounded, size: 13, color: YoBusColors.textHint),
                  Expanded(child: Text(l['arrivee'] as String, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: YoBusColors.textHint), const SizedBox(width: 4),
                  Text(l['duree'] as String, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textSecondary)),
                  const SizedBox(width: 10),
                  const Icon(Icons.directions_bus_rounded, size: 12, color: YoBusColors.textHint), const SizedBox(width: 4),
                  Text('${l['trajets']}/jour', style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textSecondary)),
                ]),
                const Spacer(),
                RichText(text: TextSpan(children: [
                  const TextSpan(text: 'Dès ', style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
                  TextSpan(text: '${fmt.format(l['prix'] as int)} F', style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: YoBusColors.primary)),
                ])),
              ]),
            ).animate().fadeIn(delay: Duration(milliseconds: 600 + i * 80)).slideX(begin: 0.1, end: 0);
          }),
      ),
    ]);
  }
}
