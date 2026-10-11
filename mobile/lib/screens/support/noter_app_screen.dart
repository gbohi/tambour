import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/support_provider.dart';
import '../../services/support_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/champ_formulaire.dart';
import '../../widgets/page_header.dart';

class NoterAppScreen extends ConsumerStatefulWidget {
  const NoterAppScreen({super.key});
  @override
  ConsumerState<NoterAppScreen> createState() => _NoterAppScreenState();
}

class _NoterAppScreenState extends ConsumerState<NoterAppScreen> {
  static const _libelles = ['', 'Très décevant', 'Décevant', 'Correct', 'Bien', 'Excellent !'];
  final _commentaireCtrl = TextEditingController();
  int _note = 0;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    // Reprend la note déjà donnée, le cas échéant
    ref.read(supportServiceProvider).getMaNote().then((n) {
      if (n != null && mounted && _note == 0) setState(() => _note = n);
    });
  }

  @override
  void dispose() { _commentaireCtrl.dispose(); super.dispose(); }

  String get _plateforme => kIsWeb ? 'web' : Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'autre';

  Future<void> _envoyer() async {
    if (_note == 0) { AppSnackbar.erreur(context, 'Choisissez une note de 1 à 5 étoiles'); return; }
    setState(() => _envoi = true);
    try {
      final msg = await ref.read(supportServiceProvider).noterApplication(
        note: _note, commentaire: _commentaireCtrl.text.trim(),
        plateforme: _plateforme, version: AppConstants.version);
      if (!mounted) return;
      AppSnackbar.succes(context, msg);
      Navigator.maybePop(context);
    } on SupportException catch (e) {
      if (mounted) AppSnackbar.erreur(context, e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        const PageHeader(titre: "Noter l'application"),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(children: [
            Container(width: 80, height: 80,
              decoration: const BoxDecoration(color: TamBourColors.goldLight, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: TamBourColors.gold, size: 40))
              .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 18),
            const Text('Vous aimez TamBour ?', style: TextStyle(fontFamily: 'Outfit', fontSize: 22,
              fontWeight: FontWeight.w800, color: TamBourColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Votre avis nous aide à améliorer l\'application pour tous les voyageurs.',
              textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
                color: TamBourColors.textSecondary)),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 42, padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => setState(() => _note = i),
                  icon: Icon(i <= _note ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i <= _note ? TamBourColors.gold : TamBourColors.border),
                ).animate(target: i <= _note ? 1 : 0).scaleXY(end: 1.1, duration: 150.ms),
            ]),
            SizedBox(height: 24, child: Text(_libelles[_note], style: const TextStyle(fontFamily: 'Outfit',
              fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.gold))),
            const SizedBox(height: 20),
            ChampFormulaire(controller: _commentaireCtrl, lignes: 4, longueurMax: 1000,
              label: _note > 0 && _note <= 3 ? 'Que pouvons-nous améliorer ?' : 'Un commentaire ? (facultatif)',
              hint: 'Dites-nous ce que vous en pensez…'),
            const SizedBox(height: 16),
            AppButton(label: 'Envoyer mon avis', icon: Icons.send_rounded, isLoading: _envoi,
              onPressed: _note == 0 ? null : _envoyer),
          ]),
        )),
      ]),
    );
  }
}
