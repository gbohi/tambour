import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/trajet.dart';
import '../../providers/recherche_provider.dart';
import 'widgets/trajet_card.dart';
import 'widgets/filtre_bar.dart';

class ResultatsScreen extends ConsumerStatefulWidget {
  final RechercheParams params;
  const ResultatsScreen({super.key, required this.params});
  @override
  ConsumerState<ResultatsScreen> createState() => _ResultatsScreenState();
}

class _ResultatsScreenState extends ConsumerState<ResultatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(rechercheProvider.notifier).rechercher(widget.params));
  }

  String get _dateLabel => DateFormat('EEEE d MMMM', 'fr_FR').format(widget.params.date);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rechercheProvider);
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        _ResultatsHeader(params: widget.params, dateLabel: _dateLabel),
        FiltreBar(
          triActif: state.tri,
          filtreClasseActif: state.filtreClasse,
          onTriChange: (t) => ref.read(rechercheProvider.notifier).changerTri(t),
          onFiltreClasseChange: (c) => ref.read(rechercheProvider.notifier).changerFiltreClasse(c)),
        Expanded(child: _buildBody(state)),
      ]),
    );
  }

  Widget _buildBody(RechercheState state) {
    if (state.isLoading) return _buildLoading();
    if (state.erreur != null) return _buildErreur(state.erreur!);
    if (state.resultatsFiltres.isEmpty) return _buildVide();
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: state.resultatsFiltres.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Text('${state.resultatsFiltres.length} trajet${state.resultatsFiltres.length > 1 ? 's' : ''} disponible${state.resultatsFiltres.length > 1 ? 's' : ''}',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary, fontWeight: FontWeight.w500)));
        final trajet = state.resultatsFiltres[i - 1];
        return Padding(padding: const EdgeInsets.only(bottom: 12),
          child: TrajetCard(trajet: trajet, nbPassagers: widget.params.nbPassagers, index: i - 1, params: widget.params));
      });
  }

  Widget _buildLoading() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), itemCount: 4,
    itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Container(height: 170, decoration: BoxDecoration(color: TamBourColors.border, borderRadius: BorderRadius.circular(16)))
        .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.6))));

  Widget _buildErreur(String message) => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: TamBourColors.error.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.wifi_off_rounded, color: TamBourColors.error, size: 34)),
      const SizedBox(height: 20),
      const Text('Connexion impossible', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)),
    ])));

  Widget _buildVide() => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: TamBourColors.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.directions_bus_rounded, color: TamBourColors.primary, size: 38)),
      const SizedBox(height: 20),
      const Text('Aucun trajet trouvé', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Essayez une autre date ou modifiez vos filtres.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary, height: 1.5)),
    ])));
}

class _ResultatsHeader extends StatelessWidget {
  final RechercheParams params;
  final String dateLabel;
  const _ResultatsHeader({required this.params, required this.dateLabel});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(params.villeDepart.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, color: TamBourColors.gold, size: 16)),
              Text(params.villeArrivee.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              _Chip(icon: Icons.calendar_today_rounded, label: dateLabel),
              const SizedBox(width: 8),
              _Chip(icon: Icons.person_outline_rounded, label: '${params.nbPassagers} passager${params.nbPassagers > 1 ? 's' : ''}'),
            ]),
          ])),
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20)),
        ]),
      )),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white70), const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
      ]));
  }
}
