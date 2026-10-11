import 'package:flutter_test/flutter_test.dart';
import 'package:tambour/core/variante.dart';
import 'package:tambour/models/user_model.dart';

UserModel compte(String role) => UserModel.fromJson({
  'id': '1', 'prenom': 'A', 'nom': 'B', 'email': 'a@b.ci', 'telephone': '0700000000', 'role': role, 'date_inscription': '2026-01-01T00:00:00Z',
});

void main() {
  tearDown(() => AppVariante.courante = Variante.passager);

  test("TamBour n'accepte que les voyageurs", () {
    AppVariante.courante = Variante.passager;
    expect(AppVariante.nom, 'TamBour');
    expect(AppVariante.accepte(compte('voyageur')), isTrue);
    expect(AppVariante.accepte(compte('chauffeur')), isFalse);
    expect(AppVariante.messageRefus, contains('TamBour Pro'));
  });

  test("TamBour Pro n'accepte que les chauffeurs", () {
    AppVariante.courante = Variante.chauffeur;
    expect(AppVariante.nom, 'TamBour Pro');
    expect(AppVariante.accepte(compte('chauffeur')), isTrue);
    expect(AppVariante.accepte(compte('voyageur')), isFalse);
  });
}
