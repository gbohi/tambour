import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/trajet.dart';
import '../../../providers/recherche_provider.dart';
import '../../../providers/siege_provider.dart';

class RecapPaiement extends ConsumerWidget {
  final Trajet trajet;
  final RechercheParams params;

  const RecapPaiement({super.key, required this.trajet, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final sieges = ref.watch(siegeProvider).selection;
    final total = trajet.prixFcfa * params.nbPassagers;

    return Container(
      decoration: BoxDecoration(
        color: YoBusColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YoBusColors.border, width: 0.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: YoBusColors.primaryLight,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18))),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: YoBusColors.primary, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(trajet.depart.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: YoBusColors.primaryDark)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.arrow_forward_rounded, size: 12, color: YoBusColors.primary)),
                Text(trajet.arrivee.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: YoBusColors.primaryDark)),
              ]),
              Text('${DateFormat('HH:mm').format(trajet.heureDepart)} · ${trajet.compagnie}',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.primary)),
            ])),
          ])),
        Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          _Ligne('Prix par passager', '${fmt.format(trajet.prixFcfa)} FCFA'),
          const SizedBox(height: 6),
          _Ligne('Passagers', '${params.nbPassagers} passager${params.nbPassagers > 1 ? 's' : ''}'),
          const SizedBox(height: 6),
          _Ligne('Sièges', sieges.join(', ')),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total à payer', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
            Text('${fmt.format(total)} FCFA', style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: YoBusColors.primary)),
          ]),
        ])),
      ]),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String label, value;
  const _Ligne(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary)),
    Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: YoBusColors.textPrimary)),
  ]);
}
