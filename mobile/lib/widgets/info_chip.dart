import 'package:flutter/material.dart';
import '../core/theme.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? TamBourColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: iconColor ?? TamBourColors.textSecondary),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w500, color: textColor ?? TamBourColors.textSecondary)),
      ]));
  }
}
