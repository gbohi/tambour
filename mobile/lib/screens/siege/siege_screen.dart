import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/siege.dart';
import '../../models/trajet.dart';
import '../../providers/siege_provider.dart';
import '../../providers/recherche_provider.dart';
import '../passagers/passagers_screen.dart';

class SiegeScreen extends ConsumerStatefulWidget {
  final Trajet trajet;
  final RechercheParams params;
  const SiegeScreen({super.key, required this.trajet, required this.params});
  @override
  ConsumerState<SiegeScreen> createState() => _SiegeScreenState();
}

class _SiegeScreenState extends ConsumerState<SiegeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(siegeProvider.notifier).charger(widget.trajet, widget.params.nbPassagers));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(siegeProvider);
    return Scaffold(
      backgroundColor: YoBusColors.background,
      body: Column(children: [
        _Header(trajet: widget.trajet),
        if (!state.isLoading) _ProgressBar(state: state, onReset: () => ref.read(siegeProvider.notifier).reinitialiser()),
        Expanded(child: state.isLoading ? _Loading() : _Body(state: state)),
        _Recap(state: state, trajet: widget.trajet, params: widget.params),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final Trajet trajet;
  const _Header({required this.trajet});
  @override
  Widget build(BuildContext context) {
    return Container(color: YoBusColors.primary, child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Choisissez vos sièges', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('${trajet.depart.nom} → ${trajet.arrivee.nom}  ·  ${DateFormat('HH:mm').format(trajet.heureDepart)}',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.white.withOpacity(0.8))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Text('${trajet.placesDisponibles} places', style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
      ]),
    )));
  }
}

class _ProgressBar extends StatelessWidget {
  final SiegeState state;
  final VoidCallback onReset;
  const _ProgressBar({required this.state, required this.onReset});
  @override
  Widget build(BuildContext context) {
    return Container(color: YoBusColors.surface, padding: const EdgeInsets.fromLTRB(20, 14, 20, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        RichText(text: TextSpan(style: const TextStyle(fontFamily: 'Outfit'), children: [
          TextSpan(text: '${state.selection.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: YoBusColors.primary)),
          TextSpan(text: ' / ${state.nbRequis} siège${state.nbRequis > 1 ? 's' : ''} sélectionné${state.selection.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 14, color: YoBusColors.textSecondary, fontWeight: FontWeight.w500)),
        ])),
        if (state.selection.isNotEmpty) GestureDetector(onTap: onReset, child: const Text('Réinitialiser', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: YoBusColors.error, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
        value: state.nbRequis == 0 ? 0 : state.selection.length / state.nbRequis,
        minHeight: 6, backgroundColor: YoBusColors.surfaceVariant,
        valueColor: const AlwaysStoppedAnimation<Color>(YoBusColors.primary))),
    ]));
  }
}

class _Body extends ConsumerWidget {
  final SiegeState state;
  const _Body({required this.state});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<int, List<Siege>> parRangee = {};
    for (final s in state.sieges) parRangee.putIfAbsent(s.rangee, () => []).add(s);
    final rangees = parRangee.keys.toList()..sort();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegItem(color: YoBusColors.primaryLight, borderColor: YoBusColors.primary.withOpacity(0.3), label: 'Libre'),
          const SizedBox(width: 16),
          _LegItem(color: YoBusColors.surfaceVariant, borderColor: YoBusColors.border, label: 'Occupé'),
          const SizedBox(width: 16),
          _LegItem(color: YoBusColors.primary, borderColor: YoBusColors.primary, label: 'Sélectionné', textColor: Colors.white),
        ]),
        const SizedBox(height: 16),
        Container(decoration: BoxDecoration(color: YoBusColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: YoBusColors.border, width: 0.5)), padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), child: Column(children: [
          Container(margin: const EdgeInsets.only(bottom: 6), height: 52,
            decoration: const BoxDecoration(color: YoBusColors.primary, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
            child: Center(child: Text('Chauffeur', style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.white.withOpacity(0.75))))),
          Row(children: [const SizedBox(width: 20), ...'ABCD'.split('').map((c) => SizedBox(width: 40, child: Center(child: Text(c, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: YoBusColors.textHint))))), const Spacer()]),
          ...rangees.map((r) {
            final sr = List<Siege>.from(parRangee[r]!)..sort((a, b) => a.colonne.compareTo(b.colonne));
            Siege? g(String col) { try { return sr.firstWhere((s) => s.colonne == col); } catch (_) { return null; } }
            return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
              SizedBox(width: 20, child: Text('$r', style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: YoBusColors.textHint), textAlign: TextAlign.center)),
              for (final col in ['A', 'B']) if (g(col) != null) _Seat(siege: g(col)!, onTap: (id) => ref.read(siegeProvider.notifier).toggleSiege(id)),
              const Spacer(),
              for (final col in ['C', 'D']) if (g(col) != null) _Seat(siege: g(col)!, onTap: (id) => ref.read(siegeProvider.notifier).toggleSiege(id)),
            ]));
          }),
        ])).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
      ]),
    );
  }
}

class _Seat extends StatelessWidget {
  final Siege siege;
  final ValueChanged<String> onTap;
  const _Seat({required this.siege, required this.onTap});
  Color get _bg => switch (siege.statut) { StatutSiege.libre => YoBusColors.primaryLight, StatutSiege.occupe => YoBusColors.surfaceVariant, StatutSiege.selectionne => YoBusColors.primary, _ => const Color(0xFFE8F4FD) };
  Color get _bc => switch (siege.statut) { StatutSiege.libre => const Color(0x4D0A7C4E), StatutSiege.occupe => YoBusColors.border, StatutSiege.selectionne => YoBusColors.primary, _ => Colors.blue };
  @override
  Widget build(BuildContext context) {
    final occ = siege.statut == StatutSiege.occupe;
    final sel = siege.statut == StatutSiege.selectionne;
    return GestureDetector(
      onTap: siege.estSelectionnable ? () => onTap(siege.id) : null,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        width: 40, height: 36, margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bc, width: 1.5)),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(top: 3, left: 4, right: 4, child: Container(height: 14, decoration: BoxDecoration(color: occ ? YoBusColors.border : sel ? Colors.white.withOpacity(0.2) : YoBusColors.primary.withOpacity(0.08), borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))))),
          Positioned(bottom: 4, child: occ ? const Icon(Icons.close_rounded, size: 12, color: YoBusColors.textHint) : sel ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : Text(siege.label, style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w700, color: sel ? Colors.white : YoBusColors.primary))),
        ])),
    );
  }
}

class _LegItem extends StatelessWidget {
  final Color color; final Color borderColor; final String label; final Color textColor;
  const _LegItem({required this.color, required this.borderColor, required this.label, this.textColor = YoBusColors.textSecondary});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 20, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), border: Border.all(color: borderColor, width: 1.5))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: textColor == Colors.white ? YoBusColors.textPrimary : YoBusColors.textSecondary, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: YoBusColors.primaryLight, shape: BoxShape.circle), child: const CircularProgressIndicator(color: YoBusColors.primary, strokeWidth: 3)),
      const SizedBox(height: 16),
      const Text('Chargement du plan...', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: YoBusColors.textSecondary)),
    ]));
  }
}

class _Recap extends StatelessWidget {
  final SiegeState state; final Trajet trajet; final RechercheParams params;
  const _Recap({required this.state, required this.trajet, required this.params});
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final prixTotal = trajet.prixFcfa * params.nbPassagers;
    return Container(
      decoration: BoxDecoration(color: YoBusColors.surface, border: const Border(top: BorderSide(color: YoBusColors.border, width: 0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -6))]),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (state.selection.isNotEmpty) Row(children: [
          const Icon(Icons.event_seat_rounded, color: YoBusColors.primary, size: 18), const SizedBox(width: 8),
          Text('Sièges : ${state.siegesSelectionnes.map((s) => s.label).join(', ')}', style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600, color: YoBusColors.textPrimary)),
          const Spacer(),
          Text('${formatter.format(prixTotal)} FCFA', style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: YoBusColors.primary)),
        ]),
        if (state.selection.isNotEmpty) const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: state.selectionComplete ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => PassagersScreen(trajet: trajet, params: params))) : null,
          style: ElevatedButton.styleFrom(backgroundColor: YoBusColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: YoBusColors.border, disabledForegroundColor: YoBusColors.textHint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)),
          child: Text(state.selectionComplete ? 'Confirmer les sièges' : 'Sélectionnez ${state.nbRequis - state.selection.length} siège${(state.nbRequis - state.selection.length) > 1 ? 's' : ''}'))),
      ]))),
    );
  }
}
