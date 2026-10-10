import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: YoBusColors.goldLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YoBusColors.gold.withOpacity(0.3))),
        child: Row(children: [
          const SizedBox(width: 20),
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: YoBusColors.gold.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_rounded, color: YoBusColors.gold, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Offre de lancement', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF7A4F00))),
            const SizedBox(height: 4),
            Text('-15% sur votre 1er trajet avec le code YOBUS15',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.gold.withOpacity(0.8))),
          ])),
          const SizedBox(width: 16),
        ]),
      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }
}
