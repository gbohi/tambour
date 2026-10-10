import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/trajet.dart';
import '../../../models/siege.dart';
import '../../../providers/recherche_provider.dart';
import '../../siege/siege_screen.dart';

class TrajetCard extends StatelessWidget {
  final Trajet trajet;
  final int nbPassagers;
  final int index;
  final RechercheParams params;

  const TrajetCard({super.key, required this.trajet, required this.nbPassagers, required this.index, required this.params});

  String _heure(DateTime dt) => DateFormat('HH:mm').format(dt);

  Color get _classeColor => trajet.classe == ClasseBus.vip ? YoBusColors.gold : trajet.classe == ClasseBus.confort ? YoBusColors.primary : YoBusColors.textSecondary;
  String get _classeLabel => trajet.classe == ClasseBus.vip ? 'VIP' : trajet.classe == ClasseBus.confort ? 'Confort' : 'Standard';
  Color get _classeBg => trajet.classe == ClasseBus.vip ? const Color(0xFFFFF8EC) : trajet.classe == ClasseBus.confort ? YoBusColors.primaryLight : YoBusColors.surfaceVariant;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final prixTotal = trajet.prixFcfa * nbPassagers;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiegeScreen(trajet: trajet, params: params))),
      child: Container(
        decoration: BoxDecoration(
          color: YoBusColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: trajet.classe == ClasseBus.vip ? YoBusColors.gold.withOpacity(0.4) : YoBusColors.border, width: trajet.classe == ClasseBus.vip ? 1.5 : 0.5)),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: YoBusColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.directions_bus_rounded, color: YoBusColors.primary, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trajet.compagnie, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
              Text(trajet.busImmatriculation, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _classeBg, borderRadius: BorderRadius.circular(20)),
              child: Text(_classeLabel, style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: _classeColor))),
            const SizedBox(width: 8),
            Row(children: [
              const Icon(Icons.star_rounded, color: YoBusColors.gold, size: 14), const SizedBox(width: 3),
              Text(trajet.note.toStringAsFixed(1), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
            ]),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_heure(trajet.heureDepart), style: const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: YoBusColors.textPrimary)),
              Text(trajet.depart.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary)),
            ]),
            Expanded(child: Column(children: [
              Text(trajet.dureeLabel, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textHint, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: YoBusColors.primary, shape: BoxShape.circle)),
                Expanded(child: Container(height: 1.5, color: YoBusColors.border)),
                const Icon(Icons.directions_bus_rounded, color: YoBusColors.primary, size: 16),
                Expanded(child: Container(height: 1.5, color: YoBusColors.border)),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: YoBusColors.gold, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              const Text('Direct', style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_heure(trajet.heureArrivee), style: const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: YoBusColors.textPrimary)),
              Text(trajet.arrivee.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary)),
            ]),
          ])),
          if (trajet.amenities.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: trajet.amenities.take(4).map((a) => _AmenityChip(amenity: a)).toList())),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: trajet.presqueComplet ? YoBusColors.error : YoBusColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(trajet.presqueComplet ? '${trajet.placesDisponibles} places restantes !' : '${trajet.placesDisponibles} places',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: trajet.presqueComplet ? YoBusColors.error : YoBusColors.success)),
              ]),
              const SizedBox(height: 2),
              Text('${trajet.nombreAvis} avis', style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: '${formatter.format(prixTotal)} ', style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w800, color: YoBusColors.primary)),
                const TextSpan(text: 'FCFA', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w500, color: YoBusColors.textSecondary)),
              ])),
              if (nbPassagers > 1) Text('${formatter.format(trajet.prixFcfa)} F/pers.', style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
            ]),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiegeScreen(trajet: trajet, params: params))),
              style: ElevatedButton.styleFrom(backgroundColor: YoBusColors.primary, foregroundColor: Colors.white, minimumSize: const Size(88, 40), maximumSize: const Size(100, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16), textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700)),
              child: const Text('Choisir')),
          ])),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 80), duration: 400.ms).slideY(begin: 0.08, end: 0),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String amenity;
  const _AmenityChip({required this.amenity});
  IconData get _icon => switch (amenity) {
    'wifi' => Icons.wifi_rounded, 'clim' => Icons.ac_unit_rounded,
    'usb' => Icons.usb_rounded, 'eau' => Icons.water_drop_outlined,
    'snack' => Icons.lunch_dining_rounded, 'siege_large' => Icons.airline_seat_recline_extra_rounded,
    _ => Icons.check_circle_outline_rounded,
  };
  String get _label => switch (amenity) {
    'wifi' => 'Wi-Fi', 'clim' => 'Clim', 'usb' => 'USB',
    'eau' => 'Eau', 'snack' => 'Snack', 'siege_large' => 'Siège large',
    _ => amenity,
  };
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: YoBusColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, size: 12, color: YoBusColors.textSecondary), const SizedBox(width: 4),
        Text(_label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textSecondary, fontWeight: FontWeight.w500)),
      ]));
  }
}
