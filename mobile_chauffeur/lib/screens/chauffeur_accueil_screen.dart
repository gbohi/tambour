import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_chauffeur/models/chauffeur.dart';
import 'package:tambour_commun/providers/auth_provider.dart';
import 'package:tambour_chauffeur/services/chauffeur_service.dart';
import 'package:tambour_chauffeur/screens/chauffeur_trajet_screen.dart';
import 'package:tambour_chauffeur/services/partage_position.dart';

/// Espace chauffeur : trajets à venir et historique.
class ChauffeurAccueilScreen extends ConsumerStatefulWidget {
  final ChauffeurService? service;  // injectable (tests)
  const ChauffeurAccueilScreen({super.key, this.service});
  @override
  ConsumerState<ChauffeurAccueilScreen> createState() => _ChauffeurAccueilScreenState();
}

class _ChauffeurAccueilScreenState extends ConsumerState<ChauffeurAccueilScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final ChauffeurService _service = widget.service ?? ChauffeurService();
  late Future<List<TrajetChauffeur>> _aVenir;
  late Future<List<TrajetChauffeur>> _historique;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _charger() {
    setState(() {
      _aVenir = _service.mesTrajets();
      _historique = _service.mesTrajets(historique: true);
    });
  }

  Future<void> _ouvrir(TrajetChauffeur t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChauffeurTrajetScreen(trajetId: t.id, service: _service)));
    if (mounted) _charger();
  }

  Future<void> _deconnecter() async {
    await PartagePosition.instance.arreter();
    await ref.read(authProvider.notifier).deconnecter();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [TamBourColors.primaryDark, TamBourColors.primary],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(children: [
                Container(width: 46, height: 46,
                  decoration: const BoxDecoration(color: TamBourColors.gold, shape: BoxShape.circle),
                  child: Center(child: Text(user?.initiales ?? 'CH', style: const TextStyle(fontFamily: 'Outfit',
                    fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bonjour ${user?.prenom ?? ''} 👋', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 18,
                      fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Espace chauffeur', style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    color: Colors.white.withOpacity(0.75))),
                ])),
                IconButton(onPressed: _charger, tooltip: 'Actualiser',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
                IconButton(onPressed: _deconnecter, tooltip: 'Se déconnecter',
                  icon: const Icon(Icons.logout_rounded, color: Colors.white)),
              ]),
            ),
            TabBar(
              controller: _tab,
              indicatorColor: TamBourColors.gold, indicatorWeight: 3,
              labelColor: Colors.white, unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
              tabs: const [Tab(text: 'Mes trajets'), Tab(text: 'Historique')]),
          ])),
        ),
        // Rappel visible partout : la position du car est partagée pendant le trajet en cours
        ListenableBuilder(listenable: PartagePosition.instance, builder: (context, _) {
          final p = PartagePosition.instance;
          if (p.trajetId == null) return const SizedBox.shrink();
          return Material(
            color: p.actif ? TamBourColors.primaryLight : TamBourColors.goldLight,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChauffeurTrajetScreen(trajetId: p.trajetId!, service: _service))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Icon(p.actif ? Icons.my_location_rounded : Icons.location_disabled_rounded, size: 18,
                    color: p.actif ? TamBourColors.primary : const Color(0xFF8A5A00)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    p.actif ? 'Position du car partagée avec les voyageurs' : 'Partage de position interrompu',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600,
                      color: TamBourColors.textPrimary))),
                  const Icon(Icons.chevron_right_rounded, color: TamBourColors.textSecondary),
                ]),
              ),
            ),
          );
        }),
        Expanded(child: TabBarView(controller: _tab, children: [
          _ListeTrajets(future: _aVenir, historique: false, onOuvrir: _ouvrir, onActualiser: _charger),
          _ListeTrajets(future: _historique, historique: true, onOuvrir: _ouvrir, onActualiser: _charger),
        ])),
      ]),
    );
  }
}

class _ListeTrajets extends StatelessWidget {
  final Future<List<TrajetChauffeur>> future;
  final bool historique;
  final ValueChanged<TrajetChauffeur> onOuvrir;
  final VoidCallback onActualiser;
  const _ListeTrajets({required this.future, required this.historique, required this.onOuvrir, required this.onActualiser});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrajetChauffeur>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: TamBourColors.primary));
        }
        if (snap.hasError) {
          return _Message(icone: Icons.wifi_off_rounded, texte: '${snap.error}',
            action: TextButton(onPressed: onActualiser, child: const Text('Réessayer')));
        }
        final trajets = snap.data!;
        if (trajets.isEmpty) {
          return _Message(icone: historique ? Icons.history_rounded : Icons.event_available_rounded,
            texte: historique ? 'Aucun trajet effectué pour le moment.'
              : 'Aucun trajet ne vous est attribué.\nVotre compagnie vous assignera vos prochains départs.');
        }
        return RefreshIndicator(
          color: TamBourColors.primary,
          onRefresh: () async => onActualiser(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (historique) _BilanHistorique(trajets: trajets),
              for (var i = 0; i < trajets.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CarteTrajetChauffeur(trajet: trajets[i], onTap: () => onOuvrir(trajets[i]),
                    prochain: !historique && i == 0),
                ).animate().fadeIn(delay: Duration(milliseconds: 40 * i)).slideY(begin: 0.05, end: 0),
            ],
          ),
        );
      },
    );
  }
}

class _BilanHistorique extends StatelessWidget {
  final List<TrajetChauffeur> trajets;
  const _BilanHistorique({required this.trajets});

  @override
  Widget build(BuildContext context) {
    final passagers = trajets.fold(0, (s, t) => s + t.nbPassagers);
    final termines = trajets.where((t) => t.statut == 'termine').length;
    Widget stat(String v, String l) => Expanded(child: Column(children: [
      Text(v, style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w900,
        color: TamBourColors.primary)),
      Text(l, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
        color: TamBourColors.textSecondary)),
    ]));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Row(children: [
        stat('$termines', 'trajets\nterminés'),
        stat('$passagers', 'passagers\ntransportés'),
        stat('${trajets.length - termines}', 'annulés ou\nnon clôturés'),
      ]),
    );
  }
}

/// Carte d'un trajet (liste de l'espace chauffeur).
class CarteTrajetChauffeur extends StatelessWidget {
  final TrajetChauffeur trajet;
  final VoidCallback onTap;
  final bool prochain;
  const CarteTrajetChauffeur({super.key, required this.trajet, required this.onTap, this.prochain = false});

  @override
  Widget build(BuildContext context) {
    final t = trajet;
    final heure = DateFormat('HH:mm');
    final jour = DateFormat('EEE d MMM', 'fr_FR').format(t.heureDepart);
    return Material(
      color: TamBourColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: prochain ? TamBourColors.primary : TamBourColors.border, width: prochain ? 1.5 : 0.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (prochain) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: TamBourColors.gold, borderRadius: BorderRadius.circular(20)),
                  child: const Text('PROCHAIN', style: TextStyle(fontFamily: 'Outfit', fontSize: 10,
                    fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5))),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(jour[0].toUpperCase() + jour.substring(1), style: const TextStyle(
                fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: TamBourColors.textSecondary))),
              BadgeStatutTrajet(statut: t.statut, label: t.statutLabel),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(heure.format(t.heureDepart), style: const TextStyle(fontFamily: 'Outfit', fontSize: 22,
                  fontWeight: FontWeight.w900, color: TamBourColors.textPrimary)),
                Text(heure.format(t.heureArriveeReelle ?? t.heureArriveeEstimee), style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textHint)),
              ]),
              const SizedBox(width: 14),
              Container(width: 2, height: 40, color: TamBourColors.border),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.depart, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
                Text(t.arrivee, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 14, runSpacing: 6, children: [
              _Info(icone: Icons.directions_bus_rounded, texte: t.busImmatriculation.isEmpty ? '—' : t.busImmatriculation),
              _Info(icone: Icons.people_alt_rounded, texte: '${t.nbPassagers} passager${t.nbPassagers > 1 ? 's' : ''}'),
              if (t.nbPassagers > 0)
                _Info(icone: Icons.qr_code_scanner_rounded, texte: '${t.nbEmbarques}/${t.nbPassagers} à bord'),
              if (t.gareDepart != null) _Info(icone: Icons.location_on_rounded, texte: t.gareDepart!),
            ]),
          ]),
        ),
      ),
    );
  }
}

class BadgeStatutTrajet extends StatelessWidget {
  final String statut, label;
  const BadgeStatutTrajet({super.key, required this.statut, required this.label});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (statut) {
      'en_cours' => (const Color(0xFF2F6FD6), const Color(0xFFEAF1FD)),
      'termine' => (TamBourColors.primary, TamBourColors.primaryLight),
      'annule' => (TamBourColors.error, const Color(0xFFFDECEC)),
      'retarde' => (const Color(0xFFB26A00), TamBourColors.goldLight),
      _ => (TamBourColors.textSecondary, TamBourColors.surfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: fg)));
  }
}

class _Info extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _Info({required this.icone, required this.texte});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icone, size: 14, color: TamBourColors.textHint),
    const SizedBox(width: 4),
    Flexible(child: Text(texte, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary))),
  ]);
}

class _Message extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Widget? action;
  const _Message({required this.icone, required this.texte, this.action});
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icone, size: 52, color: TamBourColors.textHint),
      const SizedBox(height: 12),
      Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
        height: 1.5, color: TamBourColors.textSecondary)),
      if (action != null) action!,
    ]),
  ));
}
