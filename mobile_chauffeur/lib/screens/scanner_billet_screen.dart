import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_chauffeur/models/chauffeur.dart';
import 'package:tambour_chauffeur/services/chauffeur_service.dart';

/// Scan des QR codes des billets à l'embarquement.
class ScannerBilletScreen extends StatefulWidget {
  final TrajetChauffeur trajet;
  final ChauffeurService? service;
  const ScannerBilletScreen({super.key, required this.trajet, this.service});
  @override
  State<ScannerBilletScreen> createState() => _ScannerBilletScreenState();
}

class _ScannerBilletScreenState extends State<ScannerBilletScreen> {
  late final ChauffeurService _service = widget.service ?? ChauffeurService();
  final _camera = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  ResultatScan? _resultat;
  bool _verification = false;
  int _valides = 0;
  Timer? _masquer;

  @override
  void dispose() {
    _masquer?.cancel();
    _camera.dispose();
    super.dispose();
  }

  Future<void> _verifier({String? qr, String? reference}) async {
    if (_verification) return;
    setState(() { _verification = true; _resultat = null; });
    final r = await _service.scanner(widget.trajet.id, qrData: qr, referenceBillet: reference);
    if (!mounted) return;
    r.ok ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    setState(() { _verification = false; _resultat = r; if (r.ok) _valides++; });
    _masquer?.cancel();
    _masquer = Timer(Duration(seconds: r.ok ? 3 : 5), () { if (mounted) setState(() => _resultat = null); });
  }

  void _onDetect(BarcodeCapture capture) {
    final valeur = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (valeur != null) _verifier(qr: valeur);
  }

  Future<void> _saisieManuelle() async {
    final ctrl = TextEditingController();
    final ref = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Saisir la référence', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800)),
      content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(hintText: 'Ex : TB202610123456-P1', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: TamBourColors.primary), child: const Text('Vérifier')),
      ],
    ));
    ctrl.dispose();
    if (ref != null && ref.isNotEmpty) _verifier(reference: ref);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trajet;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: MobileScanner(
          controller: _camera, onDetect: _onDetect,
          errorBuilder: (context, error) => Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(error.errorCode == MobileScannerErrorCode.permissionDenied
                ? 'Autorisez l\'accès à l\'appareil photo pour scanner les billets.'
                : 'Caméra indisponible. Utilisez la saisie manuelle.',
              textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', color: Colors.white)))),
        )),
        // Cadre de visée
        Center(child: Container(width: 250, height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 3)))),
        // En-tête
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(children: [
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t.depart} → ${t.arrivee}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('${t.nbEmbarques + _valides}/${t.nbPassagers} passagers à bord',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.white.withOpacity(0.8))),
            ])),
            IconButton(onPressed: () => _camera.toggleTorch(), tooltip: 'Lampe',
              icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white)),
          ]),
        )),
        // Résultat / consigne
        Positioned(left: 16, right: 16, bottom: 0, child: SafeArea(child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_verification)
              const _Bandeau(couleur: Colors.white, icone: Icons.hourglass_top_rounded,
                titre: 'Vérification…', texteCouleur: TamBourColors.textPrimary)
            else if (_resultat != null)
              _Bandeau(
                couleur: _resultat!.ok ? TamBourColors.primary
                  : _resultat!.code == 'deja_utilise' ? const Color(0xFFB26A00) : TamBourColors.error,
                icone: _resultat!.ok ? Icons.check_circle_rounded
                  : _resultat!.code == 'deja_utilise' ? Icons.warning_rounded : Icons.cancel_rounded,
                titre: _resultat!.ok ? 'Billet valide' : 'Billet refusé',
                texte: _resultat!.message,
              ).animate().scale(begin: const Offset(0.9, 0.9), duration: 200.ms).fadeIn()
            else
              Text('Placez le QR code du billet dans le cadre', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _saisieManuelle,
              icon: const Icon(Icons.keyboard_rounded, color: Colors.white),
              label: const Text('Saisir la référence', style: TextStyle(fontFamily: 'Outfit', color: Colors.white,
                fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
            ),
          ]),
        ))),
      ]),
    );
  }
}

class _Bandeau extends StatelessWidget {
  final Color couleur;
  final IconData icone;
  final String titre;
  final String? texte;
  final Color texteCouleur;
  const _Bandeau({required this.couleur, required this.icone, required this.titre, this.texte,
    this.texteCouleur = Colors.white});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(icone, color: texteCouleur, size: 40),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(titre, style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: texteCouleur)),
        if (texte != null) ...[
          const SizedBox(height: 2),
          Text(texte!, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: texteCouleur.withOpacity(0.95))),
        ],
      ])),
    ]),
  );
}
