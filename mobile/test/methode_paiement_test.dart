import 'package:flutter_test/flutter_test.dart';
import 'package:tambour/models/paiement.dart';

void main() {
  test("codes alignés sur l'API et logos présents pour le Mobile Money", () {
    expect(MethodePaiement.values.map((m) => m.code),
      ['orange_money', 'wave', 'mtn_momo', 'moov_money', 'carte']);
    for (final m in MethodePaiement.values.where((m) => m != MethodePaiement.carte)) {
      expect(m.logo, 'assets/images/paiements/${m.code}.png');
    }
    expect(MethodePaiement.carte.logo, isNull);
    expect(MethodePaiement.moovMoney.nom, 'Moov Money');
  });
}
