import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/passager.dart';
import 'package:tambour_passager/models/trajet.dart';
import 'package:tambour_passager/providers/passager_provider.dart';
import 'package:tambour_passager/providers/recherche_provider.dart';
import 'package:tambour_passager/screens/paiement/paiement_screen.dart';

class PassagersScreen extends ConsumerStatefulWidget {
  final Trajet trajet;
  final RechercheParams params;
  const PassagersScreen({super.key, required this.trajet, required this.params});
  @override
  ConsumerState<PassagersScreen> createState() => _PassagersScreenState();
}

class _PassagersScreenState extends ConsumerState<PassagersScreen> {
  late final List<PassagerForm> _forms;
  late final int _nb;
  late final PageController _pageController;
  int _pageActuelle = 0;

  @override
  void initState() {
    super.initState();
    // Les sièges sont attribués automatiquement une fois le paiement validé
    _nb = widget.params.nbPassagers;
    _forms = List.generate(_nb, (_) => PassagerForm());
    _pageController = PageController();
    Future.microtask(
      () => ref.read(passagerProvider.notifier).initialiser(_nb));
  }

  @override
  void dispose() {
    for (final f in _forms) f.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _pageSuivante() {
    if (!_forms[_pageActuelle].formKey.currentState!.validate()) return;
    _sauvegarder(_pageActuelle);
    if (_pageActuelle < _forms.length - 1) {
      setState(() => _pageActuelle++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      ref.read(passagerProvider.notifier).setIndexActif(_pageActuelle);
    } else {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => PaiementScreen(
          trajet: widget.trajet, params: widget.params)));
    }
  }

  void _sauvegarder(int index) {
    final f = _forms[index];
    ref.read(passagerProvider.notifier).mettreAJour(index, Passager(
      prenom:    f.prenomCtrl.text.trim(),
      nom:       f.nomCtrl.text.trim(),
      telephone: f.telephoneCtrl.text.trim(),
      email:     f.emailCtrl.text.trim(),
      siegeId:   '',
    ));
    // Le premier passager (index 0) = le payeur
    if (index == 0 && f.emailCtrl.text.trim().isNotEmpty) {
      ref.read(passagerProvider.notifier).setEmailPayeur(f.emailCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        _Header(
          nbPassagers: _nb,
          page: _pageActuelle,
          onBack: () {
            if (_pageActuelle > 0) {
              setState(() => _pageActuelle--);
              _pageController.previousPage(
                duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
            } else {
              Navigator.pop(context);
            }
          }),
        if (_nb > 1) _StepBar(total: _nb, actif: _pageActuelle),
        _RecapTrajet(trajet: widget.trajet),
        Expanded(child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _nb,
          itemBuilder: (_, i) => _FormPage(
            index: i,
            form: _forms[i], nbTotal: _nb,
            estPremier: i == 0,
          ))),
        _Bottom(
          page: _pageActuelle, nbTotal: _nb, onSuivant: _pageSuivante),
      ]),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int nbPassagers, page;
  final VoidCallback onBack;
  const _Header({required this.nbPassagers, required this.page, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
            onPressed: onBack),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Informations passagers', style: TextStyle(
              fontFamily: 'Outfit', fontSize: 18,
              fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Passager ${page + 1} sur $nbPassagers', style: TextStyle(
              fontFamily: 'Outfit', fontSize: 13,
              color: Colors.white.withOpacity(0.8))),
          ])),
        ]),
      )),
    );
  }
}

// ── Step bar ─────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int total, actif;
  const _StepBar({required this.total, required this.actif});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(total, (i) => Expanded(child: Row(children: [
          Expanded(child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), height: 4,
            decoration: BoxDecoration(
              color: i <= actif ? TamBourColors.primary : TamBourColors.border,
              borderRadius: BorderRadius.circular(2)))),
          if (i < total - 1) const SizedBox(width: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == actif ? 26 : 20,
            height: i == actif ? 26 : 20,
            decoration: BoxDecoration(
              color: i < actif ? TamBourColors.primary
                : i == actif ? TamBourColors.primary
                : TamBourColors.border,
              shape: BoxShape.circle),
            child: Center(child: i < actif
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
              : Text('${i + 1}', style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: i == actif ? 11 : 9,
                  fontWeight: FontWeight.w700,
                  color: i == actif ? Colors.white : TamBourColors.textHint)))),
          if (i < total - 1) const SizedBox(width: 4),
        ]))),
      ),
    );
  }
}

// ── Recap trajet ──────────────────────────────────────────────────────────────

class _RecapTrajet extends StatelessWidget {
  final Trajet trajet;
  const _RecapTrajet({required this.trajet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TamBourColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TamBourColors.primary.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: TamBourColors.primary, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trajet.depart.nom, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 13,
              fontWeight: FontWeight.w700, color: TamBourColors.primaryDark)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded, size: 12, color: TamBourColors.primary)),
            Text(trajet.arrivee.nom, style: const TextStyle(
              fontFamily: 'Outfit', fontSize: 13,
              fontWeight: FontWeight.w700, color: TamBourColors.primaryDark)),
          ]),
          Text('${DateFormat('HH:mm').format(trajet.heureDepart)} · ${trajet.compagnie}',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.primary)),
        ]),
      ]),
    );
  }
}

// ── Formulaire passager ───────────────────────────────────────────────────────

class _FormPage extends StatefulWidget {
  final int index, nbTotal;
  final PassagerForm form;
  final bool estPremier;  // Premier passager = le payeur, reçoit tous les billets
  const _FormPage({required this.index,
    required this.form, required this.nbTotal, required this.estPremier});
  @override
  State<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<_FormPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: widget.form.formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── En-tête passager ──────────────────────────────────────────
          Row(children: [
            Container(width: 44, height: 44,
              decoration: const BoxDecoration(
                color: TamBourColors.primary, shape: BoxShape.circle),
              child: Center(child: Text('${widget.index + 1}', style: const TextStyle(
                fontFamily: 'Outfit', fontSize: 18,
                fontWeight: FontWeight.w800, color: Colors.white)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.nbTotal > 1
                  ? 'Passager ${widget.index + 1} sur ${widget.nbTotal}'
                  : 'Informations du passager',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
                  fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
              const SizedBox(height: 3),
              const Text('Siège attribué après le paiement', style: TextStyle(
                fontFamily: 'Outfit', fontSize: 12,
                color: TamBourColors.primary, fontWeight: FontWeight.w500)),
            ])),
          ]).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // ── Champs obligatoires ───────────────────────────────────────
          _field('Prénom *', 'Ex: Kouassi', Icons.person_outline_rounded,
            widget.form.prenomCtrl,
            (v) => v == null || v.trim().length < 2 ? 'Prénom requis' : null,
            TextCapitalization.words),
          const SizedBox(height: 12),

          _field('Nom de famille *', 'Ex: Adjoumani', Icons.person_outline_rounded,
            widget.form.nomCtrl,
            (v) => v == null || v.trim().length < 2 ? 'Nom requis' : null,
            TextCapitalization.words),
          const SizedBox(height: 12),

          _telField(),
          const SizedBox(height: 12),

          // ── Email facultatif ──────────────────────────────────────────
          _emailField(),

          // Bandeau info payeur (1er passager)
          if (widget.estPremier && widget.nbTotal > 1) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TamBourColors.goldLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TamBourColors.gold.withOpacity(0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded,
                  size: 16, color: TamBourColors.gold),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'En tant que 1er passager, vous recevrez tous les billets '
                  '(${widget.nbTotal} billets) sur votre email si renseigné.',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    color: Color(0xFF7A4F00), height: 1.4))),
              ])),
          ],

          const SizedBox(height: 14),

          // ── Mention protection données ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TamBourColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: TamBourColors.textHint),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Vos informations sont protégées et utilisées uniquement pour ce voyage.',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                  color: TamBourColors.textSecondary, height: 1.4))),
            ])),
        ]),
      ),
    );
  }

  // ── Champ texte générique ─────────────────────────────────────────────────
  Widget _field(
    String label, String hint, IconData icon,
    TextEditingController ctrl, String? Function(String?) validator,
    TextCapitalization cap, [List<TextInputFormatter>? formatters]) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
        fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, validator: validator,
        textCapitalization: cap, inputFormatters: formatters,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
          color: TamBourColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: _deco(hint, icon)),
    ]);
  }

  // ── Champ téléphone ───────────────────────────────────────────────────────
  Widget _telField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Téléphone *', style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
        fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.form.telephoneCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10)],
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
          color: TamBourColors.textPrimary, fontWeight: FontWeight.w500),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Téléphone requis';
          if (v.trim().length < 10) return 'Numéro à 10 chiffres';
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 0, 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: TamBourColors.primaryLight,
              borderRadius: BorderRadius.circular(7)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🇨🇮', style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
              Text('+225', style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                fontWeight: FontWeight.w700, color: TamBourColors.primary)),
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

  // ── Champ email facultatif ────────────────────────────────────────────────
  Widget _emailField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Email', style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
          fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: TamBourColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6)),
          child: const Text('Facultatif', style: TextStyle(
            fontFamily: 'Outfit', fontSize: 10,
            fontWeight: FontWeight.w600, color: TamBourColors.textHint))),
      ]),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.form.emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
          color: TamBourColors.textPrimary, fontWeight: FontWeight.w500),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null; // facultatif
          if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim()))
            return 'Email invalide';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'ex: kouassi@email.com (envoi du billet)',
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.email_outlined, size: 16, color: TamBourColors.textHint)),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          filled: true, fillColor: TamBourColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textHint),
          errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error))),
    ]);
  }

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(icon, size: 16, color: TamBourColors.textHint)),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    filled: true, fillColor: TamBourColors.surfaceVariant,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textHint),
    errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error));
}

// ── Bouton bas ────────────────────────────────────────────────────────────────

class _Bottom extends StatelessWidget {
  final int page, nbTotal;
  final VoidCallback onSuivant;
  const _Bottom({required this.page, required this.nbTotal, required this.onSuivant});
  bool get _estDerniere => page == nbTotal - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TamBourColors.surface,
        border: Border(top: BorderSide(color: TamBourColors.border, width: 0.5))),
      child: SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: onSuivant,
            icon: Icon(_estDerniere
              ? Icons.payment_rounded
              : Icons.arrow_forward_rounded, size: 20),
            label: Text(_estDerniere
              ? 'Continuer vers le paiement'
              : 'Passager suivant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TamBourColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(fontFamily: 'Outfit',
                fontSize: 16, fontWeight: FontWeight.w700)))))),
    );
  }
}
