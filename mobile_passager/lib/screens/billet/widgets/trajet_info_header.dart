import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/trajet.dart';

class TrajetInfoHeader extends StatelessWidget {
  final Trajet trajet;

  const TrajetInfoHeader({super.key, required this.trajet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: TamBourColors.primary,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trajet.depart.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(trajet.depart.region, style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white.withOpacity(0.7))),
          ])),
          Column(children: [
            const Icon(Icons.arrow_forward_rounded, color: TamBourColors.gold, size: 28),
            Text(trajet.dureeLabel, style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Colors.white.withOpacity(0.7))),
          ]),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(trajet.arrivee.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.end),
            Text(trajet.arrivee.region, style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.end),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _InfoBloc(label: 'Départ', value: DateFormat('HH:mm').format(trajet.heureDepart)),
          _InfoBloc(label: 'Arrivée', value: DateFormat('HH:mm').format(trajet.heureArrivee)),
          _InfoBloc(label: 'Date', value: DateFormat('dd/MM/yy').format(trajet.heureDepart)),
          _InfoBloc(label: 'Compagnie', value: trajet.compagnie.split(' ').first),
        ]),
      ]),
    );
  }
}

class _InfoBloc extends StatelessWidget {
  final String label, value;
  const _InfoBloc({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
    ]);
  }
}
