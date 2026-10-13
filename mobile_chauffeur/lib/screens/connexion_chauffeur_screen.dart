import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/providers/auth_provider.dart';
import 'package:tambour_commun/widgets/auth_field.dart';

/// Connexion de l'application TamBour Pro. Pas d'inscription : les comptes chauffeurs
/// sont créés par la compagnie depuis le back-office.
class ConnexionChauffeurScreen extends ConsumerStatefulWidget {
  const ConnexionChauffeurScreen({super.key});
  @override
  ConsumerState<ConnexionChauffeurScreen> createState() => _ConnexionChauffeurScreenState();
}

class _ConnexionChauffeurScreenState extends ConsumerState<ConnexionChauffeurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _mdpVisible = false;

  @override
  void dispose() { _emailCtrl.dispose(); _mdpCtrl.dispose(); super.dispose(); }

  Future<void> _connexion() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(email: _emailCtrl.text.trim(), motDePasse: _mdpCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: TamBourColors.marque,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 48),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/logo_symbole_clair.png', package: 'tambour_commun', height: 84, semanticLabel: 'TamBour'),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('TamBour', style: TextStyle(fontFamily: 'Outfit', fontSize: 30,
                  fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: TamBourColors.gold, borderRadius: BorderRadius.circular(20)),
                  child: const Text('PRO', style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
                    fontWeight: FontWeight.w900, color: TamBourColors.marque))),
              ]),
              const SizedBox(height: 6),
              Text('Espace chauffeur', style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                color: Colors.white.withValues(alpha: 0.75))),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(22)),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Connexion', style: TextStyle(fontFamily: 'Outfit', fontSize: 20,
                      fontWeight: FontWeight.w800, color: TamBourColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Vos trajets, vos passagers et le contrôle des billets.',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textSecondary)),
                    const SizedBox(height: 18),
                    AuthField(controller: _emailCtrl, label: 'Adresse email', hint: 'chauffeur@compagnie.ci',
                      icone: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "L'email est requis";
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      }),
                    const SizedBox(height: 12),
                    AuthField(controller: _mdpCtrl, label: 'Mot de passe', hint: '••••••••',
                      icone: Icons.lock_outline_rounded, obscureText: !_mdpVisible,
                      suffixIcon: IconButton(
                        icon: Icon(_mdpVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: TamBourColors.textHint, size: 20),
                        onPressed: () => setState(() => _mdpVisible = !_mdpVisible)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Le mot de passe est requis' : null),
                    if (auth.erreur != null) ...[
                      const SizedBox(height: 12),
                      ErreurBanner(message: auth.erreur!),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(height: 52, child: ElevatedButton(
                      onPressed: auth.estChargement ? null : _connexion,
                      style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.marque,
                        foregroundColor: Colors.white, disabledBackgroundColor: TamBourColors.border, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: auth.estChargement
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Se connecter', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)))),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 18, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  "Votre compte est créé par votre compagnie. Identifiants perdus ? Contactez votre responsable d'exploitation.",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12.5, height: 1.4, color: Colors.white.withValues(alpha: 0.7)))),
              ]),
            ]),
          ),
        )),
      ),
    );
  }
}
