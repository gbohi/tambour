import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/support.dart';
import '../../providers/support_provider.dart';
import '../../services/support_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/champ_formulaire.dart';
import '../../widgets/page_header.dart';

/// Liste de mes réclamations + accès au formulaire.
class ReclamationsScreen extends ConsumerWidget {
  const ReclamationsScreen({super.key});

  Future<void> _nouvelle(BuildContext context, WidgetRef ref) async {
    final cree = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const NouvelleReclamationScreen()));
    if (cree == true) ref.invalidate(reclamationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reclamations = ref.watch(reclamationsProvider);
    return Scaffold(
      backgroundColor: TamBourColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nouvelle(context, ref),
        backgroundColor: TamBourColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle réclamation', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700))),
      body: Column(children: [
        const PageHeader(titre: 'Mes réclamations', sousTitre: 'Suivez le traitement de vos demandes'),
        Expanded(child: reclamations.when(
          loading: () => const Center(child: CircularProgressIndicator(color: TamBourColors.primary)),
          error: (e, _) => _Vide(
            icone: Icons.wifi_off_rounded,
            texte: e is SupportException ? e.message : 'Impossible de charger vos réclamations.',
            action: TextButton(onPressed: () => ref.invalidate(reclamationsProvider), child: const Text('Réessayer'))),
          data: (liste) => liste.isEmpty
            ? const _Vide(icone: Icons.inbox_rounded,
                texte: 'Aucune réclamation.\nUn souci avec un voyage, un paiement ou un billet ?\nSignalez-le ici.')
            : RefreshIndicator(
                color: TamBourColors.primary,
                onRefresh: () => ref.refresh(reclamationsProvider.future),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: liste.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CarteReclamation(r: liste[i]).animate().fadeIn(delay: (40 * i).ms),
                ),
              ),
        )),
      ]),
    );
  }
}

class _Vide extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Widget? action;
  const _Vide({required this.icone, required this.texte, this.action});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icone, size: 52, color: TamBourColors.textHint),
      const SizedBox(height: 12),
      Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit',
        fontSize: 14, height: 1.5, color: TamBourColors.textSecondary)),
      if (action != null) action!,
    ]),
  ));
}

class _CarteReclamation extends StatelessWidget {
  final Reclamation r;
  const _CarteReclamation({required this.r});

  (Color, Color) get _couleurs => switch (r.statut) {
    StatutReclamation.ouverte => (TamBourColors.gold, TamBourColors.goldLight),
    StatutReclamation.enCours => (const Color(0xFF2F6FD6), const Color(0xFFEAF1FD)),
    StatutReclamation.resolue => (TamBourColors.primary, TamBourColors.primaryLight),
    StatutReclamation.rejetee => (TamBourColors.error, const Color(0xFFFDECEC)),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _couleurs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(r.reference, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
            fontWeight: FontWeight.w700, color: TamBourColors.textHint, letterSpacing: 0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(r.statutLabel, style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
              fontWeight: FontWeight.w700, color: fg))),
        ]),
        const SizedBox(height: 8),
        Text(r.sujet, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
          fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
        const SizedBox(height: 4),
        Text('${r.categorieLabel} · ${DateFormat('d MMM yyyy', 'fr_FR').format(r.date.toLocal())}'
          '${r.referenceReservation.isNotEmpty ? ' · ${r.referenceReservation}' : ''}',
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary)),
        if (r.reponse.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Réponse du support', style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                fontWeight: FontWeight.w700, color: TamBourColors.primary)),
              const SizedBox(height: 4),
              Text(r.reponse, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                height: 1.4, color: TamBourColors.textPrimary)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// Formulaire « Faire une réclamation ».
class NouvelleReclamationScreen extends ConsumerStatefulWidget {
  const NouvelleReclamationScreen({super.key});
  @override
  ConsumerState<NouvelleReclamationScreen> createState() => _NouvelleReclamationScreenState();
}

class _NouvelleReclamationScreenState extends ConsumerState<NouvelleReclamationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _sujetCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _categorie;
  bool _envoi = false;

  @override
  void dispose() {
    for (final c in [_refCtrl, _sujetCtrl, _descriptionCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final msg = await ref.read(supportServiceProvider).creerReclamation(
        categorie: _categorie!, sujet: _sujetCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        referenceReservation: _refCtrl.text.trim().toUpperCase());
      if (!mounted) return;
      AppSnackbar.succes(context, msg);
      Navigator.pop(context, true);
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
        const PageHeader(titre: 'Faire une réclamation', sousTitre: 'Réponse sous 48 h'),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Motif', style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
              fontWeight: FontWeight.w600, color: TamBourColors.textSecondary)),
            const SizedBox(height: 8),
            FormField<String>(
              validator: (_) => _categorie == null ? 'Choisissez un motif' : null,
              builder: (state) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in Reclamation.categories.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _categorie == e.key,
                      onSelected: (_) { setState(() => _categorie = e.key); state.didChange(e.key); },
                      selectedColor: TamBourColors.primary,
                      backgroundColor: TamBourColors.surface,
                      side: BorderSide(color: _categorie == e.key ? TamBourColors.primary : TamBourColors.border),
                      labelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600,
                        color: _categorie == e.key ? Colors.white : TamBourColors.textPrimary),
                      showCheckmark: false,
                    ),
                ]),
                if (state.hasError) Padding(padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(state.errorText!, style: const TextStyle(fontFamily: 'Outfit',
                    fontSize: 12, color: TamBourColors.error))),
              ]),
            ),
            const SizedBox(height: 18),
            ChampFormulaire(controller: _refCtrl, label: 'Référence de réservation (facultatif)',
              hint: 'Ex : TB202610123456', icone: Icons.confirmation_number_outlined,
              majuscules: TextCapitalization.characters),
            const SizedBox(height: 12),
            ChampFormulaire(controller: _sujetCtrl, label: 'Objet', hint: 'Résumez le problème',
              icone: Icons.subject_rounded, longueurMax: 200,
              validator: (v) => (v ?? '').trim().length < 3 ? 'Objet requis' : null),
            const SizedBox(height: 4),
            ChampFormulaire(controller: _descriptionCtrl, label: 'Description', lignes: 6,
              hint: 'Que s\'est-il passé ? Date, trajet, montant…',
              validator: (v) => (v ?? '').trim().length < 20 ? 'Décrivez le problème (20 caractères min.)' : null),
            const SizedBox(height: 20),
            AppButton(label: 'Envoyer la réclamation', icon: Icons.send_rounded, isLoading: _envoi, onPressed: _envoyer),
          ])),
        )),
      ]),
    );
  }
}
