import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icone;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const AuthField({super.key, required this.controller, required this.label, required this.hint,
    required this.icone, this.validator, this.obscureText = false, this.suffixIcon,
    this.keyboardType, this.textCapitalization = TextCapitalization.none});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: YoBusColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, validator: validator, obscureText: obscureText,
        keyboardType: keyboardType, textCapitalization: textCapitalization,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: YoBusColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Icon(icone, size: 18, color: YoBusColors.textHint)),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon: suffixIcon,
          filled: true, fillColor: YoBusColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YoBusColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YoBusColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: YoBusColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: YoBusColors.textHint),
          errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.error))),
    ]);
  }
}

class ErreurBanner extends StatelessWidget {
  final String message;
  const ErreurBanner({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: YoBusColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YoBusColors.error.withOpacity(0.3), width: 1)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: YoBusColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: YoBusColors.error))),
      ]));
  }
}

class DividerOu extends StatelessWidget {
  const DividerOu({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('ou', style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: YoBusColors.textHint))),
      const Expanded(child: Divider()),
    ]);
  }
}
