/// Frais de service fixés par l'administrateur (Paramètres › Frais de service).
/// Même calcul que le serveur (plateforme.models.ParametresPlateforme.calculer_frais),
/// qui reste la référence au moment de la réservation.
class TarifsPlateforme {
  /// par_reservation | par_passager | pourcentage
  final String mode;
  final double valeur;
  final int minimum;
  final bool remboursables;
  final String libelle;

  const TarifsPlateforme({required this.mode, required this.valeur, this.minimum = 0,
    this.remboursables = false, this.libelle = ''});

  /// Valeur par défaut tant que l'API n'a pas répondu (hors ligne) : 500 FCFA par réservation.
  static const parDefaut = TarifsPlateforme(mode: 'par_reservation', valeur: 500, libelle: '500 FCFA par réservation');

  factory TarifsPlateforme.fromJson(Map<String, dynamic> j) => TarifsPlateforme(
    mode: j['frais_service_mode'] as String? ?? 'par_reservation',
    valeur: (j['frais_service_valeur'] as num?)?.toDouble() ?? 0,
    minimum: (j['frais_service_minimum'] as num?)?.round() ?? 0,
    remboursables: j['frais_remboursables'] as bool? ?? false,
    libelle: j['libelle_frais'] as String? ?? '',
  );

  /// Frais en FCFA pour une réservation, arrondis à 5 FCFA (plus petite pièce).
  int frais(int montantBillets, int nbPassagers) {
    final double f = switch (mode) {
      'par_passager' => valeur * nbPassagers,
      'pourcentage' => (montantBillets * valeur / 100).clamp(minimum.toDouble(), double.infinity),
      _ => valeur,
    };
    return (f / 5).round() * 5;
  }

  Devis devis(int prixUnitaire, int nbPassagers) {
    final billets = prixUnitaire * nbPassagers;
    final f = frais(billets, nbPassagers);
    return Devis(prixUnitaire: prixUnitaire, nbPassagers: nbPassagers, montantBillets: billets,
      fraisService: f, montantTotal: billets + f, libelleFrais: libelle, fraisRemboursables: remboursables);
  }
}

/// Détail du prix : TTC = prix des billets + frais de service.
class Devis {
  final int prixUnitaire, nbPassagers, montantBillets, fraisService, montantTotal;
  final String libelleFrais;
  final bool fraisRemboursables;
  const Devis({required this.prixUnitaire, required this.nbPassagers, required this.montantBillets,
    required this.fraisService, required this.montantTotal, this.libelleFrais = '', this.fraisRemboursables = false});
}
