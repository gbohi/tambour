import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/gare.dart';
import '../../../services/itineraire_service.dart';

/// Fiche de la gare sélectionnée sur la carte : infos, « Voir les trajets », « Y aller » et itinéraire.
class FicheGareBottom extends StatelessWidget {
  final Gare gare;
  final VoidCallback onVoirTrajets;
  final VoidCallback onYAller;
  final VoidCallback onFermer;
  final VoidCallback onOuvrirGps;
  final Itineraire? itineraire;
  final bool calculEnCours;

  const FicheGareBottom({
    super.key,
    required this.gare,
    required this.onVoirTrajets,
    required this.onYAller,
    required this.onFermer,
    required this.onOuvrirGps,
    this.itineraire,
    this.calculEnCours = false,
  });

  @override
  Widget build(BuildContext context) {
    final it = itineraire;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: TamBourColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: TamBourColors.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(gare.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Outfit',
                fontSize: 15, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
              const SizedBox(height: 2),
              Text('${gare.ville} · ${gare.heuresOuverture}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary)),
            ]),
          )),
          IconButton(
            onPressed: onFermer, tooltip: 'Fermer',
            icon: const Icon(Icons.close_rounded, color: TamBourColors.textHint, size: 20)),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 6),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, size: 13, color: TamBourColors.textHint), const SizedBox(width: 4),
            Expanded(child: Text(gare.adresse, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary))),
          ]),
        ),
        if (it != null) ...[
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(right: 8), child: _BlocItineraire(itineraire: it)),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: onVoirTrajets,
              icon: const Icon(Icons.confirmation_number_outlined, size: 16),
              label: const Text('Voir les trajets', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: TamBourColors.primary,
                side: const BorderSide(color: TamBourColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: calculEnCours ? null : (it == null ? onYAller : onOuvrirGps),
              icon: calculEnCours
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(it == null ? Icons.near_me_rounded : Icons.navigation_rounded, size: 16),
              label: Text(calculEnCours ? 'Calcul…' : it == null ? 'Y aller' : 'Démarrer le GPS',
                maxLines: 1, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: TamBourColors.primary, foregroundColor: Colors.white,
                disabledBackgroundColor: TamBourColors.primary.withOpacity(0.7), disabledForegroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700)))),
          ]),
        ),
      ]),
    );
  }
}

class _BlocItineraire extends StatelessWidget {
  final Itineraire itineraire;
  const _BlocItineraire({required this.itineraire});

  @override
  Widget build(BuildContext context) {
    final it = itineraire;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Mode(icone: Icons.directions_car_rounded, duree: Itineraire.dureeLabel(it.dureeVoiture), principal: true),
          const SizedBox(width: 16),
          _Mode(icone: Icons.directions_walk_rounded, duree: Itineraire.dureeLabel(it.dureeMarche)),
          const Spacer(),
          Text(it.distanceLabel, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
            fontWeight: FontWeight.w700, color: TamBourColors.primaryDark)),
        ]),
        if (it.estimation) ...[
          const SizedBox(height: 6),
          const Text('Estimation à vol d\'oiseau (itinéraire routier indisponible).',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textSecondary)),
        ],
      ]),
    );
  }
}

class _Mode extends StatelessWidget {
  final IconData icone;
  final String duree;
  final bool principal;
  const _Mode({required this.icone, required this.duree, this.principal = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icone, size: 18, color: principal ? TamBourColors.primary : TamBourColors.textSecondary),
    const SizedBox(width: 4),
    Text(duree, style: TextStyle(fontFamily: 'Outfit', fontSize: principal ? 16 : 13,
      fontWeight: principal ? FontWeight.w800 : FontWeight.w600,
      color: principal ? TamBourColors.primary : TamBourColors.textSecondary)),
  ]);
}
