import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/support.dart';
import 'package:tambour_passager/providers/support_provider.dart';
import 'package:tambour_commun/widgets/page_header.dart';

class CentreAideScreen extends ConsumerStatefulWidget {
  const CentreAideScreen({super.key});
  @override
  ConsumerState<CentreAideScreen> createState() => _CentreAideScreenState();
}

class _CentreAideScreenState extends ConsumerState<CentreAideScreen> {
  String _recherche = '';

  List<CategorieFAQ> _filtrer(List<CategorieFAQ> cats) {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return cats;
    return cats
      .map((c) => CategorieFAQ(c.code, c.label, c.questions.where((x) =>
        x.question.toLowerCase().contains(q) || x.reponse.toLowerCase().contains(q)).toList()))
      .where((c) => c.questions.isNotEmpty)
      .toList();
  }

  @override
  Widget build(BuildContext context) {
    final faq = ref.watch(faqProvider);
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        PageHeader(
          titre: "Centre d'aide", sousTitre: 'Comment pouvons-nous vous aider ?',
          bas: TextField(
            onChanged: (v) => setState(() => _recherche = v),
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Rechercher (paiement, billet, points…)',
              prefixIcon: const Icon(Icons.search_rounded, color: TamBourColors.textHint, size: 20),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)))),
        Expanded(child: faq.when(
          loading: () => const Center(child: CircularProgressIndicator(color: TamBourColors.primary)),
          error: (_, __) => const SizedBox(),
          data: (toutes) {
            final cats = _filtrer(toutes);
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                if (cats.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text(
                    'Aucune réponse trouvée.\nContactez-nous, nous vous aiderons !', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)))),
                for (final c in cats) ...[
                  Padding(padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4), child: Text(c.label,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700,
                      color: TamBourColors.textSecondary, letterSpacing: 0.5))),
                  // Material (et non Container coloré) : l'effet d'appui des questions reste visible
                  Material(
                    color: TamBourColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: TamBourColors.border, width: 0.5)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      for (final q in c.questions)
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: TamBourColors.primary, collapsedIconColor: TamBourColors.textHint,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            expandedAlignment: Alignment.centerLeft,
                            title: Text(q.question, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                              fontWeight: FontWeight.w600, color: TamBourColors.textPrimary)),
                            children: [Text(q.reponse, style: const TextStyle(fontFamily: 'Outfit',
                              fontSize: 13, height: 1.5, color: TamBourColors.textSecondary))],
                          ),
                        ),
                    ]),
                  ).animate().fadeIn(duration: 250.ms),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                _BesoinAide(),
              ],
            );
          },
        )),
      ]),
    );
  }
}

class _BesoinAide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Vous n'avez pas trouvé votre réponse ?", style: TextStyle(fontFamily: 'Outfit',
          fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.primaryDark)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => context.push('/support'),
            icon: const Icon(Icons.headset_mic_rounded, size: 18),
            label: const Text('Support'),
            style: OutlinedButton.styleFrom(foregroundColor: TamBourColors.primary,
              side: const BorderSide(color: TamBourColors.primary), minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => context.push('/reclamations'),
            icon: const Icon(Icons.report_problem_rounded, size: 18),
            label: const Text('Réclamation'),
            style: ElevatedButton.styleFrom(backgroundColor: TamBourColors.primary, foregroundColor: Colors.white,
              elevation: 0, minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ]),
      ]),
    );
  }
}
