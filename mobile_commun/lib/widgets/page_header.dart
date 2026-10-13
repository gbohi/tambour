import 'package:flutter/material.dart';
import 'package:tambour_commun/core/theme.dart';

/// En-tête vert des pages secondaires (retour + titre + sous-titre facultatif).
class PageHeader extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget? action;
  final Widget? bas;

  const PageHeader({super.key, required this.titre, this.sousTitre, this.action, this.bas});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.maybePop(context)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titre, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18,
                  fontWeight: FontWeight.w800, color: Colors.white)),
                if (sousTitre != null) ...[
                  const SizedBox(height: 2),
                  Text(sousTitre!, style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                    color: Colors.white.withOpacity(0.8))),
                ],
              ])),
              if (action != null) action!,
            ]),
            if (bas != null) Padding(padding: const EdgeInsets.fromLTRB(8, 12, 0, 0), child: bas!),
          ]),
        ),
      ),
    );
  }
}
