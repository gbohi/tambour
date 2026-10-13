import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/providers/auth_provider.dart';
import 'package:tambour_commun/widgets/auth_field.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});
  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _mdpVisible = false;

  @override
  void dispose() { _emailCtrl.dispose(); _mdpCtrl.dispose(); super.dispose(); }

  Future<void> _connexion() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(email: _emailCtrl.text.trim(), motDePasse: _mdpCtrl.text);
    if (ok && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bon retour !', style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: TamBourColors.textPrimary)).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          const Text('Connectez-vous pour accéder à vos billets.', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 28),
          AuthField(controller: _emailCtrl, label: 'Adresse email', hint: 'exemple@email.com',
            icone: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
            validator: (v) { if (v == null || v.trim().isEmpty) return "L'email est requis"; if (!v.contains('@')) return 'Email invalide'; return null; }).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 14),
          AuthField(controller: _mdpCtrl, label: 'Mot de passe', hint: '••••••••',
            icone: Icons.lock_outline_rounded, obscureText: !_mdpVisible,
            suffixIcon: IconButton(icon: Icon(_mdpVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: TamBourColors.textHint, size: 20), onPressed: () => setState(() => _mdpVisible = !_mdpVisible)),
            validator: (v) { if (v == null || v.isEmpty) return 'Le mot de passe est requis'; return null; }).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight,
            child: const Text('Mot de passe oublié ?', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: TamBourColors.primary))).animate().fadeIn(delay: 200.ms),
          if (authState.erreur != null) ...[
            const SizedBox(height: 14),
            ErreurBanner(message: authState.erreur!).animate().fadeIn(duration: 250.ms).shakeX(hz: 4, amount: 4),
          ],
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: authState.estChargement ? null : _connexion,
              style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: TamBourColors.border, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: authState.estChargement
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Se connecter', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)))).animate().fadeIn(delay: 240.ms),
          const SizedBox(height: 24),
          const DividerOu(),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {},
            child: Container(width: double.infinity, height: 54,
              decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: TamBourColors.border)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.phone_android_rounded, color: TamBourColors.primary, size: 22),
                SizedBox(width: 10),
                Text('Continuer avec un numéro', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600, color: TamBourColors.textPrimary)),
              ]))).animate().fadeIn(delay: 320.ms),
        ]),
      ),
    );
  }
}
