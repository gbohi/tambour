import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/gare.dart';
import '../../models/trajet.dart';
import '../../providers/recherche_provider.dart';
import '../../services/gare_service.dart';
import '../../widgets/page_header.dart';
import '../resultats/widgets/trajet_card.dart';

/// Prochains départs depuis une gare (bouton « Voir les trajets » de la carte des gares).
class DepartsGareScreen extends StatefulWidget {
  final Gare gare;
  const DepartsGareScreen({super.key, required this.gare});

  @override
  State<DepartsGareScreen> createState() => _DepartsGareScreenState();
}

class _DepartsGareScreenState extends State<DepartsGareScreen> {
  late Future<List<Trajet>> _departs;
  String? _destination;  // filtre

  @override
  void initState() {
    super.initState();
    _departs = GareService().getDeparts(widget.gare);
  }

  String _jour(DateTime d) {
    final now = DateTime.now();
    final demain = now.add(const Duration(days: 1));
    bool meme(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    if (meme(d, now)) return "Aujourd'hui";
    if (meme(d, demain)) return 'Demain';
    final s = DateFormat('EEEE d MMMM', 'fr_FR').format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        PageHeader(titre: 'Départs', sousTitre: widget.gare.nom),
        Expanded(child: FutureBuilder<List<Trajet>>(
          future: _departs,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: TamBourColors.primary));
            }
            final tous = snap.data ?? const <Trajet>[];
            final destinations = {for (final t in tous) t.arrivee.nom}.toList()..sort();
            final liste = _destination == null ? tous : tous.where((t) => t.arrivee.nom == _destination).toList();
            if (tous.isEmpty) {
              return const _Vide();
            }
            // Regroupement par jour
            final items = <Object>[];
            String? jourCourant;
            for (final t in liste) {
              final j = _jour(t.heureDepart);
              if (j != jourCourant) { items.add(j); jourCourant = j; }
              items.add(t);
            }
            return Column(children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    _Filtre(label: 'Toutes (${tous.length})', actif: _destination == null,
                      onTap: () => setState(() => _destination = null)),
                    for (final d in destinations)
                      _Filtre(label: d, actif: _destination == d, onTap: () => setState(() => _destination = d)),
                  ],
                ),
              ),
              Expanded(child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                      child: Text(item, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
                        fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)));
                  }
                  final t = item as Trajet;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TrajetCard(trajet: t, nbPassagers: 1, index: i, params: RechercheParams(
                      villeDepart: t.depart, villeArrivee: t.arrivee, date: t.heureDepart, nbPassagers: 1)),
                  ).animate().fadeIn(delay: Duration(milliseconds: 30 * (i % 10)));
                },
              )),
            ]);
          },
        )),
      ]),
    );
  }
}

class _Filtre extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback onTap;
  const _Filtre({required this.label, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: actif,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: TamBourColors.primary,
      backgroundColor: TamBourColors.surface,
      side: BorderSide(color: actif ? TamBourColors.primary : TamBourColors.border),
      labelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600,
        color: actif ? Colors.white : TamBourColors.textPrimary),
    ),
  );
}

class _Vide extends StatelessWidget {
  const _Vide();
  @override
  Widget build(BuildContext context) => const Center(child: SingleChildScrollView(
    padding: EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy_rounded, size: 52, color: TamBourColors.textHint),
      SizedBox(height: 12),
      Text('Aucun départ prévu depuis cette gare\ndans les 7 prochains jours.', textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)),
    ]),
  ));
}
