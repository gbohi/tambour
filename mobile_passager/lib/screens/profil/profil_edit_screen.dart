import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/providers/auth_provider.dart';

class ProfilEditScreen extends ConsumerStatefulWidget {
  const ProfilEditScreen({super.key});

  @override
  ConsumerState<ProfilEditScreen> createState() => _ProfilEditScreenState();
}

class _ProfilEditScreenState extends ConsumerState<ProfilEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telCtrl;
  bool _modifications = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _prenomCtrl = TextEditingController(text: user?.prenom ?? '');
    _nomCtrl = TextEditingController(text: user?.nom ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _telCtrl = TextEditingController(text: user?.telephone ?? '');

    for (final ctrl in [_prenomCtrl, _nomCtrl, _emailCtrl, _telCtrl]) {
      ctrl.addListener(_detecterModifications);
    }
  }

  void _detecterModifications() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final modifie = _prenomCtrl.text.trim() != user.prenom ||
        _nomCtrl.text.trim() != user.nom ||
        _emailCtrl.text.trim() != user.email ||
        _telCtrl.text.trim() != user.telephone;
    if (modifie != _modifications) setState(() => _modifications = modifie);
  }

  @override
  void dispose() {
    for (final c in [_prenomCtrl, _nomCtrl, _emailCtrl, _telCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).mettreAJourProfil({
      'prenom': _prenomCtrl.text.trim(),
      'nom': _nomCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
    });
    if (ok && mounted) {
      setState(() => _modifications = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profil mis à jour avec succès',
            style: TextStyle(fontFamily: 'Outfit')),
        backgroundColor: TamBourColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(
        children: [
          _Header(
            estChargement: authState.estChargement,
            aModifications: _modifications,
            onSauvegarder: _sauvegarder,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              color: TamBourColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: TamBourColors.primary.withOpacity(0.2), width: 3),
                            ),
                            child: Center(
                              child: Text(
                                user?.initiales ?? 'TB',
                                style: const TextStyle(fontFamily: 'Outfit', fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: TamBourColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 28),

                    _SectionLabel(icon: Icons.person_rounded, label: 'Informations personnelles'),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(child: _ProfilField(controller: _prenomCtrl, label: 'Prénom', icone: Icons.badge_outlined, textCapitalization: TextCapitalization.words, validator: (v) => v == null || v.trim().length < 2 ? 'Requis' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _ProfilField(controller: _nomCtrl, label: 'Nom', icone: Icons.badge_outlined, textCapitalization: TextCapitalization.words, validator: (v) => v == null || v.trim().length < 2 ? 'Requis' : null)),
                      ],
                    ).animate().fadeIn(delay: 80.ms),

                    const SizedBox(height: 14),

                    _ProfilField(
                      controller: _emailCtrl, label: 'Adresse email',
                      icone: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                      validator: (v) { if (v == null || v.trim().isEmpty) return 'Email requis'; if (!v.contains('@')) return 'Email invalide'; return null; },
                    ).animate().fadeIn(delay: 120.ms),

                    const SizedBox(height: 14),

                    _TelField(controller: _telCtrl).animate().fadeIn(delay: 160.ms),

                    const SizedBox(height: 28),

                    _SectionLabel(icon: Icons.lock_outline_rounded, label: 'Sécurité'),
                    const SizedBox(height: 14),

                    _BoutonAction(icon: Icons.password_rounded, label: 'Changer le mot de passe',
                      onTap: () => _showChangeMdp(context)).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    _BoutonAction(icon: Icons.phone_android_rounded, label: 'Vérification en deux étapes',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Activé', style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: TamBourColors.primary)),
                      ),
                      onTap: () {}).animate().fadeIn(delay: 240.ms),

                    const SizedBox(height: 28),

                    _SectionLabel(icon: Icons.notifications_rounded, label: 'Préférences'),
                    const SizedBox(height: 14),

                    _Toggle(icon: Icons.sms_rounded, label: 'Notifications SMS', valeur: true, onChanged: (_) {}).animate().fadeIn(delay: 280.ms),
                    const SizedBox(height: 8),
                    _Toggle(icon: Icons.local_offer_rounded, label: 'Offres et promotions', valeur: true, onChanged: (_) {}).animate().fadeIn(delay: 320.ms),
                    const SizedBox(height: 8),
                    _Toggle(icon: Icons.alarm_rounded, label: 'Rappels de voyage', valeur: true, onChanged: (_) {}).animate().fadeIn(delay: 360.ms),

                    const SizedBox(height: 28),

                    _ZoneDanger().animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeMdp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeMdpSheet(),
    );
  }
}

class _Header extends StatelessWidget {
  final bool estChargement, aModifications;
  final VoidCallback onSauvegarder;

  const _Header({required this.estChargement, required this.aModifications, required this.onSauvegarder});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
              const Expanded(child: Text('Mon profil', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
              AnimatedOpacity(
                opacity: aModifications ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: aModifications ? onSauvegarder : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: aModifications ? TamBourColors.gold : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: estChargement
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enregistrer', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: TamBourColors.primary, size: 16)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
    ]);
  }
}

class _ProfilField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icone;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _ProfilField({required this.controller, required this.label, required this.icone, this.validator, this.keyboardType, this.textCapitalization = TextCapitalization.none});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, validator: validator, keyboardType: keyboardType, textCapitalization: textCapitalization,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Icon(icone, size: 18, color: TamBourColors.textHint)),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          filled: true, fillColor: TamBourColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error))),
    ]);
  }
}

class _TelField extends StatelessWidget {
  final TextEditingController controller;
  const _TelField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Téléphone', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textPrimary, fontWeight: FontWeight.w500),
        validator: (v) { if (v == null || v.trim().isEmpty) return 'Téléphone requis'; if (v.trim().length < 10) return 'Numéro à 10 chiffres'; return null; },
        decoration: InputDecoration(
          prefixIcon: Container(margin: const EdgeInsets.fromLTRB(12,8,0,8), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('🇨🇮', style: TextStyle(fontSize: 16)), SizedBox(width: 5), Text('+225', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: TamBourColors.primary))])),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: TamBourColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error))),
    ]);
  }
}

class _BoutonAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Widget? trailing;
  const _BoutonAction({required this.icon, required this.label, required this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TamBourColors.border, width: 0.5)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: TamBourColors.primary, size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500, color: TamBourColors.textPrimary))),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          const Icon(Icons.chevron_right_rounded, color: TamBourColors.textHint, size: 20),
        ]),
      ),
    );
  }
}

class _Toggle extends StatefulWidget {
  final IconData icon; final String label; final bool valeur; final ValueChanged<bool> onChanged;
  const _Toggle({required this.icon, required this.label, required this.valeur, required this.onChanged});
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  late bool _val;
  @override
  void initState() { super.initState(); _val = widget.valeur; }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(9)), child: Icon(widget.icon, color: TamBourColors.primary, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500, color: TamBourColors.textPrimary))),
        Switch(value: _val, onChanged: (v) { setState(() => _val = v); widget.onChanged(v); }, activeColor: TamBourColors.primary, activeTrackColor: TamBourColors.primary.withOpacity(0.3)),
      ]),
    );
  }
}

class _ZoneDanger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TamBourColors.error.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: TamBourColors.error.withOpacity(0.2), width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Zone de danger', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: TamBourColors.error)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Supprimer le compte ?', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800)),
            content: const Text('Cette action est irréversible. Tous vos billets seront supprimés.', style: TextStyle(fontFamily: 'Outfit', color: TamBourColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(fontFamily: 'Outfit', color: TamBourColors.textSecondary))),
              ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Supprimer', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700))),
            ],
          )),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: TamBourColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: TamBourColors.error.withOpacity(0.3), width: 0.5)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delete_outline_rounded, color: TamBourColors.error, size: 18),
              SizedBox(width: 8),
              Text('Supprimer mon compte', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.error)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ChangeMdpSheet extends StatefulWidget {
  @override
  State<_ChangeMdpSheet> createState() => _ChangeMdpSheetState();
}

class _ChangeMdpSheetState extends State<_ChangeMdpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _actuelCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _visible = false;

  @override
  void dispose() { _actuelCtrl.dispose(); _nouveauCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: TamBourColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Changer le mot de passe', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: TamBourColors.textPrimary)),
            const SizedBox(height: 20),
            _MdpField(controller: _actuelCtrl, label: 'Mot de passe actuel', visible: _visible, onToggle: () => setState(() => _visible = !_visible), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),
            _MdpField(controller: _nouveauCtrl, label: 'Nouveau mot de passe', visible: _visible, onToggle: () => setState(() => _visible = !_visible), validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (v.length < 8) return 'Minimum 8 caractères'; return null; }),
            const SizedBox(height: 12),
            _MdpField(controller: _confirmCtrl, label: 'Confirmer', visible: _visible, onToggle: () => setState(() => _visible = !_visible), validator: (v) => v != _nouveauCtrl.text ? 'Ne correspond pas' : null),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)),
              child: const Text('Modifier le mot de passe'))),
          ]),
        ),
      ),
    );
  }
}

class _MdpField extends StatelessWidget {
  final TextEditingController controller; final String label; final bool visible; final VoidCallback onToggle; final String? Function(String?) validator;
  const _MdpField({required this.controller, required this.label, required this.visible, required this.onToggle, required this.validator});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, obscureText: !visible, validator: validator,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textPrimary),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textSecondary),
        suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: TamBourColors.textHint, size: 20), onPressed: onToggle),
        filled: true, fillColor: TamBourColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error)),
    );
  }
}
