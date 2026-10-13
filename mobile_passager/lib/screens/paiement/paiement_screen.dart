import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/paiement.dart';
import 'package:tambour_passager/models/trajet.dart';
import 'package:tambour_passager/providers/paiement_provider.dart';
import 'package:tambour_passager/providers/passager_provider.dart';
import 'package:tambour_passager/providers/recherche_provider.dart';
import 'package:tambour_passager/screens/billet/billet_screen.dart';

class PaiementScreen extends ConsumerStatefulWidget {
  final Trajet trajet;
  final RechercheParams params;
  const PaiementScreen({super.key, required this.trajet, required this.params});
  @override
  ConsumerState<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends ConsumerState<PaiementScreen> {
  final _telCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _telCtrl.addListener(() => ref.read(paiementProvider.notifier).setTelephone(_telCtrl.text.trim()));
  }

  @override
  void dispose() { _telCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _payer() async {
    if (!_formKey.currentState!.validate()) return;
    final state = ref.read(paiementProvider);
    if (state.methodeSelectionnee == null) { _snack('Choisissez un moyen de paiement', true); return; }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => ref.read(paiementProvider.notifier).tickTimer());
    await ref.read(paiementProvider.notifier).initierPaiement(PaiementRequest(
      trajetId: widget.trajet.id,
      montantFcfa: widget.trajet.prixFcfa * widget.params.nbPassagers,
      methode: state.methodeSelectionnee!, telephone: state.telephone));
    _timer?.cancel();
    final ns = ref.read(paiementProvider);
    if (ns.statut == StatutPaiement.succes && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BilletScreen(trajet: widget.trajet, params: widget.params, result: ns.result!)));
    }
  }

  void _snack(String msg, bool isErr) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontFamily: 'Outfit')),
    backgroundColor: isErr ? TamBourColors.error : TamBourColors.primary,
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paiementProvider);
    final total = widget.trajet.prixFcfa * widget.params.nbPassagers;
    final fmt = NumberFormat('#,###', 'fr_FR');
    if (state.statut == StatutPaiement.expire) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { Navigator.pop(context); _snack('Session expirée. Recommencez.', true); } });
    }
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        _Header(onBack: () => Navigator.pop(context)),
        Expanded(child: state.statut == StatutPaiement.enCours
          ? _EnCours(methode: state.methodeSelectionnee!, telephone: state.telephone, montant: total, secondes: state.secondesRestantes)
          : SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _RecapCard(trajet: widget.trajet, params: widget.params, total: total).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),
              const Text('Choisissez votre moyen de paiement', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
              const SizedBox(height: 14),
              // Mobile Money uniquement dans l'app (la carte reste disponible sur le site web)
              ...MethodePaiement.values.where((m) => m.logo != null).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MethodeCard(methode: m, selected: state.methodeSelectionnee == m,
                  onTap: () => ref.read(paiementProvider.notifier).selectionnerMethode(m)))),
              if (state.methodeSelectionnee != null) ...[
                const SizedBox(height: 14),
                _TelField(controller: _telCtrl, methode: state.methodeSelectionnee!),
              ],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 58, child: ElevatedButton(
                onPressed: state.peutPayer ? _payer : null,
                style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: TamBourColors.border, disabledForegroundColor: TamBourColors.textHint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_rounded, size: 18), const SizedBox(width: 10),
                  Text('Payer ${fmt.format(total)} FCFA', style: const TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w800)),
                ]))),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _SecItem(icon: Icons.lock_rounded, label: 'SSL 256-bit'),
                _SecItem(icon: Icons.verified_rounded, label: 'CinetPay'),
                _SecItem(icon: Icons.replay_rounded, label: 'Remboursement'),
              ])),
            ])))),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(color: TamBourColors.primary, child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: onBack),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Paiement sécurisé', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: 4),
          Row(children: [Icon(Icons.lock_rounded, color: Colors.white60, size: 12), SizedBox(width: 4), Text('Connexion chiffrée SSL', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white60))]),
        ])),
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20)),
      ]))));
  }
}

class _RecapCard extends ConsumerWidget {
  final Trajet trajet; final RechercheParams params; final int total;
  const _RecapCard({required this.trajet, required this.params, required this.total});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final sieges = ref.watch(passagerProvider).passagers.map((p) => p.siegeId).toList();
    return Container(decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: TamBourColors.border, width: 0.5)), child: Column(children: [
      Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18))), child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: TamBourColors.primary, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(trajet.depart.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.primaryDark)), const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.arrow_forward_rounded, size: 12, color: TamBourColors.primary)), Text(trajet.arrivee.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.primaryDark))]),
          Text('${DateFormat('HH:mm').format(trajet.heureDepart)} · ${trajet.compagnie}', style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.primary)),
        ])),
      ])),
      Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        _Ligne('Prix par passager', '${fmt.format(trajet.prixFcfa)} FCFA'),
        const SizedBox(height: 6),
        _Ligne('Passagers', '${params.nbPassagers} passager${params.nbPassagers > 1 ? 's' : ''}'),
        const SizedBox(height: 6),
        _Ligne('Sièges attribués', sieges.join(', ')),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total à payer', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
          Text('${fmt.format(total)} FCFA', style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: TamBourColors.primary)),
        ]),
      ])),
    ]));
  }
}

class _Ligne extends StatelessWidget {
  final String label, value;
  const _Ligne(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary)),
    Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: TamBourColors.textPrimary)),
  ]);
}

class _MethodeCard extends StatelessWidget {
  final MethodePaiement methode; final bool selected; final VoidCallback onTap;
  const _MethodeCard({required this.methode, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final couleur = methode.couleur;
    return Semantics(
      button: true, selected: selected, label: methode.nom,
      child: GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: selected ? couleur.withValues(alpha: 0.07) : TamBourColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? couleur : TamBourColors.border, width: selected ? 2 : 1)),
        child: Row(children: [
          LogoMethodePaiement(methode: methode, taille: 46),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(methode.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
            const SizedBox(height: 2),
            Text(methode.description, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary)),
          ])),
          const SizedBox(width: 8),
          AnimatedContainer(duration: const Duration(milliseconds: 200), width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? TamBourColors.primary : Colors.transparent,
              border: Border.all(color: selected ? TamBourColors.primary : TamBourColors.border, width: 2)),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null),
        ]))),
    );
  }
}

/// Logo officiel du moyen de paiement (icône carte pour la carte bancaire).
class LogoMethodePaiement extends StatelessWidget {
  final MethodePaiement methode; final double taille;
  const LogoMethodePaiement({super.key, required this.methode, this.taille = 44});
  @override
  Widget build(BuildContext context) {
    final logo = methode.logo;
    if (logo == null) {
      return Container(width: taille, height: taille,
        decoration: BoxDecoration(color: methode.couleur, borderRadius: BorderRadius.circular(taille * 0.24)),
        child: Icon(Icons.credit_card_rounded, color: Colors.white, size: taille * 0.5));
    }
    return Image.asset(logo, width: taille, height: taille, fit: BoxFit.contain, excludeFromSemantics: true);
  }
}

class _TelField extends StatelessWidget {
  final TextEditingController controller; final MethodePaiement methode;
  const _TelField({required this.controller, required this.methode});
  String get _hint => methode.exempleNumero;
  String get _label => 'Numéro ${methode.nom}';
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(controller: controller, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: 1),
        validator: (v) { if (v == null || v.trim().isEmpty) return 'Numéro requis'; if (v.trim().length < 10) return 'Numéro à 10 chiffres'; return null; },
        decoration: InputDecoration(hintText: _hint,
          prefixIcon: Container(margin: const EdgeInsets.fromLTRB(12,8,0,8), padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(7)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('🇨🇮', style: TextStyle(fontSize: 14)), SizedBox(width: 4), Text('+225', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: TamBourColors.primary))])),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0), filled: true, fillColor: TamBourColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.primary, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 1.5)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TamBourColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textHint, letterSpacing: 0), errorStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.error))),
    ]);
  }
}

class _EnCours extends StatelessWidget {
  final MethodePaiement methode; final String telephone; final int montant, secondes;
  const _EnCours({required this.methode, required this.telephone, required this.montant, required this.secondes});
  String get _nom => methode.nomCourt;
  Color get _color => methode.couleur;
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final prog = secondes / 120.0;
    final timerColor = secondes > 60 ? TamBourColors.primary : secondes > 30 ? TamBourColors.gold : TamBourColors.error;
    final mins = secondes ~/ 60; final secs = secondes % 60;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      _Pulse(color: _color, methode: methode),
      const SizedBox(height: 32),
      Text('Confirmez sur $_nom', style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w800, color: TamBourColors.textPrimary), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('Une notification a été envoyée au\n$telephone', style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        const Text('Montant à confirmer', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.primary)),
        const SizedBox(height: 6),
        Text('${fmt.format(montant)} FCFA', style: const TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.w800, color: TamBourColors.primary)),
      ])),
      const SizedBox(height: 28),
      SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: prog, strokeWidth: 5, backgroundColor: TamBourColors.border, valueColor: AlwaysStoppedAnimation<Color>(timerColor))),
        Text('$mins:${secs.toString().padLeft(2,'0')}', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: timerColor)),
      ])),
    ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0)));
  }
}

class _Pulse extends StatelessWidget {
  final Color color; final MethodePaiement methode;
  const _Pulse({required this.color, required this.methode});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 1000.ms, curve: Curves.easeInOut).then().scale(begin: const Offset(1.2,1.2), end: const Offset(1,1), duration: 1000.ms, curve: Curves.easeInOut),
      Container(width: 72, height: 72, decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle)),
      LogoMethodePaiement(methode: methode, taille: 56),
    ]));
  }
}

class _SecItem extends StatelessWidget {
  final IconData icon; final String label;
  const _SecItem({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: TamBourColors.textSecondary), const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textSecondary, fontWeight: FontWeight.w500)),
  ]);
}
