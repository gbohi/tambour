import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/paiement.dart';

class MethodePaiementCard extends StatelessWidget {
  final MethodePaiement methode;
  final bool selected;
  final VoidCallback onTap;

  const MethodePaiementCard({
    super.key,
    required this.methode,
    required this.selected,
    required this.onTap,
  });

  String get _nom => switch (methode) {
    MethodePaiement.mtnMomo => 'MTN Mobile Money',
    MethodePaiement.orangeMoney => 'Orange Money',
    MethodePaiement.wave => 'Wave',
    MethodePaiement.carte => 'Carte bancaire',
  };

  Color get _couleur => switch (methode) {
    MethodePaiement.mtnMomo => const Color(0xFFFFCC00),
    MethodePaiement.orangeMoney => const Color(0xFFFF6600),
    MethodePaiement.wave => const Color(0xFF1AC9E6),
    MethodePaiement.carte => const Color(0xFF1A56DB),
  };

  Color get _textColor => switch (methode) {
    MethodePaiement.mtnMomo => const Color(0xFF5C4500),
    _ => Colors.white,
  };

  IconData get _icon => switch (methode) {
    MethodePaiement.mtnMomo => Icons.signal_cellular_alt_rounded,
    MethodePaiement.orangeMoney => Icons.signal_cellular_alt_2_bar_rounded,
    MethodePaiement.wave => Icons.waves_rounded,
    MethodePaiement.carte => Icons.credit_card_rounded,
  };

  String get _description => switch (methode) {
    MethodePaiement.mtnMomo => 'Paiement instantané depuis votre compte MTN',
    MethodePaiement.orangeMoney => 'Paiement instantané depuis votre compte Orange',
    MethodePaiement.wave => 'Paiement rapide via l\'application Wave',
    MethodePaiement.carte => 'Visa, Mastercard, carte locale',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _couleur.withOpacity(0.08) : YoBusColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _couleur : YoBusColors.border, width: selected ? 2 : 0.5)),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: _couleur, borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _textColor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
            const SizedBox(height: 3),
            Text(_description, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textSecondary)),
          ])),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _couleur : Colors.transparent,
              border: Border.all(color: selected ? _couleur : YoBusColors.border, width: 2)),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null),
        ]),
      ),
    );
  }
}
