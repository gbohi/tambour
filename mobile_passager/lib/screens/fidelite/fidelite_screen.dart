import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/fidelite.dart';
import 'package:tambour_passager/providers/fidelite_provider.dart';
import 'package:tambour_commun/widgets/page_header.dart';

class FideliteScreen extends ConsumerWidget {
  const FideliteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fidelite = ref.watch(fideliteProvider);
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        const PageHeader(titre: 'Programme fidélité', sousTitre: 'Voyagez, parrainez, gagnez des points'),
        Expanded(child: fidelite.when(
          loading: () => const Center(child: CircularProgressIndicator(color: TamBourColors.primary)),
          error: (_, __) => _Erreur(onReessayer: () => ref.invalidate(fideliteProvider)),
          data: (f) => RefreshIndicator(
            color: TamBourColors.primary,
            onRefresh: () => ref.refresh(fideliteProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _CartePoints(info: f).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 16),
                _CodeParrainage(info: f).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 24),
                const _Titre('Comment ça marche ?'),
                const SizedBox(height: 12),
                _EtapesInvitation(info: f).animate().fadeIn(delay: 180.ms),
                const SizedBox(height: 24),
                const _Titre('Historique des points'),
                const SizedBox(height: 12),
                _Historique(mouvements: f.historique).animate().fadeIn(delay: 240.ms),
              ],
            ),
          ),
        )),
      ]),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);
  @override
  Widget build(BuildContext context) => Text(texte, style: const TextStyle(fontFamily: 'Outfit',
    fontSize: 17, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary));
}

// ── Solde de points ──────────────────────────────────────────────────────────

class _CartePoints extends StatelessWidget {
  final FideliteInfo info;
  const _CartePoints({required this.info});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [TamBourColors.primary, TamBourColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: TamBourColors.primary.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: TamBourColors.gold.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: TamBourColors.gold, size: 20)),
          const SizedBox(width: 10),
          Text('Mes points', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Colors.white.withOpacity(0.85))),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmt.format(info.points), style: const TextStyle(fontFamily: 'Outfit', fontSize: 40,
            fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          const SizedBox(width: 8),
          const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('pts', style: TextStyle(
            fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: TamBourColors.gold))),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _Stat(valeur: '${info.nbVoyages}', label: 'Voyages'),
          _Stat(valeur: '${info.nbFilleuls}', label: 'Amis parrainés'),
          _Stat(valeur: fmt.format(info.pointsParrainage), label: 'Pts parrainage'),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String valeur, label;
  const _Stat({required this.valeur, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(valeur, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
    Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.white.withOpacity(0.7))),
  ]));
}

// ── Code de parrainage ───────────────────────────────────────────────────────

class _CodeParrainage extends StatelessWidget {
  final FideliteInfo info;
  const _CodeParrainage({required this.info});

  void _copier(BuildContext context) {
    Clipboard.setData(ClipboardData(text: info.codeParrainage));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Code copié', style: TextStyle(fontFamily: 'Outfit')),
      backgroundColor: TamBourColors.primary, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: TamBourColors.goldLight, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TamBourColors.gold.withOpacity(0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mon code de parrainage', style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
          fontWeight: FontWeight.w700, color: Color(0xFF7A4F00))),
        const SizedBox(height: 4),
        Text('Vous gagnez ${info.pointsParrain} pts et votre ami ${info.pointsFilleul} pts à son inscription.',
          style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: const Color(0xFF7A4F00).withOpacity(0.8))),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => _copier(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TamBourColors.gold.withOpacity(0.5), width: 1.2)),
            child: Row(children: [
              Expanded(child: Text(info.codeParrainage, style: const TextStyle(fontFamily: 'Outfit',
                fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: TamBourColors.textPrimary))),
              const Icon(Icons.copy_rounded, color: TamBourColors.gold, size: 20),
              const SizedBox(width: 6),
              const Text('Copier', style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                fontWeight: FontWeight.w700, color: TamBourColors.gold)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => SharePlus.instance.share(ShareParams(
            text: info.messagePartage, subject: 'Rejoins-moi sur TamBour')),
          icon: const Icon(Icons.share_rounded, size: 18),
          label: const Text('Inviter des amis'),
          style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.primary, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}

// ── Processus d'invitation ───────────────────────────────────────────────────

class _EtapesInvitation extends StatelessWidget {
  final FideliteInfo info;
  const _EtapesInvitation({required this.info});

  @override
  Widget build(BuildContext context) {
    final etapes = [
      (Icons.send_rounded, 'Invitez vos amis',
        'Partagez votre code de parrainage par WhatsApp, SMS ou réseaux sociaux.'),
      (Icons.download_rounded, 'Ils téléchargent et s\'inscrivent',
        'Vos amis installent TamBour et saisissent votre code lors de leur inscription.'),
      (Icons.card_giftcard_rounded, 'Obtenez des récompenses',
        'Vous gagnez ${info.pointsParrain} points par ami inscrit, et votre ami reçoit ${info.pointsFilleul} points de bienvenue.'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Column(children: [
        for (var i = 0; i < etapes.length; i++)
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 40, height: 40,
                decoration: const BoxDecoration(color: TamBourColors.primary, shape: BoxShape.circle),
                child: Center(child: Text('${i + 1}', style: const TextStyle(fontFamily: 'Outfit',
                  fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)))),
              if (i < etapes.length - 1)
                Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4),
                  color: TamBourColors.primary.withOpacity(0.2))),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Padding(
              padding: EdgeInsets.only(bottom: i < etapes.length - 1 ? 18 : 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(etapes[i].$1, size: 16, color: TamBourColors.gold),
                  const SizedBox(width: 6),
                  Expanded(child: Text(etapes[i].$2, style: const TextStyle(fontFamily: 'Outfit',
                    fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary))),
                ]),
                const SizedBox(height: 4),
                Text(etapes[i].$3, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                  color: TamBourColors.textSecondary, height: 1.4)),
              ]),
            )),
          ])),
      ]),
    );
  }
}

// ── Historique ───────────────────────────────────────────────────────────────

class _Historique extends StatelessWidget {
  final List<MouvementPoints> mouvements;
  const _Historique({required this.mouvements});

  IconData _icone(String motif) => switch (motif) {
    'voyage' => Icons.directions_bus_rounded,
    'parrainage' => Icons.people_alt_rounded,
    'bienvenue' => Icons.card_giftcard_rounded,
    'utilisation' => Icons.redeem_rounded,
    _ => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (mouvements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TamBourColors.border, width: 0.5)),
        child: const Column(children: [
          Icon(Icons.hourglass_empty_rounded, color: TamBourColors.textHint, size: 32),
          SizedBox(height: 8),
          Text('Aucun point pour le moment.\nVoyagez ou invitez un ami pour commencer !', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textSecondary)),
        ]),
      );
    }
    final fmtDate = DateFormat('d MMM yyyy', 'fr_FR');
    return Container(
      decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TamBourColors.border, width: 0.5)),
      child: Column(children: [
        for (var i = 0; i < mouvements.length; i++) ...[
          ListTile(
            leading: Container(width: 38, height: 38,
              decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(_icone(mouvements[i].motif), color: TamBourColors.primary, size: 18)),
            title: Text(mouvements[i].description.isNotEmpty ? mouvements[i].description : mouvements[i].motifLabel,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600, color: TamBourColors.textPrimary)),
            subtitle: Text(fmtDate.format(mouvements[i].date.toLocal()),
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textHint)),
            trailing: Text('${mouvements[i].points > 0 ? '+' : ''}${mouvements[i].points}',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800,
                color: mouvements[i].points >= 0 ? TamBourColors.primary : TamBourColors.error)),
          ),
          if (i < mouvements.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ]),
    );
  }
}

class _Erreur extends StatelessWidget {
  final VoidCallback onReessayer;
  const _Erreur({required this.onReessayer});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: TamBourColors.textHint),
      const SizedBox(height: 12),
      const Text('Impossible de charger votre programme fidélité.\nVérifiez votre connexion ou reconnectez-vous.',
        textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: onReessayer, child: const Text('Réessayer')),
    ]),
  ));
}
