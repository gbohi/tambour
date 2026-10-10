import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/siege.dart';

class SiegeWidget extends StatelessWidget {
  final Siege siege;
  final VoidCallback? onTap;

  const SiegeWidget({super.key, required this.siege, this.onTap});

  Color get _backgroundColor => switch (siege.statut) {
    StatutSiege.libre => YoBusColors.primaryLight,
    StatutSiege.occupe => YoBusColors.surfaceVariant,
    StatutSiege.selectionne => YoBusColors.primary,
    StatutSiege.rezerveHandicap => const Color(0xFFE8F4FD),
  };

  Color get _borderColor => switch (siege.statut) {
    StatutSiege.libre => const Color(0x4D0A7C4E),
    StatutSiege.occupe => YoBusColors.border,
    StatutSiege.selectionne => YoBusColors.primary,
    StatutSiege.rezerveHandicap => Colors.blue,
  };

  bool get _estOccupe => siege.statut == StatutSiege.occupe;
  bool get _estSelectionne => siege.statut == StatutSiege.selectionne;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: siege.estSelectionnable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor, width: 1.5)),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
            top: 3, left: 4, right: 4,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: _estOccupe ? YoBusColors.border : _estSelectionne ? Colors.white.withOpacity(0.2) : YoBusColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))))),
          Positioned(
            bottom: 4,
            child: _estOccupe
                ? const Icon(Icons.close_rounded, size: 12, color: YoBusColors.textHint)
                : _estSelectionne
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                    : Text(siege.label,
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w700,
                            color: _estSelectionne ? Colors.white : YoBusColors.primary))),
        ]),
      ),
    );
  }
}

class LegendeSeats extends StatelessWidget {
  const LegendeSeats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _LegItem(color: YoBusColors.primaryLight, borderColor: YoBusColors.primary.withOpacity(0.3), label: 'Libre'),
      const SizedBox(width: 16),
      _LegItem(color: YoBusColors.surfaceVariant, borderColor: YoBusColors.border, label: 'Occupé'),
      const SizedBox(width: 16),
      _LegItem(color: YoBusColors.primary, borderColor: YoBusColors.primary, label: 'Sélectionné', textColor: Colors.white),
    ]);
  }
}

class _LegItem extends StatelessWidget {
  final Color color, borderColor;
  final String label;
  final Color textColor;
  const _LegItem({required this.color, required this.borderColor, required this.label, this.textColor = YoBusColors.textSecondary});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 20, height: 18,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), border: Border.all(color: borderColor, width: 1.5))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: textColor == Colors.white ? YoBusColors.textPrimary : YoBusColors.textSecondary, fontWeight: FontWeight.w500)),
    ]);
  }
}
