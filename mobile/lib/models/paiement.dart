import 'package:flutter/material.dart';

/// Ordre d'affichage : Orange Money, Wave, MTN MoMo, Moov Money, puis carte.
enum MethodePaiement { orangeMoney, wave, mtnMomo, moovMoney, carte }

extension InfosMethodePaiement on MethodePaiement {
  /// Valeur attendue par l'API.
  String get code => switch (this) {
    MethodePaiement.orangeMoney => 'orange_money',
    MethodePaiement.wave => 'wave',
    MethodePaiement.mtnMomo => 'mtn_momo',
    MethodePaiement.moovMoney => 'moov_money',
    MethodePaiement.carte => 'carte',
  };

  String get nom => switch (this) {
    MethodePaiement.orangeMoney => 'Orange Money',
    MethodePaiement.wave => 'Wave',
    MethodePaiement.mtnMomo => 'MTN Mobile Money',
    MethodePaiement.moovMoney => 'Moov Money',
    MethodePaiement.carte => 'Carte bancaire',
  };

  String get nomCourt => this == MethodePaiement.mtnMomo ? 'MTN MoMo' : nom;

  String get description => switch (this) {
    MethodePaiement.wave => "Confirmez dans l'application Wave",
    MethodePaiement.carte => 'Visa, Mastercard',
    _ => 'Validation par code sur votre téléphone',
  };

  /// Couleur de la marque (bordure de sélection, minuteur).
  Color get couleur => switch (this) {
    MethodePaiement.orangeMoney => const Color(0xFFFF7900),
    MethodePaiement.wave => const Color(0xFF1DC8F2),
    MethodePaiement.mtnMomo => const Color(0xFFE5B800),
    MethodePaiement.moovMoney => const Color(0xFF0066B3),
    MethodePaiement.carte => const Color(0xFF475569),
  };

  /// Logo officiel ; null pour la carte bancaire.
  String? get logo => this == MethodePaiement.carte ? null : 'assets/images/paiements/$code.png';

  String get exempleNumero => switch (this) {
    MethodePaiement.orangeMoney => '07 00 00 00 00',
    MethodePaiement.mtnMomo => '05 00 00 00 00',
    _ => '01 00 00 00 00',
  };
}
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
