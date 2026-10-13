import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/models/suivi.dart';

/// « Arrivée dans 1 h 25 » : temps restant, heure d'arrivée, progression et fraîcheur de la position.
class PanneauArrivee extends StatelessWidget {
  final SuiviTrajet suivi;
  /// Libellé de l'arrivée : « Arrivée » (voyageur) ou « Arrivée à destination » (chauffeur).
  final String libelle;
  const PanneauArrivee({super.key, required this.suivi, this.libelle = 'Arrivée'});

  @override
  Widget build(BuildContext context) {
    final s = suivi;
    final heure = DateFormat('HH:mm');
    final (titre, sousTitre) = switch (s.phase) {
      'a_venir' => (
        s.departDansMinutes == 0 ? 'Départ imminent' : 'Départ dans ${SuiviTrajet.duree(s.departDansMinutes ?? 0)}',
        '${s.depart} ${heure.format(s.heureDepart)} → ${s.arrivee}${s.arriveeEstimee != null ? ' ${heure.format(s.arriveeEstimee!)}' : ''}'),
      'arrivee_imminente' => ('Arrivée imminente', 'Le car approche de ${s.arrivee}'),
      'arrive' => ('Arrivé à ${s.arrivee}', s.arriveeEstimee != null ? 'à ${heure.format(s.arriveeEstimee!)}' : ''),
      'annule' => ('Trajet annulé', 'Consultez vos billets pour le remboursement'),
      _ => (
        '$libelle dans ${SuiviTrajet.duree(s.minutesRestantes ?? 0)}',
        'à ${s.arrivee}${s.arriveeEstimee != null ? ' vers ${heure.format(s.arriveeEstimee!)}' : ''}'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titre, style: const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800,
            color: TamBourColors.textPrimary, height: 1.15)),
          const SizedBox(height: 4),
          Text(sousTitre, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)),
        ])),
        if (s.retardMinutes > 0 && !s.estArrive)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: TamBourColors.goldLight, borderRadius: BorderRadius.circular(20)),
            child: Text('+${s.retardMinutes} min', style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
              fontWeight: FontWeight.w700, color: Color(0xFF8A5A00)))),
      ]),
      const SizedBox(height: 16),
      _Progression(suivi: s),
      const SizedBox(height: 12),
      _Source(suivi: s),
    ]);
  }
}

class _Progression extends StatelessWidget {
  final SuiviTrajet suivi;
  const _Progression({required this.suivi});
  @override
  Widget build(BuildContext context) {
    final p = (suivi.progression.clamp(0, 100)) / 100;
    return Column(children: [
      LayoutBuilder(builder: (context, c) {
        final x = (c.maxWidth - 28) * p;
        return SizedBox(height: 28, child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
          Container(height: 6, decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(3))),
          FractionallySizedBox(widthFactor: p, child: Container(height: 6,
            decoration: BoxDecoration(color: TamBourColors.primary, borderRadius: BorderRadius.circular(3)))),
          Positioned(left: x, child: Container(width: 28, height: 28,
            decoration: BoxDecoration(color: TamBourColors.marque, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5)),
            child: const Icon(Icons.directions_bus_rounded, size: 15, color: Colors.white))),
        ]));
      }),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: Text(suivi.depart, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary))),
        Text('${suivi.progression} %', style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
          fontWeight: FontWeight.w700, color: TamBourColors.primary)),
        Expanded(child: Text(suivi.arrivee, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary))),
      ]),
    ]);
  }
}

class _Source extends StatelessWidget {
  final SuiviTrajet suivi;
  const _Source({required this.suivi});
  @override
  Widget build(BuildContext context) {
    final s = suivi;
    final gps = s.source == 'gps' && s.position != null;
    final texte = gps
      ? 'Position GPS ${SuiviTrajet.ilYa(s.position!.ilYaSecondes)}'
          '${s.position!.vitesseKmh != null ? ' · ${s.position!.vitesseKmh!.round()} km/h' : ''}'
      : s.enRoute ? "Estimation selon l'horaire (position du car indisponible)"
      : s.phase == 'a_venir' ? 'Le suivi en direct commence au départ du car' : 'Suivi terminé';
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
        color: gps ? const Color(0xFF22C55E) : TamBourColors.textHint)),
      const SizedBox(width: 8),
      Expanded(child: Text(texte, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, color: TamBourColors.textSecondary))),
      if (s.distanceRestanteKm != null && s.enRoute)
        Text('${s.distanceRestanteKm!.round()} km restants', style: const TextStyle(fontFamily: 'Outfit',
          fontSize: 12.5, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
    ]);
  }
}
