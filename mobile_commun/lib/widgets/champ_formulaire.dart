import 'package:flutter/material.dart';
import 'package:tambour_commun/core/theme.dart';

/// Champ de saisie avec libellé, au style des formulaires de l'application.
class ChampFormulaire extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icone;
  final int lignes;
  final int? longueurMax;
  final TextInputType? clavier;
  final TextCapitalization majuscules;
  final String? Function(String?)? validator;

  const ChampFormulaire({super.key, required this.controller, required this.label, this.hint,
    this.icone, this.lignes = 1, this.longueurMax, this.clavier,
    this.majuscules = TextCapitalization.sentences, this.validator});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder bord(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
        fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, validator: validator, maxLines: lignes, minLines: lignes,
        maxLength: longueurMax, keyboardType: clavier, textCapitalization: majuscules,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textHint),
          prefixIcon: icone != null ? Icon(icone, size: 18, color: TamBourColors.textHint) : null,
          filled: true, fillColor: TamBourColors.surface,
          border: bord(TamBourColors.border, 1), enabledBorder: bord(TamBourColors.border, 1),
          focusedBorder: bord(TamBourColors.primary, 2),
          errorBorder: bord(TamBourColors.error, 1.5), focusedErrorBorder: bord(TamBourColors.error, 2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    ]);
  }
}
