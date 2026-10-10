import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import 'auth_field.dart';

class InscriptionForm extends ConsumerStatefulWidget {
  const InscriptionForm({super.key});
  @override
  ConsumerState<InscriptionForm> createState() => _InscriptionFormState();
}

class _InscriptionFormState extends ConsumerState<InscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _mdpConfirmCtrl = TextEditingController();
  final _parrainCtrl = TextEditingController();
  bool _mdpVisible = false;
  String? _parrainPrenom;   // prénom du parrain si le code est valide
  bool _verifCode = false;
  bool _cguAcceptees = false;

  @override
  void dispose() {
    for (final c in [_prenomCtrl, _nomCtrl, _emailCtrl, _telCtrl, _mdpCtrl, _mdpConfirmCtrl, _parrainCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _verifierCode(String valeur) async {
    final code = valeur.trim().toUpperCase();
    if (code.length < 8) {
      if (_parrainPrenom != null) setState(() => _parrainPrenom = null);
      return;
    }
    setState(() => _verifCode = true);
    final prenom = await ref.read(authServiceProvider).verifierCodeParrainage(code);
    if (!mounted || _parrainCtrl.text.trim().toUpperCase() != code) return;
    setState(() { _verifCode = false; _parrainPrenom = prenom; });
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_cguAcceptees) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Veuillez accepter les conditions d'utilisation"),
        backgroundColor: TamBourColors.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    final ok = await ref.read(authProvider.notifier).inscrire(
      prenom: _prenomCtrl.text.trim(), nom: _nomCtrl.text.trim(),
      email: _emailCtrl.text.trim(), telephone: _telCtrl.text.trim(),
      motDePasse: _mdpCtrl.text,
      codeParrainage: _parrainCtrl.text.trim().toUpperCase());
    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Créer un compte', style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: TamBourColors.textPrimary)).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          const Text('Rejoignez des milliers de voyageurs ivoiriens.', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)).animate().fadeIn(delay: 60.ms),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: AuthField(controller: _prenomCtrl, label: 'Prénom', hint: 'Kouassi',
              icone: Icons.person_outline_rounded, textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().length < 2 ? 'Requis' : null)),
            const SizedBox(width: 12),
            Expanded(child: AuthField(controller: _nomCtrl, label: 'Nom', hint: 'Adjoumani',
              icone: Icons.badge_outlined, textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().length < 2 ? 'Requis' : null)),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),
          AuthField(controller: _emailCtrl, label: 'Adresse email', hint: 'exemple@email.com',
            icone: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
            validator: (v) { if (v == null || v.trim().isEmpty) return "L'email est requis"; if (!v.contains('@')) return 'Email invalide'; return null; }).animate().fadeIn(delay: 140.ms),
          const SizedBox(height: 14),
          _ChampTelephone(controller: _telCtrl).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 14),
          AuthField(controller: _mdpCtrl, label: 'Mot de passe', hint: 'Minimum 8 caractères',
            icone: Icons.lock_outline_rounded, obscureText: !_mdpVisible,
            suffixIcon: IconButton(icon: Icon(_mdpVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: TamBourColors.textHint, size: 20), onPressed: () => setState(() => _mdpVisible = !_mdpVisible)),
            validator: (v) { if (v == null || v.isEmpty) return 'Mot de passe requis'; if (v.length < 8) return 'Minimum 8 caractères'; return null; }).animate().fadeIn(delay: 220.ms),
          const SizedBox(height: 14),
          AuthField(controller: _mdpConfirmCtrl, label: 'Confirmer le mot de passe', hint: '••••••••',
            icone: Icons.lock_outline_rounded, obscureText: !_mdpVisible,
            suffixIcon: IconButton(icon: Icon(_mdpVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: TamBourColors.textHint, size: 20), onPressed: () => setState(() => _mdpVisible = !_mdpVisible)),
            validator: (v) => v != _mdpCtrl.text ? 'Les mots de passe ne correspondent pas' : null).animate().fadeIn(delay: 260.ms),
          const SizedBox(height: 14),
          _ChampParrainage(
            controller: _parrainCtrl, onChanged: _verifierCode,
            verification: _verifCode, parrainPrenom: _parrainPrenom).animate().fadeIn(delay: 280.ms),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _cguAcceptees = !_cguAcceptees),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(color: _cguAcceptees ? TamBourColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: _cguAcceptees ? TamBourColors.primary : TamBourColors.border, width: 1.5)),
                child: _cguAcceptees ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null),
              const SizedBox(width: 10),
              Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textSecondary), children: [
                const TextSpan(text: "J'accepte les "),
                const TextSpan(text: "conditions d'utilisation", style: TextStyle(color: TamBourColors.primary, fontWeight: FontWeight.w600)),
                const TextSpan(text: ' et la '),
                const TextSpan(text: 'politique de confidentialité', style: TextStyle(color: TamBourColors.primary, fontWeight: FontWeight.w600)),
              ]))),
            ])).animate().fadeIn(delay: 300.ms),
          if (authState.erreur != null) ...[
            const SizedBox(height: 14),
            ErreurBanner(message: authState.erreur!).animate().fadeIn().shakeX(hz: 4, amount: 4),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: authState.estChargement ? null : _inscrire,
              style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: TamBourColors.border, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: authState.estChargement
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Créer mon compte', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)))).animate().fadeIn(delay: 340.ms),
        ]),
      ),
    );
  }
}

class _ChampTelephone extends StatelessWidget {
  final TextEditingController controller;
  const _ChampTelephone({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Téléphone', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textPrimary, fontWeight: FontWeight.w500),
        validator: (v) { if (v == null || v.trim().isEmpty) return 'Le téléphone est requis'; if (v.trim().length < 10) return 'Numéro à 10 chiffres'; return null; },
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 0, 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🇨🇮', style: TextStyle(fontSize: 16)), SizedBox(width: 5),
              Text('+225', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: TamBourColors.primary)),
            ])),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: '07 00 00 00 00',
          filled: true, fillColor: TamBourColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textHint),
          errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error))),
    ]);
  }
}

/// Code de parrainage facultatif : le parrain et le nouvel inscrit gagnent des points.
class _ChampParrainage extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool verification;
  final String? parrainPrenom;
  const _ChampParrainage({required this.controller, required this.onChanged,
    required this.verification, required this.parrainPrenom});

  @override
  Widget build(BuildContext context) {
    final code = controller.text.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Code de parrainage (facultatif)', style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
        fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, onChanged: onChanged,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), LengthLimitingTextInputFormatter(12)],
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, letterSpacing: 1.5,
          color: TamBourColors.textPrimary, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Ex : TB7K2QX9',
          prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.card_giftcard_rounded, size: 18, color: TamBourColors.gold)),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon: verification
            ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: TamBourColors.primary)))
            : parrainPrenom != null
              ? const Icon(Icons.check_circle_rounded, color: TamBourColors.success, size: 20)
              : null,
          filled: true, fillColor: TamBourColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, letterSpacing: 0, color: TamBourColors.textHint)),
      ),
      const SizedBox(height: 6),
      Text(
        parrainPrenom != null
          ? 'Parrainé par $parrainPrenom : vous recevrez des points de bienvenue 🎁'
          : code.length >= 8 && !verification
            ? 'Code introuvable : vérifiez-le ou laissez ce champ vide.'
            : 'Un ami vous a invité ? Saisissez son code pour gagner des points.',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
          color: parrainPrenom != null ? TamBourColors.success
            : code.length >= 8 && !verification ? TamBourColors.error : TamBourColors.textHint)),
    ]);
  }
}
