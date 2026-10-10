import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/passager.dart';

class TypePieceSelector extends StatelessWidget {
  final TypePiece selected;
  final ValueChanged<TypePiece> onChanged;

  const TypePieceSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: TypePiece.values.map((t) {
      final sel = selected == t;
      final lbl = switch (t) { TypePiece.cni => 'CNI', TypePiece.passeport => 'Passeport', TypePiece.permis => 'Permis' };
      final ic = switch (t) { TypePiece.cni => Icons.credit_card_rounded, TypePiece.passeport => Icons.book_rounded, TypePiece.permis => Icons.drive_eta_rounded };
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? YoBusColors.primary : YoBusColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? YoBusColors.primary : YoBusColors.border, width: sel ? 2 : 0.5)),
          child: Column(children: [
            Icon(ic, color: sel ? Colors.white : YoBusColors.textSecondary, size: 18),
            const SizedBox(height: 4),
            Text(lbl, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : YoBusColors.textSecondary)),
          ]))));
    }).toList());
  }
}
