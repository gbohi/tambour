import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/support.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import '../../services/support_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/champ_formulaire.dart';
import '../../widgets/page_header.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});
  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sujetCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    for (final c in [_sujetCtrl, _messageCtrl, _nomCtrl, _emailCtrl, _telCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _ouvrir(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) AppSnackbar.erreur(context, "Impossible d'ouvrir ce lien sur cet appareil.");
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final msg = await ref.read(supportServiceProvider).envoyerMessage(
        sujet: _sujetCtrl.text.trim(), message: _messageCtrl.text.trim(),
        nom: _nomCtrl.text.trim(), email: _emailCtrl.text.trim(), telephone: _telCtrl.text.trim());
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
    final connecte = ref.watch(authProvider).estConnecte;
    final infos = ref.watch(infosContactProvider).valueOrNull ?? InfosContact.parDefaut;
    final whatsapp = infos.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        const PageHeader(titre: 'Contacter le support', sousTitre: 'Notre équipe vous répond rapidement'),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Canal(icone: Icons.call_rounded, label: 'Appeler', couleur: TamBourColors.primary,
                onTap: () => _ouvrir(Uri(scheme: 'tel', path: infos.telephone.replaceAll(' ', '')))),
              const SizedBox(width: 10),
              _Canal(icone: Icons.chat_rounded, label: 'WhatsApp', couleur: const Color(0xFF25D366),
                onTap: () => _ouvrir(Uri.parse('https://wa.me/$whatsapp'))),
              const SizedBox(width: 10),
              _Canal(icone: Icons.email_rounded, label: 'Email', couleur: TamBourColors.gold,
                onTap: () => _ouvrir(Uri(scheme: 'mailto', path: infos.email,
                  queryParameters: {'subject': 'Support TamBour'}))),
            ]).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 16, color: TamBourColors.textHint),
              const SizedBox(width: 6),
              Expanded(child: Text('${infos.horaires} · ${infos.telephone}', style: const TextStyle(
                fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary))),
            ]),
            const SizedBox(height: 24),
            const Text('Ou écrivez-nous', style: TextStyle(fontFamily: 'Outfit', fontSize: 17,
              fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
            const SizedBox(height: 14),
            if (!connecte) ...[
              ChampFormulaire(controller: _nomCtrl, label: 'Nom complet', icone: Icons.person_outline_rounded,
                majuscules: TextCapitalization.words,
                validator: (v) => (v ?? '').trim().length < 2 ? 'Nom requis' : null),
              const SizedBox(height: 12),
              ChampFormulaire(controller: _emailCtrl, label: 'Email', icone: Icons.email_outlined,
                clavier: TextInputType.emailAddress, majuscules: TextCapitalization.none),
              const SizedBox(height: 12),
              ChampFormulaire(controller: _telCtrl, label: 'Téléphone', icone: Icons.phone_outlined,
                clavier: TextInputType.phone,
                validator: (v) => (v ?? '').trim().isEmpty && _emailCtrl.text.trim().isEmpty
                  ? 'Indiquez un email ou un téléphone' : null),
              const SizedBox(height: 12),
            ],
            ChampFormulaire(controller: _sujetCtrl, label: 'Sujet', hint: 'Ex : modifier ma réservation',
              icone: Icons.subject_rounded, longueurMax: 200,
              validator: (v) => (v ?? '').trim().length < 3 ? 'Sujet requis' : null),
            const SizedBox(height: 4),
            ChampFormulaire(controller: _messageCtrl, label: 'Message', lignes: 6,
              hint: 'Décrivez votre demande…',
              validator: (v) => (v ?? '').trim().length < 10 ? 'Message trop court (10 caractères min.)' : null),
            const SizedBox(height: 20),
            AppButton(label: 'Envoyer le message', icon: Icons.send_rounded, isLoading: _envoi, onPressed: _envoyer),
          ])),
        )),
      ]),
    );
  }
}

class _Canal extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;
  final VoidCallback onTap;
  const _Canal({required this.icone, required this.label, required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Column(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: couleur.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icone, color: couleur, size: 22)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
          fontWeight: FontWeight.w600, color: TamBourColors.textPrimary)),
      ]),
    ),
  ));
}
