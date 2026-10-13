import 'package:flutter/material.dart';
import 'package:tambour_commun/core/theme.dart';

/// Logo TamBour : symbole (tambour + route) suivi du nom, en une seule couleur comme le logo officiel.
/// [clair] : version blanche pour fonds verts.
class LogoTamBour extends StatelessWidget {
  final double taille;   // hauteur du texte
  final bool clair;
  const LogoTamBour({super.key, this.taille = 22, this.clair = true});

  @override
  Widget build(BuildContext context) {
    final couleur = clair ? Colors.white : TamBourColors.marque;
    return Semantics(
      label: 'TamBour',
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Image.asset(clair ? 'assets/images/logo_symbole_clair.png' : 'assets/images/logo_symbole.png',
          package: 'tambour_commun', height: taille * 1.35, excludeFromSemantics: true),
        SizedBox(width: taille * 0.32),
        Text('TamBour', style: TextStyle(fontFamily: 'Outfit', fontSize: taille,
          fontWeight: FontWeight.w800, color: couleur, letterSpacing: -taille * 0.02, height: 1)),
      ]),
    );
  }
}
