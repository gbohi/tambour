import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';

/// Fenêtre « Noter ce trajet » : note globale, ponctualité, confort, propreté et commentaire.
class NoterTrajetSheet extends StatefulWidget {
  final String? reservationId;  // null : billet de démonstration
  final String trajet;
  final String compagnie;

  const NoterTrajetSheet({super.key, required this.reservationId, required this.trajet, required this.compagnie});

  static Future<bool?> ouvrir(BuildContext context,
      {required String? reservationId, required String trajet, required String compagnie}) =>
    showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => NoterTrajetSheet(reservationId: reservationId, trajet: trajet, compagnie: compagnie));

  @override
  State<NoterTrajetSheet> createState() => _NoterTrajetSheetState();
}

class _NoterTrajetSheetState extends State<NoterTrajetSheet> {
  static const _libelles = ['', 'Très décevant', 'Décevant', 'Correct', 'Bon voyage', 'Excellent voyage !'];
  final _commentaireCtrl = TextEditingController();
  int _note = 0;
  final Map<String, int> _criteres = {'ponctualite': 0, 'confort': 0, 'proprete': 0};
  bool _envoi = false;

  @override
  void dispose() { _commentaireCtrl.dispose(); super.dispose(); }

  Future<void> _envoyer() async {
    setState(() => _envoi = true);
    try {
      if (widget.reservationId != null) {
        await ApiClient.instance.dio.post('/avis/', data: {
          'reservation_id': widget.reservationId,
          'note': _note,
          'commentaire': _commentaireCtrl.text.trim(),
          for (final e in _criteres.entries) if (e.value > 0) 'note_${e.key}': e.value,
        });
      }
      if (!mounted) return;
      AppSnackbar.succes(context, 'Merci ! Votre avis aide les autres voyageurs.');
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final data = e.response?.data;
      var msg = 'Impossible d\'envoyer votre avis. Réessayez.';
      if (data is Map && data['errors'] is Map) {
        for (final v in (data['errors'] as Map).values) {
          if (v is List && v.isNotEmpty) { msg = '${v.first}'; break; }
        }
      }
      if (mounted) AppSnackbar.erreur(context, msg);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      padding: EdgeInsets.only(bottom: bas),
      decoration: const BoxDecoration(color: TamBourColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: TamBourColors.border,
            borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          const Text('Comment s\'est passé votre voyage ?', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', fontSize: 19, fontWeight: FontWeight.w800,
              color: TamBourColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${widget.trajet} · ${widget.compagnie}', textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: TamBourColors.textSecondary)),
          const SizedBox(height: 18),
          _Etoiles(note: _note, taille: 40, onChange: (n) => setState(() => _note = n)),
          SizedBox(height: 22, child: Text(_libelles[_note], style: const TextStyle(fontFamily: 'Outfit',
            fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.gold))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _Critere(label: 'Ponctualité', icone: Icons.schedule_rounded, note: _criteres['ponctualite']!,
                onChange: (n) => setState(() => _criteres['ponctualite'] = n)),
              _Critere(label: 'Confort', icone: Icons.airline_seat_recline_normal_rounded, note: _criteres['confort']!,
                onChange: (n) => setState(() => _criteres['confort'] = n)),
              _Critere(label: 'Propreté', icone: Icons.cleaning_services_rounded, note: _criteres['proprete']!,
                onChange: (n) => setState(() => _criteres['proprete'] = n)),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentaireCtrl, maxLines: 3, maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Racontez votre expérience (facultatif)',
              hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textHint),
              filled: true, fillColor: TamBourColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 8),
          AppButton(label: 'Publier mon avis', icon: Icons.send_rounded, isLoading: _envoi,
            onPressed: _note == 0 ? null : _envoyer),
        ])),
      ),
    );
  }
}

class _Etoiles extends StatelessWidget {
  final int note;
  final double taille;
  final ValueChanged<int> onChange;
  const _Etoiles({required this.note, required this.taille, required this.onChange});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    for (var i = 1; i <= 5; i++)
      InkResponse(
        onTap: () => onChange(i),
        radius: taille * 0.7,
        child: Padding(
          padding: EdgeInsets.all(taille * 0.12),
          child: Icon(i <= note ? Icons.star_rounded : Icons.star_outline_rounded,
            size: taille, color: i <= note ? TamBourColors.gold : TamBourColors.border))),
  ]);
}

class _Critere extends StatelessWidget {
  final String label;
  final IconData icone;
  final int note;
  final ValueChanged<int> onChange;
  const _Critere({required this.label, required this.icone, required this.note, required this.onChange});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icone, size: 18, color: TamBourColors.primary),
    const SizedBox(width: 8),
    Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600,
        color: TamBourColors.textPrimary))),
    Flexible(flex: 2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight,
      child: _Etoiles(note: note, taille: 26, onChange: onChange))),
  ]);
}
