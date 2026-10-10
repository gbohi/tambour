enum MethodePaiement { mtnMomo, orangeMoney, wave, carte }
enum StatutPaiement { attente, enCours, succes, echec, expire }

class PaiementRequest {
  final String trajetId;
  final int montantFcfa;
  final MethodePaiement methode;
  final String telephone;

  const PaiementRequest({
    required this.trajetId,
    required this.montantFcfa, required this.methode, required this.telephone,
  });

  Map<String, dynamic> toJson() => {
    'trajet_id': trajetId,
    'montant_fcfa': montantFcfa, 'methode': methode.name, 'telephone': telephone,
  };
}

class PaiementResult {
  final String referenceTransaction;
  final StatutPaiement statut;
  final DateTime timestamp;
  final int montantFcfa;
  final MethodePaiement methode;

  const PaiementResult({
    required this.referenceTransaction, required this.statut,
    required this.timestamp, required this.montantFcfa, required this.methode,
  });
}
