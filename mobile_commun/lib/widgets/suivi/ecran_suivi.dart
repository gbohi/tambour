import 'package:flutter/material.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/models/suivi.dart';
import 'package:tambour_commun/widgets/suivi/carte_suivi.dart';
import 'package:tambour_commun/widgets/suivi/panneau_arrivee.dart';
import 'package:tambour_commun/widgets/suivi/suivi_controleur.dart';

/// Écran « Suivre le car » : carte plein écran et panneau d'arrivée, actualisés automatiquement.
class EcranSuivi extends StatefulWidget {
  final SuiviControleur controleur;
  final String libelleArrivee;
  /// Contenu ajouté sous le panneau (ex. état du partage de position côté chauffeur).
  final Widget? complement;
  final String userAgent;
  const EcranSuivi({super.key, required this.controleur, this.libelleArrivee = 'Arrivée',
    this.complement, this.userAgent = 'ci.tambour.app'});
  @override
  State<EcranSuivi> createState() => _EcranSuiviState();
}

class _EcranSuiviState extends State<EcranSuivi> {
  @override
  void initState() {
    super.initState();
    widget.controleur.addListener(_maj);
    if (widget.controleur.suivi == null) widget.controleur.rafraichir();
  }

  @override
  void dispose() { widget.controleur.removeListener(_maj); super.dispose(); }

  void _maj() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final c = widget.controleur;
    final s = c.suivi;
    return Scaffold(
      backgroundColor: TamBourColors.background,
      appBar: AppBar(
        backgroundColor: TamBourColors.marque, foregroundColor: Colors.white,
        title: Text(s == null ? 'Suivi du car' : '${s.depart} → ${s.arrivee}',
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [IconButton(tooltip: 'Actualiser', onPressed: c.rafraichir, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: s == null
        ? Center(child: c.erreur == null
            ? const CircularProgressIndicator(color: TamBourColors.primary)
            : _Erreur(message: c.erreur!, onReessayer: c.rafraichir))
        : Column(children: [
            Expanded(child: CarteSuivi(suivi: s, userAgent: widget.userAgent)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: const BoxDecoration(color: TamBourColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))]),
              child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                PanneauArrivee(suivi: s, libelle: widget.libelleArrivee),
                if (c.erreur != null) ...[
                  const SizedBox(height: 10),
                  Text('Connexion instable : dernières informations affichées.', style: TextStyle(fontFamily: 'Outfit',
                    fontSize: 12, color: TamBourColors.error.withValues(alpha: 0.9))),
                ],
                const SizedBox(height: 14),
                _InfosCar(suivi: s),
                if (widget.complement != null) ...[const SizedBox(height: 12), widget.complement!],
              ])),
            ),
          ]),
    );
  }
}

class _InfosCar extends StatelessWidget {
  final SuiviTrajet suivi;
  const _InfosCar({required this.suivi});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: TamBourColors.marque, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(suivi.compagnie, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Outfit',
          fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
        Text(suivi.busImmatriculation.isEmpty ? suivi.statutLabel : 'Car ${suivi.busImmatriculation} · ${suivi.statutLabel}',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary)),
      ])),
    ]),
  );
}

class _Erreur extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;
  const _Erreur({required this.message, required this.onReessayer});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 44, color: TamBourColors.textHint),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', color: TamBourColors.textSecondary)),
      const SizedBox(height: 16),
      FilledButton(onPressed: onReessayer, style: FilledButton.styleFrom(backgroundColor: TamBourColors.primary),
        child: const Text('Réessayer')),
    ]),
  );
}
