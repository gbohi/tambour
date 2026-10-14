import 'package:tambour_passager/models/trajet.dart';
import 'package:tambour_passager/models/passager.dart';
import 'package:tambour_passager/models/paiement.dart';

/// UN billet par passager — QR unique
class Billet {
  final String id;
  final String referenceReservation;
  final String referenceBillet;    // ex: TB20260608001-P1
  final Trajet trajet;
  final Passager passager;
  final PaiementResult paiement;
  final DateTime dateReservation;
  final String codeQr;
  final int numeroBillet;
  final int totalBillets;

  const Billet({
    required this.id,
    required this.referenceReservation,
    required this.referenceBillet,
    required this.trajet,
    required this.passager,
    required this.paiement,
    required this.dateReservation,
    required this.codeQr,
    required this.numeroBillet,
    required this.totalBillets,
  });

  /// Génère la liste des billets (1 par passager) depuis une réservation
  static List<Billet> creerDepuisReservation({
    required String referenceReservation,
    required Trajet trajet,
    required List<Passager> passagers,
    required PaiementResult paiement,
  }) {
    return passagers.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      final id  = '$referenceReservation-P${i + 1}';
      final ref = '$referenceReservation-P${i + 1}';
      final qr  = 'TAMBOUR|$referenceReservation|${i + 1}'
          '|${trajet.id}|${trajet.depart.id}|${trajet.arrivee.id}'
          '|${trajet.heureDepart.toIso8601String()}'
          '|${p.siegeId}|${p.nomComplet}';
      return Billet(
        id: id, referenceReservation: referenceReservation,
        referenceBillet: ref, trajet: trajet, passager: p, paiement: paiement,
        dateReservation: DateTime.now(), codeQr: qr,
        numeroBillet: i + 1, totalBillets: passagers.length,
      );
    }).toList();
  }

  bool get estValide => trajet.heureDepart.isAfter(DateTime.now());
}
