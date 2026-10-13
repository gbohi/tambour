import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/ligne_populaire.dart';
import 'package:tambour_passager/providers/ligne_provider.dart';
import 'package:tambour_passager/widgets/ligne_card.dart';
import 'package:tambour_commun/widgets/page_header.dart';

class LignesPopulairesScreen extends ConsumerStatefulWidget {
  const LignesPopulairesScreen({super.key});
  @override
  ConsumerState<LignesPopulairesScreen> createState() => _LignesPopulairesScreenState();
}

class _LignesPopulairesScreenState extends ConsumerState<LignesPopulairesScreen> {
  String _recherche = '';

  List<LignePopulaire> _filtrer(List<LignePopulaire> lignes) {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return lignes;
    return lignes.where((l) =>
      l.depart.toLowerCase().contains(q) || l.arrivee.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lignes = ref.watch(lignesPopulairesProvider);
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(children: [
        const PageHeader(titre: 'Lignes populaires', sousTitre: 'Toutes les lignes desservies'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _recherche = v),
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Rechercher une ville…',
              prefixIcon: const Icon(Icons.search_rounded, color: TamBourColors.textHint, size: 20),
              filled: true, fillColor: TamBourColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: TamBourColors.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: TamBourColors.border, width: 0.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16))),
        ),
        Expanded(child: lignes.when(
          loading: () => const Center(child: CircularProgressIndicator(color: TamBourColors.primary)),
          error: (_, __) => const SizedBox(),
          data: (toutes) {
            final liste = _filtrer(toutes);
            if (liste.isEmpty) {
              return const Center(child: Text('Aucune ligne trouvée',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 15, color: TamBourColors.textHint)));
            }
            return RefreshIndicator(
              color: TamBourColors.primary,
              onRefresh: () => ref.refresh(lignesPopulairesProvider.future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: liste.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => LigneTile(ligne: liste[i])
                  .animate().fadeIn(delay: Duration(milliseconds: 40 * i.clamp(0, 10))),
              ),
            );
          },
        )),
      ]),
    );
  }
}
