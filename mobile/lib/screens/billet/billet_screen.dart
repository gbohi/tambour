import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../models/paiement.dart';
import '../../models/trajet.dart';
import '../../models/billet.dart';
import '../../providers/passager_provider.dart';
import '../../providers/recherche_provider.dart';
import '../../providers/siege_provider.dart';
import '../billets/mes_billets_screen.dart';

class BilletScreen extends ConsumerWidget {
  final Trajet trajet;
  final RechercheParams params;
  final PaiementResult result;

  const BilletScreen({
    super.key,
    required this.trajet,
    required this.params,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passagers = ref.watch(passagerProvider).passagers;
    final emailPayeur = ref.watch(passagerProvider).emailPayeur;

    // Générer 1 billet par passager
    final billets = Billet.creerDepuisReservation(
      referenceReservation: result.referenceTransaction,
      trajet: trajet,
      passagers: passagers,
      paiement: result,
    );

    return Scaffold(
      backgroundColor: YoBusColors.primary,
      body: Column(children: [
        _Header(),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(children: [
            _SuccessAnimation(nbBillets: billets.length),
            const SizedBox(height: 20),
            // Email payeur
            if (emailPayeur.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.email_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${billets.length} billet${billets.length > 1 ? 's' : ''} envoyé${billets.length > 1 ? 's' : ''} à $emailPayeur',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white),
                  )),
                ])).animate().fadeIn(delay: 350.ms),
            // Un billet par passager
            ...billets.asMap().entries.map((e) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BilletIndividuel(billet: e.value)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 400 + e.key * 150), duration: 500.ms)
                  .slideY(begin: 0.1, end: 0),
              )),
            const SizedBox(height: 8),
            _Actions(
              onAccueil:    () => Navigator.of(context).popUntil((r) => r.isFirst),
              onMesBillets: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ]),
        )),
      ]),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(children: [
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 18))),
      ])));
  }
}

// ── Animation succès ──────────────────────────────────────────────────────────

class _SuccessAnimation extends StatelessWidget {
  final int nbBillets;
  const _SuccessAnimation({required this.nbBillets});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))
          .animate(onPlay: (c) => c.repeat())
          .scale(begin: const Offset(1,1), end: const Offset(1.15,1.15), duration: 1200.ms)
          .then().scale(begin: const Offset(1.15,1.15), end: const Offset(1,1), duration: 1200.ms),
        Container(width: 72, height: 72,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: YoBusColors.primary, size: 38))
          .animate().scale(begin: const Offset(0,0), end: const Offset(1,1),
            duration: 500.ms, curve: Curves.elasticOut),
      ]),
      const SizedBox(height: 18),
      const Text('Réservation confirmée !', style: TextStyle(
        fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))
        .animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      const SizedBox(height: 6),
      Text(
        nbBillets > 1
          ? '$nbBillets billets générés. Bon voyage !'
          : 'Votre billet est prêt. Bon voyage !',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Colors.white.withOpacity(0.8)))
        .animate().fadeIn(delay: 400.ms),
    ]);
  }
}

// ── Billet individuel (1 par passager) ───────────────────────────────────────

class _BilletIndividuel extends StatelessWidget {
  final Billet billet;
  const _BilletIndividuel({required this.billet});

  @override
  Widget build(BuildContext context) {
    final fmt     = NumberFormat('#,###', 'fr_FR');
    final heureFmt = DateFormat('HH:mm');
    final dateFmt  = DateFormat('dd/MM/yy');
    final b = billet;

    return Container(
      decoration: BoxDecoration(
        color: YoBusColors.surface, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(children: [
        // Header vert
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: YoBusColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Column(children: [
            // Logo + numéro billet
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Tam', style: TextStyle(fontFamily: 'Outfit',
                  fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                TextSpan(text: 'Bour', style: TextStyle(fontFamily: 'Outfit',
                  fontSize: 16, fontWeight: FontWeight.w900, color: YoBusColors.gold)),
              ])),
              if (b.totalBillets > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('${b.numeroBillet}/${b.totalBillets}', style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 11,
                    fontWeight: FontWeight.w800, color: Colors.white))),
            ]),
            const SizedBox(height: 14),
            // Trajet
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.trajet.depart.nom, style: const TextStyle(fontFamily: 'Outfit',
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('Départ', style: TextStyle(fontFamily: 'Outfit',
                  fontSize: 10, color: Colors.white.withOpacity(0.7))),
              ])),
              Column(children: [
                const Icon(Icons.arrow_forward_rounded, color: YoBusColors.gold, size: 24),
                Text(heureFmt.format(b.trajet.heureDepart), style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w800,
                  color: YoBusColors.gold)),
              ]),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(b.trajet.arrivee.nom, style: const TextStyle(fontFamily: 'Outfit',
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.end),
                Text('Arrivée', style: TextStyle(fontFamily: 'Outfit',
                  fontSize: 10, color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.end),
              ])),
            ]),
            const SizedBox(height: 12),
            // Infos bas header
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _InfoCol('Date',  dateFmt.format(b.trajet.heureDepart)),
                _InfoCol('Heure', heureFmt.format(b.trajet.heureDepart)),
                _InfoCol('Siège', b.passager.siegeId),
                _InfoCol('Passager', b.passager.prenom),
              ])),
          ])),

        // Pointillés
        Row(children: [
          Container(width: 20, height: 20,
            decoration: const BoxDecoration(color: YoBusColors.primary, shape: BoxShape.circle)),
          Expanded(child: LayoutBuilder(builder: (_, c) {
            const dw = 8.0, ds = 5.0;
            final n = (c.maxWidth / (dw + ds)).floor();
            return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(n, (_) => Container(
                width: dw, height: 1.5, color: YoBusColors.border)));
          })),
          Container(width: 20, height: 20,
            decoration: const BoxDecoration(color: YoBusColors.primary, shape: BoxShape.circle)),
        ]),

        // Corps
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // QR Code unique
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YoBusColors.border, width: 0.5)),
              child: Column(children: [
                QrImageView(
                  data: b.codeQr, version: QrVersions.auto, size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: YoBusColors.primary),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: YoBusColors.textPrimary)),
                const SizedBox(height: 8),
                Text(b.referenceBillet, style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700,
                  color: YoBusColors.textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                const Text("Présentez ce QR à l'embarquement", style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint)),
              ])),
            const SizedBox(height: 14),
            // Infos passager
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YoBusColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _InfoLigne(Icons.person_rounded,    'Passager',   b.passager.nomComplet),
                const SizedBox(height: 8),
                _InfoLigne(Icons.phone_rounded,     'Téléphone',  b.passager.telephone),
                if (b.passager.aEmail) ...[
                  const SizedBox(height: 8),
                  _InfoLigne(Icons.email_outlined,  'Email',      b.passager.email),
                ],
                const SizedBox(height: 8),
                _InfoLigne(Icons.event_seat_rounded,'Siège',      b.passager.siegeId),
                const SizedBox(height: 8),
                _InfoLigne(Icons.directions_bus_rounded, 'Compagnie', b.trajet.compagnie),
              ])),
            const SizedBox(height: 12),
            // Montant
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YoBusColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.payments_rounded, color: YoBusColors.primary, size: 20),
                const SizedBox(width: 10),
                const Text('Montant payé', style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 13, color: YoBusColors.primary)),
                const Spacer(),
                Text('${fmt.format(b.paiement.montantFcfa)} FCFA', style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800,
                  color: YoBusColors.primary)),
              ])),
          ])),
      ]),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label, value;
  const _InfoCol(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 9,
      color: Colors.white.withOpacity(0.7))),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
      fontWeight: FontWeight.w800, color: Colors.white)),
  ]);
}

class _InfoLigne extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoLigne(this.icon, this.label, this.value);
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

// ── Actions ───────────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  final VoidCallback onAccueil, onMesBillets;
  const _Actions({required this.onAccueil, required this.onMesBillets});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(width: double.infinity, height: 54,
        child: ElevatedButton.icon(
          onPressed: onMesBillets,
          icon: const Icon(Icons.confirmation_number_rounded, size: 20),
          label: const Text('Voir mes billets'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, foregroundColor: YoBusColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 54,
        child: OutlinedButton.icon(
          onPressed: onAccueil,
          icon: const Icon(Icons.home_rounded, size: 20),
          label: const Text("Retour à l'accueil"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600)))),
    ]);
  }
}
