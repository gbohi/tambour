import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class PassagerStepIndicator extends StatelessWidget {
  final int total;
  final int actif;

  const PassagerStepIndicator({super.key, required this.total, required this.actif});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(total, (i) => Expanded(child: Row(children: [
          Expanded(child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), height: 4,
            decoration: BoxDecoration(
              color: i <= actif ? TamBourColors.primary : TamBourColors.border,
              borderRadius: BorderRadius.circular(2)))),
          if (i < total - 1) const SizedBox(width: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == actif ? 26 : 20, height: i == actif ? 26 : 20,
            decoration: BoxDecoration(
              color: i < actif ? TamBourColors.primary : i == actif ? TamBourColors.primary : TamBourColors.border,
              shape: BoxShape.circle),
            child: Center(child: i < actif
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                : Text('${i + 1}', style: TextStyle(fontFamily: 'Outfit', fontSize: i == actif ? 11 : 9, fontWeight: FontWeight.w700, color: i == actif ? Colors.white : TamBourColors.textHint)))),
          if (i < total - 1) const SizedBox(width: 4),
        ]))),
      ),
    );
  }
}
