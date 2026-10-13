import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_chauffeur/models/chauffeur.dart';
import 'package:tambour_chauffeur/services/chauffeur_service.dart';
import 'package:tambour_commun/widgets/app_snackbar.dart';
import 'package:tambour_commun/widgets/page_header.dart';
import 'package:tambour_chauffeur/screens/chauffeur_accueil_screen.dart';
import 'package:tambour_chauffeur/screens/scanner_billet_screen.dart';

/// Détail d'un trajet côté chauffeur : embarquement, passagers, démarrer / terminer.
class ChauffeurTrajetScreen extends StatefulWidget {
  final String trajetId;
  final ChauffeurService? service;
  const ChauffeurTrajetScreen({super.key, required this.trajetId, this.service});
  @override
  State<ChauffeurTrajetScreen> createState() => _ChauffeurTrajetScreenState();
}

class _ChauffeurTrajetScreenState extends State<ChauffeurTrajetScreen> {
  late final ChauffeurService _service = widget.service ?? ChauffeurService();
  TrajetChauffeur? _trajet;
  String? _erreur;
  bool _action = false;
  String _recherche = '';

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    try {
      final t = await _service.trajet(widget.trajetId);
      if (mounted) setState(() { _trajet = t; _erreur = null; });
    } on ChauffeurException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _scanner() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScannerBilletScreen(trajet: _trajet!, service: _service)));
    await _charger();
  }

  Future<void> _changerStatut({required bool terminer}) async {
    final t = _trajet!;
    final restants = t.nbPassagers - t.nbEmbarques;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(terminer ? 'Terminer le trajet ?' : 'Démarrer le trajet ?',
        style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800)),
      content: Text(terminer
        ? 'Confirmez l\'arrivée à ${t.arrivee}. Les voyageurs pourront ensuite noter le trajet.'
        : restants > 0
          ? '$restants passager${restants > 1 ? 's' : ''} n\'${restants > 1 ? 'ont' : 'a'} pas encore été scanné${restants > 1 ? 's' : ''}. Démarrer quand même ?'
          : 'Tous les passagers sont à bord. Bonne route !',
        style: const TextStyle(fontFamily: 'Outfit')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: TamBourColors.primary),
          child: Text(terminer ? 'Terminer' : 'Démarrer')),
      ],
    ));
    if (ok != true) return;
    setState(() => _action = true);
    try {
      final msg = terminer ? await _service.terminer(t.id) : await _service.demarrer(t.id);
      if (mounted) AppSnackbar.succes(context, msg);
      await _charger();
    } on ChauffeurException catch (e) {
      if (mounted) AppSnackbar.erreur(context, e.message);
    } finally {
      if (mounted) setState(() => _action = false);
    }
  }

  Future<void> _validerManuellement(PassagerChauffeur p) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Valider sans scanner ?', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800)),
      content: Text('${p.nomComplet} — siège ${p.siege}\nBillet ${p.referenceBillet}\n\n'
        'Vérifiez la pièce d\'identité ou le billet du passager avant de valider.',
        style: const TextStyle(fontFamily: 'Outfit')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: TamBourColors.primary), child: const Text('Valider')),
      ],
    ));
    if (ok != true) return;
    final r = await _service.scanner(_trajet!.id, referenceBillet: p.referenceBillet);
    if (!mounted) return;
    r.ok ? AppSnackbar.succes(context, r.message) : AppSnackbar.erreur(context, r.message);
    await _charger();
  }

  @override
  Widget build(BuildContext context) {
    final t = _trajet;
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        PageHeader(
          titre: t == null ? 'Trajet' : '${t.depart} → ${t.arrivee}',
          sousTitre: t == null ? null
            : '${DateFormat('EEE d MMM · HH:mm', 'fr_FR').format(t.heureDepart)} · ${t.busImmatriculation}',
          action: IconButton(onPressed: _charger, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
        ),
        Expanded(child: t == null
          ? Center(child: _erreur == null
              ? const CircularProgressIndicator(color: TamBourColors.primary)
              : Padding(padding: const EdgeInsets.all(32), child: Text(_erreur!, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Outfit', color: TamBourColors.textSecondary))))
          : RefreshIndicator(
              color: TamBourColors.primary,
              onRefresh: _charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _Embarquement(trajet: t),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: Text('Passagers (${t.passagers.length})', style: const TextStyle(
                      fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary))),
                    BadgeStatutTrajet(statut: t.statut, label: t.statutLabel),
                  ]),
                  const SizedBox(height: 10),
                  if (t.passagers.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        onChanged: (v) => setState(() => _recherche = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Nom, siège ou référence…', isDense: true,
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true, fillColor: TamBourColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: TamBourColors.border))),
                      ),
                    ),
                  if (t.passagers.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Text('Aucun passager pour ce trajet.',
                      textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Outfit', color: TamBourColors.textSecondary))),
                  ...t.passagers
                    .where((p) => _recherche.isEmpty || p.nomComplet.toLowerCase().contains(_recherche)
                      || p.siege.toLowerCase() == _recherche || p.referenceBillet.toLowerCase().contains(_recherche))
                    .map((p) => _LignePassager(passager: p,
                      onValider: t.estTermine || p.embarque ? null : () => _validerManuellement(p))),
                ],
              ),
            )),
      ]),
      bottomNavigationBar: t == null || t.estTermine ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: _action ? null : _scanner,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scanner', maxLines: 1),
              style: FilledButton.styleFrom(backgroundColor: TamBourColors.primary,
                minimumSize: const Size(0, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: _action ? null : () => _changerStatut(terminer: t.estEnCours),
              icon: Icon(t.estEnCours ? Icons.flag_rounded : Icons.play_arrow_rounded),
              label: Text(t.estEnCours ? 'Terminer' : 'Démarrer', maxLines: 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.estEnCours ? TamBourColors.error : TamBourColors.primary,
                side: BorderSide(color: t.estEnCours ? TamBourColors.error : TamBourColors.primary, width: 1.5),
                minimumSize: const Size(0, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)))),
          ]),
        ),
      ),
    );
  }
}

class _Embarquement extends StatelessWidget {
  final TrajetChauffeur trajet;
  const _Embarquement({required this.trajet});

  @override
  Widget build(BuildContext context) {
    final t = trajet;
    final ratio = t.nbPassagers == 0 ? 0.0 : t.nbEmbarques / t.nbPassagers;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Embarquement', style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
          fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${t.nbEmbarques}', style: const TextStyle(fontFamily: 'Outfit', fontSize: 36,
            fontWeight: FontWeight.w900, color: TamBourColors.primary, height: 1)),
          Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text('/ ${t.nbPassagers} à bord',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textSecondary))),
          const Spacer(),
          Text('${t.placesTotal - t.nbPassagers} places libres', style: const TextStyle(fontFamily: 'Outfit',
            fontSize: 12, color: TamBourColors.textHint)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
          value: ratio, minHeight: 10, backgroundColor: TamBourColors.surfaceVariant,
          color: ratio >= 1 ? TamBourColors.primary : TamBourColors.gold)),
        if (t.gareDepart != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 15, color: TamBourColors.textHint),
            const SizedBox(width: 4),
            Expanded(child: Text('Départ : ${t.gareDepart}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary))),
          ]),
        ],
      ]),
    );
  }
}

class _LignePassager extends StatelessWidget {
  final PassagerChauffeur passager;
  final VoidCallback? onValider;
  const _LignePassager({required this.passager, this.onValider});

  @override
  Widget build(BuildContext context) {
    final p = passager;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: p.embarque ? TamBourColors.primaryLight : TamBourColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.embarque ? TamBourColors.primary.withOpacity(0.3) : TamBourColors.border, width: 0.8)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: p.embarque ? TamBourColors.primary : TamBourColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(p.siege, style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
            fontWeight: FontWeight.w800, color: p.embarque ? Colors.white : TamBourColors.textPrimary)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.nomComplet, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(
            fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
          Text(p.embarque && p.embarqueLe != null
              ? 'À bord depuis ${DateFormat('HH:mm').format(p.embarqueLe!)}'
              : p.referenceBillet,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
              color: p.embarque ? TamBourColors.primary : TamBourColors.textHint)),
        ])),
        if (p.embarque)
          const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.check_circle_rounded, color: TamBourColors.primary))
        else if (onValider != null)
          TextButton(onPressed: onValider, child: const Text('Valider')),
      ]),
    );
  }
}
