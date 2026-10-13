import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/ligne_populaire.dart';
import 'package:tambour_passager/providers/recherche_provider.dart';

/// Lance la recherche des départs de demain sur cette ligne.
void rechercherLigne(BuildContext context, LignePopulaire l) {
  context.push('/resultats', extra: RechercheParams(
    villeDepart: l.villeDepart, villeArrivee: l.villeArrivee,
    date: DateTime.now().add(const Duration(days: 1)), nbPassagers: 1));
}

/// Carte compacte d'une ligne (carrousel de l'accueil).
class LigneCard extends StatelessWidget {
  final LignePopulaire ligne;
  const LigneCard({super.key, required this.ligne});

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    return InkWell(
      onTap: () => rechercherLigne(context, l),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 190, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TamBourColors.border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.depart, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
            const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 14, color: TamBourColors.textHint), const SizedBox(width: 6),
            Expanded(child: Text(l.arrivee, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary))),
          ]),
          const SizedBox(height: 8),
          LigneInfos(ligne: l),
          const Spacer(),
          LignePrix(prix: l.prixMin),
        ]),
      ),
    );
  }
}

/// Ligne pleine largeur (page « Lignes populaires »).
class LigneTile extends StatelessWidget {
  final LignePopulaire ligne;
  const LigneTile({super.key, required this.ligne});

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    return InkWell(
      onTap: () => rechercherLigne(context, l),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TamBourColors.border, width: 0.5)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.directions_bus_rounded, color: TamBourColors.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text('${l.depart}  →  ${l.arrivee}', overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary))),
              if (l.estPopulaire) ...[
                const SizedBox(width: 6),
                const Icon(Icons.local_fire_department_rounded, size: 16, color: TamBourColors.gold),
              ],
            ]),
            const SizedBox(height: 6),
            LigneInfos(ligne: l),
          ])),
          const SizedBox(width: 8),
          LignePrix(prix: l.prixMin),
        ]),
      ),
    );
  }
}

class LigneInfos extends StatelessWidget {
  final LignePopulaire ligne;
  const LigneInfos({super.key, required this.ligne});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary);
    return Row(children: [
      if (ligne.dureeLabel != null) ...[
        const Icon(Icons.access_time_rounded, size: 13, color: TamBourColors.textHint), const SizedBox(width: 4),
        Text(ligne.dureeLabel!, style: style),
        const SizedBox(width: 10),
      ],
      if (ligne.trajetsParJour > 0) ...[
        const Icon(Icons.directions_bus_rounded, size: 13, color: TamBourColors.textHint), const SizedBox(width: 4),
        Text('${ligne.trajetsParJour}/jour', style: style),
      ],
    ]);
  }
}

class LignePrix extends StatelessWidget {
  final int? prix;
  const LignePrix({super.key, required this.prix});

  @override
  Widget build(BuildContext context) {
    if (prix == null) {
      return const Text('Voir les départs', style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
        fontWeight: FontWeight.w600, color: TamBourColors.primary));
    }
    return RichText(text: TextSpan(children: [
      const TextSpan(text: 'Dès ', style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textHint)),
      TextSpan(text: '${NumberFormat('#,###', 'fr_FR').format(prix)} F', style: const TextStyle(
        fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: TamBourColors.primary)),
    ]));
  }
}
