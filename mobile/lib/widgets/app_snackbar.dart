import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppSnackbar {
  static void succes(BuildContext context, String message) {
    _show(context, message, TamBourColors.primary, Icons.check_circle_rounded);
  }

  static void erreur(BuildContext context, String message) {
    _show(context, message, TamBourColors.error, Icons.error_outline_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, TamBourColors.textSecondary, Icons.info_outline_rounded);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3)));
  }
}
