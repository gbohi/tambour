import '../models/user_model.dart';

/// Les deux applications construites à partir de ce projet.
/// - passager : « TamBour », réservation et billets (lib/main.dart)
/// - chauffeur : « TamBour Pro », contrôle des billets et trajets (lib/main_chauffeur.dart)
enum Variante { passager, chauffeur }

class AppVariante {
  AppVariante._();

  static Variante courante = Variante.passager;

  static bool get estChauffeur => courante == Variante.chauffeur;
  static String get nom => estChauffeur ? 'TamBour Pro' : 'TamBour';

  /// Chaque application n'accepte que les comptes qui la concernent.
  static bool accepte(UserModel u) => estChauffeur ? u.estChauffeur : !u.estChauffeur;

  static String get messageRefus => estChauffeur
    ? "Ce compte n'est pas un compte chauffeur. Les voyageurs utilisent l'application TamBour."
    : "Ce compte est un compte chauffeur : connectez-vous avec l'application TamBour Pro.";
}
