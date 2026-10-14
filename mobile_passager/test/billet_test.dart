import 'package:flutter_test/flutter_test.dart';
import 'package:tambour_passager/models/billet.dart';
import 'package:tambour_passager/models/paiement.dart';
import 'package:tambour_passager/models/passager.dart';
import 'package:tambour_passager/models/trajet.dart';

void main() {
  test('les billets portent la vraie référence, le nom et un QR complet', () {
    final billets = Billet.creerDepuisReservation(
      referenceReservation: 'TB202610141234',
      trajet: Trajet.mockTrajets('abj', 'yam').first,
      passagers: const [
        Passager(prenom: 'Aya', nom: 'Koné', telephone: '0707123456', siegeId: '1C'),
        Passager(prenom: 'Ibrahim', nom: 'Koné', telephone: '0505987654', siegeId: '1D'),
      ],
      paiement: PaiementResult(referenceTransaction: 'TB202610141234', statut: StatutPaiement.succes,
        timestamp: DateTime(2026, 10, 14), montantFcfa: 7500, methode: MethodePaiement.orangeMoney),
    );
    expect(billets.map((b) => b.referenceBillet), ['TB202610141234-P1', 'TB202610141234-P2']);
    expect(billets.first.passager.nomComplet, 'Aya Koné');
    expect(billets.first.codeQr, startsWith('TAMBOUR|TB202610141234|1|'));
    expect(billets.first.codeQr, endsWith('|1C|Aya Koné'));
    expect(billets.every((b) => !b.codeQr.contains(r'$')), isTrue);
  });
}
