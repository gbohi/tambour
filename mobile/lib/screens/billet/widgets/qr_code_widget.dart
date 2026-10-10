import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final String reference;
  final double size;

  const QrCodeWidget({
    super.key,
    required this.data,
    required this.reference,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YoBusColors.border, width: 0.5)),
      child: Column(children: [
        QrImageView(
          data: data,
          version: QrVersions.auto,
          size: size,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: YoBusColors.primary),
          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: YoBusColors.textPrimary)),
        const SizedBox(height: 10),
        Text(reference,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: YoBusColors.textSecondary, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        const Text("Présentez ce QR code à l'embarquement",
          style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
      ]),
    );
  }
}
