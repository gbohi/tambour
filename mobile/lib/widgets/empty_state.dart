import 'package:flutter/material.dart';
import '../core/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String? description;
  final String? labelBouton;
  final VoidCallback? onBouton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titre,
    this.description,
    this.labelBouton,
    this.onBouton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(color: YoBusColors.primaryLight, shape: BoxShape.circle),
          child: Icon(icon, color: YoBusColors.primary, size: 42)),
        const SizedBox(height: 24),
        Text(titre, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary), textAlign: TextAlign.center),
        if (description != null) ...[
          const SizedBox(height: 10),
          Text(description!, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: YoBusColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
        ],
        if (labelBouton != null && onBouton != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBouton,
            style: ElevatedButton.styleFrom(
              backgroundColor: YoBusColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: 0,
              textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)),
            child: Text(labelBouton!)),
        ],
      ]),
    ));
  }
}
