import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../providers/recherche_provider.dart';

class FiltreBar extends StatelessWidget {
  final TriOption triActif;
  final FiltreClasse filtreClasseActif;
  final ValueChanged<TriOption> onTriChange;
  final ValueChanged<FiltreClasse> onFiltreClasseChange;

  const FiltreBar({super.key, required this.triActif, required this.filtreClasseActif, required this.onTriChange, required this.onFiltreClasseChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YoBusColors.surface,
      child: Column(children: [
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), children: [
          _TriChip(label: 'Horaire', icon: Icons.access_time_rounded, actif: triActif == TriOption.horaire, onTap: () => onTriChange(TriOption.horaire)),
          const SizedBox(width: 8),
          _TriChip(label: 'Prix', icon: Icons.attach_money_rounded, actif: triActif == TriOption.prix, onTap: () => onTriChange(TriOption.prix)),
          const SizedBox(width: 8),
          _TriChip(label: 'Durée', icon: Icons.timer_outlined, actif: triActif == TriOption.duree, onTap: () => onTriChange(TriOption.duree)),
          const SizedBox(width: 8),
          _TriChip(label: 'Note', icon: Icons.star_rounded, actif: triActif == TriOption.note, onTap: () => onTriChange(TriOption.note)),
        ])),
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), children: [
          _ClasseChip(label: 'Tous', actif: filtreClasseActif == FiltreClasse.tous, onTap: () => onFiltreClasseChange(FiltreClasse.tous)),
          const SizedBox(width: 8),
          _ClasseChip(label: 'Standard', actif: filtreClasseActif == FiltreClasse.standard, onTap: () => onFiltreClasseChange(FiltreClasse.standard)),
          const SizedBox(width: 8),
          _ClasseChip(label: 'Confort', actif: filtreClasseActif == FiltreClasse.confort, color: YoBusColors.primary, onTap: () => onFiltreClasseChange(FiltreClasse.confort)),
          const SizedBox(width: 8),
          _ClasseChip(label: 'VIP', actif: filtreClasseActif == FiltreClasse.vip, color: YoBusColors.gold, onTap: () => onFiltreClasseChange(FiltreClasse.vip)),
        ])),
        const Divider(height: 1),
      ]),
    );
  }
}

class _TriChip extends StatelessWidget {
  final String label; final IconData icon; final bool actif; final VoidCallback onTap;
  const _TriChip({required this.label, required this.icon, required this.actif, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: actif ? YoBusColors.primary : YoBusColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: actif ? Colors.white : YoBusColors.textSecondary), const SizedBox(width: 5),
        Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: actif ? Colors.white : YoBusColors.textSecondary)),
      ])));
  }
}

class _ClasseChip extends StatelessWidget {
  final String label; final bool actif; final VoidCallback onTap; final Color color;
  const _ClasseChip({required this.label, required this.actif, required this.onTap, this.color = YoBusColors.textSecondary});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: actif ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: actif ? color : YoBusColors.border, width: actif ? 1.5 : 0.5)),
      child: Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: actif ? color : YoBusColors.textSecondary))));
  }
}
