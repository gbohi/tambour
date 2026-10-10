import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';

// ── Modèle mock passager par billet ──────────────────────────────────────────

class _PassagerMock {
  final String prenom, nom, telephone, email, siege;
  const _PassagerMock({required this.prenom, required this.nom,
    required this.telephone, this.email = '', required this.siege});
  String get nomComplet => '$prenom $nom';
}

class _ReservationMock {
  final String ref;
  final String depart, arrivee;
  final DateTime date;
  final String compagnie;
  final int prixParPassager;
  final String statut;
  final List<_PassagerMock> passagers;

  const _ReservationMock({
    required this.ref, required this.depart, required this.arrivee,
    required this.date, required this.compagnie,
    required this.prixParPassager, required this.statut,
    required this.passagers,
  });

  int get montantTotal => prixParPassager * passagers.length;
  int get nbPassagers => passagers.length;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MesBilletsScreen extends StatefulWidget {
  const MesBilletsScreen({super.key});
  @override
  State<MesBilletsScreen> createState() => _MesBilletsScreenState();
}

class _MesBilletsScreenState extends State<MesBilletsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  // Données mock — 1 réservation = N passagers = N billets
  List<_ReservationMock> get _aVenir => [
    _ReservationMock(
      ref: 'TB20260608001', depart: 'Abidjan', arrivee: 'Bouaké',
      date: DateTime.now().add(const Duration(days: 2, hours: 6)),
      compagnie: 'Trans Ivoire', prixParPassager: 3500, statut: 'confirmee',
      passagers: const [
        _PassagerMock(prenom: 'Kouassi', nom: 'Adjoumani',
          telephone: '0707010203', email: 'k.adjoumani@email.com', siege: '7A'),
        _PassagerMock(prenom: 'Aya', nom: 'Koné',
          telephone: '0504050607', siege: '7B'),
        _PassagerMock(prenom: 'Koffi', nom: 'Bamba',
          telephone: '0102030405', email: 'k.bamba@email.com', siege: '8A'),
      ]),
    _ReservationMock(
      ref: 'TB20260615002', depart: 'Bouaké', arrivee: 'Korhogo',
      date: DateTime.now().add(const Duration(days: 9, hours: 8)),
      compagnie: 'Confort Express', prixParPassager: 2500, statut: 'confirmee',
      passagers: const [
        _PassagerMock(prenom: 'Amara', nom: 'Touré',
          telephone: '0102030405', email: 'amara@email.com', siege: '12C'),
      ]),
  ];

  List<_ReservationMock> get _passes => [
    _ReservationMock(
      ref: 'TB20260501003', depart: 'Abidjan', arrivee: 'Yamoussoukro',
      date: DateTime.now().subtract(const Duration(days: 10)),
      compagnie: 'Trans Ivoire', prixParPassager: 2800, statut: 'termine',
      passagers: const [
        _PassagerMock(prenom: 'Fatoumata', nom: 'Coulibaly',
          telephone: '0102030405', siege: '3B'),
        _PassagerMock(prenom: 'Ibrahim', nom: 'Diallo',
          telephone: '0708091011', siege: '3C'),
      ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YoBusColors.background,
      body: Column(children: [
        Container(
          color: YoBusColors.primary,
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Mes billets', style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 18,
                  fontWeight: FontWeight.w800, color: Colors.white))),
              ])),
            TabBar(
              controller: _tab,
              indicatorColor: YoBusColors.gold, indicatorWeight: 3,
              labelColor: Colors.white, unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
              tabs: [
                Tab(text: 'À venir (${_aVenir.fold(0, (s, r) => s + r.nbPassagers)})'),
                Tab(text: 'Passés (${_passes.fold(0, (s, r) => s + r.nbPassagers)})'),
              ]),
          ])),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _ReservationsList(reservations: _aVenir, estAVenir: true),
          _ReservationsList(reservations: _passes, estAVenir: false),
        ])),
      ]),
    );
  }
}

// ── Liste des réservations → affiche les billets individuels ──────────────────

class _ReservationsList extends StatelessWidget {
  final List<_ReservationMock> reservations;
  final bool estAVenir;
  const _ReservationsList({required this.reservations, required this.estAVenir});

  @override
  Widget build(BuildContext context) {
    // Aplatir : une réservation → N billets individuels
    final billets = <Map<String, dynamic>>[];
    for (final r in reservations) {
      for (int i = 0; i < r.passagers.length; i++) {
        billets.add({'reservation': r, 'passager': r.passagers[i],
          'index': i, 'total': r.passagers.length});
      }
    }

    if (billets.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
          decoration: const BoxDecoration(
            color: YoBusColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.confirmation_number_rounded,
            color: YoBusColors.primary, size: 38)),
        const SizedBox(height: 20),
        Text(estAVenir ? 'Aucun voyage à venir' : 'Aucun voyage passé',
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 17,
            fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
        const SizedBox(height: 8),
        const Text("Réservez votre prochain trajet depuis l'accueil.",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: YoBusColors.textSecondary)),
      ]));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: billets.length,
      itemBuilder: (context, i) {
        final b = billets[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _BilletIndividuelCard(
            reservation: b['reservation'] as _ReservationMock,
            passager:    b['passager']    as _PassagerMock,
            numeroBillet: (b['index'] as int) + 1,
            totalBillets:  b['total']    as int,
          ).animate()
            .fadeIn(delay: Duration(milliseconds: 100 + i * 70), duration: 350.ms)
            .slideY(begin: 0.06, end: 0));
      });
  }
}

// ── Carte d'un billet individuel ──────────────────────────────────────────────

class _BilletIndividuelCard extends StatelessWidget {
  final _ReservationMock reservation;
  final _PassagerMock passager;
  final int numeroBillet, totalBillets;

  const _BilletIndividuelCard({
    required this.reservation, required this.passager,
    required this.numeroBillet, required this.totalBillets,
  });

  Color get _statutColor => switch (reservation.statut) {
    'confirmee' => YoBusColors.primary,
    'annulee'   => YoBusColors.error,
    _           => YoBusColors.textSecondary,
  };
  String get _statutLabel => switch (reservation.statut) {
    'confirmee' => 'Confirmé',
    'annulee'   => 'Annulé',
    _           => 'Terminé',
  };

  // Référence unique par passager : TB20260608001-P1
  String get _refBillet => '${reservation.ref}-P$numeroBillet';

  // QR unique par passager
  String get _qrData =>
    'TAMBOUR|${reservation.ref}|${reservation.depart}|${reservation.arrivee}|'
    '${reservation.date.toIso8601String()}|${passager.siege}|${passager.nomComplet}';

  @override
  Widget build(BuildContext context) {
    final fmt     = NumberFormat('#,###', 'fr_FR');
    final dateFmt = DateFormat('EEE d MMM · HH:mm', 'fr_FR');

    return Container(
      decoration: BoxDecoration(
        color: YoBusColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YoBusColors.border, width: 0.5)),
      child: Column(children: [
        // ── Header vert ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: YoBusColors.primaryLight,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18))),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: YoBusColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(reservation.depart, style: const TextStyle(fontFamily: 'Outfit',
                  fontSize: 14, fontWeight: FontWeight.w700, color: YoBusColors.primaryDark)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.arrow_forward_rounded, size: 12, color: YoBusColors.primary)),
                Text(reservation.arrivee, style: const TextStyle(fontFamily: 'Outfit',
                  fontSize: 14, fontWeight: FontWeight.w700, color: YoBusColors.primaryDark)),
              ]),
              Text(reservation.compagnie, style: const TextStyle(fontFamily: 'Outfit',
                fontSize: 11, color: YoBusColors.primary)),
            ])),
            // Badge numéro billet
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statutColor.withOpacity(0.3))),
                child: Text(_statutLabel, style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 11,
                  fontWeight: FontWeight.w700, color: _statutColor))),
              if (totalBillets > 1) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: YoBusColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('Billet $numeroBillet/$totalBillets',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 10,
                      fontWeight: FontWeight.w700, color: YoBusColors.primary))),
              ],
            ]),
          ])),

        // ── Corps ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // Passager + siège
            Row(children: [
              Container(width: 34, height: 34,
                decoration: BoxDecoration(
                  color: YoBusColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                  color: YoBusColors.primary, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(passager.nomComplet, style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 14,
                  fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
                Text(passager.telephone, style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: YoBusColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.event_seat_rounded,
                    size: 14, color: YoBusColors.primary),
                  const SizedBox(width: 4),
                  Text('Siège ${passager.siege}', style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 12,
                    fontWeight: FontWeight.w800, color: YoBusColors.primary)),
                ])),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 13, color: YoBusColors.textHint),
              const SizedBox(width: 6),
              Text(dateFmt.format(reservation.date), style: const TextStyle(
                fontFamily: 'Outfit', fontSize: 12,
                fontWeight: FontWeight.w600, color: YoBusColors.textPrimary)),
              const Spacer(),
              Text('${fmt.format(reservation.prixParPassager)} FCFA',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                  fontWeight: FontWeight.w800, color: YoBusColors.primary)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YoBusColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6)),
                child: Text('Réf: $_refBillet', style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 11,
                  color: YoBusColors.textSecondary, fontWeight: FontWeight.w500))),
              if (passager.email.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.email_outlined, size: 12, color: YoBusColors.textHint),
                const SizedBox(width: 4),
                Expanded(child: Text(passager.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                    color: YoBusColors.textHint))),
              ],
            ]),

            // ── Boutons Voir / Partager ───────────────────────────────────
            if (reservation.statut == 'confirmee') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _ouvrirBillet(context),
                  icon: const Icon(Icons.qr_code_rounded, size: 16),
                  label: const Text('Voir le billet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YoBusColors.primary,
                    side: const BorderSide(color: YoBusColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontFamily: 'Outfit',
                      fontSize: 13, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _partager(),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YoBusColors.primary, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontFamily: 'Outfit',
                      fontSize: 13, fontWeight: FontWeight.w700)))),
              ]),
            ],
          ])),
      ]),
    );
  }

  // ── Ouvrir la fiche billet individuelle ──────────────────────────────────
  void _ouvrirBillet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BilletDetailSheet(
        reservation: reservation, passager: passager,
        numeroBillet: numeroBillet, totalBillets: totalBillets,
        refBillet: _refBillet, qrData: _qrData));
  }

  // ── Partager ce billet ───────────────────────────────────────────────────
  Future<void> _partager() async {
    final fmt     = NumberFormat('#,###', 'fr_FR');
    final dateFmt = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');
    await Share.share(
      '🎫 Billet TamBour — $_refBillet\n\n'
      '👤 ${passager.nomComplet}\n'
      '📍 ${reservation.depart} → ${reservation.arrivee}\n'
      '📅 ${dateFmt.format(reservation.date)}\n'
      '💺 Siège ${passager.siege}\n'
      '🏢 ${reservation.compagnie}\n'
      '💰 ${fmt.format(reservation.prixParPassager)} FCFA\n\n'
      'Réservé avec TamBour 🥁 — Votre voyage, notre priorité.',
      subject: 'Mon billet TamBour — ${reservation.depart} → ${reservation.arrivee}');
  }
}

// ── Fiche détail billet (bottom sheet) avec QR + PDF ─────────────────────────

class _BilletDetailSheet extends StatefulWidget {
  final _ReservationMock reservation;
  final _PassagerMock passager;
  final int numeroBillet, totalBillets;
  final String refBillet, qrData;

  const _BilletDetailSheet({
    required this.reservation, required this.passager,
    required this.numeroBillet, required this.totalBillets,
    required this.refBillet, required this.qrData,
  });

  @override
  State<_BilletDetailSheet> createState() => _BilletDetailSheetState();
}

class _BilletDetailSheetState extends State<_BilletDetailSheet> {
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    final fmt     = NumberFormat('#,###', 'fr_FR');
    final heureFmt = DateFormat('HH:mm');
    final dateFmt  = DateFormat('dd MMMM yyyy', 'fr_FR');
    final r = widget.reservation;
    final p = widget.passager;

    return DraggableScrollableSheet(
      initialChildSize: 0.92, maxChildSize: 0.95, minChildSize: 0.6,
      builder: (context, sc) => Container(
        decoration: const BoxDecoration(
          color: YoBusColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: YoBusColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: SafeArea(bottom: false, child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Billet ${widget.numeroBillet}/${widget.totalBillets}',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 20,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(p.nomComplet, style: TextStyle(fontFamily: 'Outfit',
                      fontSize: 14, color: Colors.white.withOpacity(0.8))),
                  ])),
                  // Bouton PDF
                  GestureDetector(
                    onTap: _generatingPdf ? null : _telechargerPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: _generatingPdf
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: YoBusColors.primary))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.download_rounded, size: 16, color: YoBusColors.primary),
                            SizedBox(width: 6),
                            Text('PDF', style: TextStyle(fontFamily: 'Outfit',
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: YoBusColors.primary)),
                          ]))),
                ])),
            ])),
          ),

          // Corps
          Expanded(child: SingleChildScrollView(
            controller: sc, physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: YoBusColors.surface, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, 6))]),
              child: Column(children: [
                // Header vert du billet
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: YoBusColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                  child: Column(children: [
                    // Logo TamBour
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      RichText(text: const TextSpan(children: [
                        TextSpan(text: 'Tam', style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        TextSpan(text: 'Bour', style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 18, fontWeight: FontWeight.w900, color: YoBusColors.gold)),
                      ])),
                      if (widget.totalBillets > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                          child: Text('${widget.numeroBillet}/${widget.totalBillets}',
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                              fontWeight: FontWeight.w700, color: Colors.white))),
                    ]),
                    const SizedBox(height: 16),
                    // Trajet
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.depart, style: const TextStyle(fontFamily: 'Outfit',
                          fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Départ', style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 11, color: Colors.white.withOpacity(0.7))),
                      ])),
                      Column(children: [
                        const Icon(Icons.arrow_forward_rounded, color: YoBusColors.gold, size: 28),
                        Text(heureFmt.format(r.date), style: const TextStyle(
                          fontFamily: 'Outfit', fontSize: 14,
                          fontWeight: FontWeight.w800, color: YoBusColors.gold)),
                      ]),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(r.arrivee, style: const TextStyle(fontFamily: 'Outfit',
                          fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          textAlign: TextAlign.end),
                        Text('Arrivée', style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 11, color: Colors.white.withOpacity(0.7)),
                          textAlign: TextAlign.end),
                      ])),
                    ]),
                    const SizedBox(height: 14),
                    // Infos bas header
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _InfoCol('Date', DateFormat('dd/MM/yy').format(r.date)),
                        _InfoCol('Heure', heureFmt.format(r.date)),
                        _InfoCol('Siège', p.siege),
                        _InfoCol('Passager', p.prenom),
                      ])),
                  ])),

                // Découpe pointillés
                Row(children: [
                  Container(width: 22, height: 22,
                    decoration: const BoxDecoration(
                      color: YoBusColors.primary, shape: BoxShape.circle)),
                  Expanded(child: LayoutBuilder(builder: (_, c) {
                    const dw = 8.0, ds = 5.0;
                    final n = (c.maxWidth / (dw + ds)).floor();
                    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(n, (_) => Container(
                        width: dw, height: 1.5, color: YoBusColors.border)));
                  })),
                  Container(width: 22, height: 22,
                    decoration: const BoxDecoration(
                      color: YoBusColors.primary, shape: BoxShape.circle)),
                ]),

                // QR Code unique par passager
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: YoBusColors.border, width: 0.5)),
                      child: Column(children: [
                        QrImageView(
                          data: widget.qrData, version: QrVersions.auto, size: 180,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: YoBusColors.primary),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: YoBusColors.textPrimary)),
                        const SizedBox(height: 10),
                        Text(widget.refBillet, style: const TextStyle(
                          fontFamily: 'Outfit', fontSize: 13,
                          fontWeight: FontWeight.w700, color: YoBusColors.textSecondary,
                          letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        const Text("Présentez ce QR code à l'embarquement",
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                            color: YoBusColors.textHint)),
                      ])),

                    const SizedBox(height: 14),

                    // Infos passager
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: YoBusColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        _InfoRow(Icons.person_rounded, 'Passager', p.nomComplet),
                        const SizedBox(height: 8),
                        _InfoRow(Icons.phone_rounded, 'Téléphone', p.telephone),
                        if (p.email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoRow(Icons.email_outlined, 'Email', p.email),
                        ],
                        const SizedBox(height: 8),
                        _InfoRow(Icons.event_seat_rounded, 'Siège', p.siege),
                        const SizedBox(height: 8),
                        _InfoRow(Icons.directions_bus_rounded, 'Compagnie', r.compagnie),
                      ])),

                    const SizedBox(height: 12),

                    // Montant
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: YoBusColors.primaryLight,
                        borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.payments_rounded, color: YoBusColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Montant payé', style: TextStyle(
                          fontFamily: 'Outfit', fontSize: 13, color: YoBusColors.primary)),
                        const Spacer(),
                        Text('${fmt.format(r.prixParPassager)} FCFA',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 17,
                            fontWeight: FontWeight.w800, color: YoBusColors.primary)),
                      ])),

                    const SizedBox(height: 10),
                    Text(dateFmt.format(r.date), textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Outfit',
                        fontSize: 12, color: YoBusColors.textSecondary)),
                  ]),
                ),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  // ── PDF individuel par passager ──────────────────────────────────────────
  Future<void> _telechargerPdf() async {
    setState(() => _generatingPdf = true);
    try {
      final r = widget.reservation;
      final p = widget.passager;
      final fmt      = NumberFormat('#,###', 'fr_FR');
      final dateFmt  = DateFormat('dd/MM/yyyy HH:mm');

      // Générer QR en image
      final qrValidation = QrValidator.validate(
        data: widget.qrData, version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L);
      final qrCode = qrValidation.qrCode!;
      final painter = QrPainter.withQr(qr: qrCode,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0A7C4E)),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A1A)));
      final imgData = await painter.toImageData(300);
      final qrBytes = imgData!.buffer.asUint8List();
      final qrImg   = pw.MemoryImage(qrBytes);

      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // En-tête
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0A7C4E),
                borderRadius: pw.BorderRadius.circular(12)),
              child: pw.Column(children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('TamBour', style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  if (widget.totalBillets > 1)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(20)),
                      child: pw.Text(
                        'Billet ${widget.numeroBillet}/${widget.totalBillets}',
                        style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0A7C4E)))),
                ]),
                pw.SizedBox(height: 16),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(r.depart, style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('DÉPART', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                  ]),
                  pw.Text('→', style: pw.TextStyle(fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFFF5A623))),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text(r.arrivee, style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('ARRIVÉE', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                  ]),
                ]),
              ])),

            pw.SizedBox(height: 24),

            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              // Infos passager
              pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfInfo('Référence',    widget.refBillet),
                  _pdfInfo('Passager',     p.nomComplet),
                  _pdfInfo('Téléphone',    p.telephone),
                  if (p.email.isNotEmpty)
                    _pdfInfo('Email',      p.email),
                  _pdfInfo('Siège',        p.siege),
                  _pdfInfo('Date/Heure',   dateFmt.format(r.date)),
                  _pdfInfo('Compagnie',    r.compagnie),
                  _pdfInfo('Montant',      '${fmt.format(r.prixParPassager)} FCFA'),
                  _pdfInfo('Statut',       'Confirmé ✓'),
                ])),
              pw.SizedBox(width: 20),
              // QR
              pw.Column(children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8)),
                  child: pw.Image(qrImg, width: 140, height: 140)),
                pw.SizedBox(height: 6),
                pw.Text("QR d'embarquement",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ]),
            ]),

            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text('Ce billet est nominatif et non transférable.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text('Support : support@tambour.ci',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ])));

      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur PDF : $e'),
        backgroundColor: YoBusColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  pw.Widget _pdfInfo(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9,
        fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 12,
        fontWeight: pw.FontWeight.bold)),
    ]));
}

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _InfoCol extends StatelessWidget {
  final String label, value;
  const _InfoCol(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 10,
      color: Colors.white.withOpacity(0.7))),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
      fontWeight: FontWeight.w800, color: Colors.white)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: YoBusColors.textHint),
    const SizedBox(width: 8),
    Text('$label : ', style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
      color: YoBusColors.textSecondary)),
    Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
      fontWeight: FontWeight.w700, color: YoBusColors.textPrimary),
      overflow: TextOverflow.ellipsis)),
  ]);
}
