import 'package:flutter/material.dart';

/// Passager sans pièce d'identité — email facultatif
class Passager {
  final String prenom;
  final String nom;
  final String telephone;
  final String email;     // facultatif — envoi billet par email
  final String siegeId;

  const Passager({
    required this.prenom,
    required this.nom,
    required this.telephone,
    this.email = '',
    required this.siegeId,
  });

  String get nomComplet => '\$prenom \$nom';
  bool get aEmail => email.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'prenom': prenom, 'nom': nom,
    'telephone': telephone, 'email': email, 'siege_id': siegeId,
  };

  Passager copyWith({String? prenom, String? nom,
    String? telephone, String? email, String? siegeId}) => Passager(
    prenom: prenom ?? this.prenom, nom: nom ?? this.nom,
    telephone: telephone ?? this.telephone,
    email: email ?? this.email, siegeId: siegeId ?? this.siegeId,
  );
}

/// Formulaire passager — un contrôleur par champ
class PassagerForm {
  final TextEditingController prenomCtrl;
  final TextEditingController nomCtrl;
  final TextEditingController telephoneCtrl;
  final TextEditingController emailCtrl;
  final GlobalKey<FormState> formKey;

  PassagerForm()
    : prenomCtrl    = TextEditingController(),
      nomCtrl       = TextEditingController(),
      telephoneCtrl = TextEditingController(),
      emailCtrl     = TextEditingController(),
      formKey       = GlobalKey<FormState>();

  void dispose() {
    prenomCtrl.dispose(); nomCtrl.dispose();
    telephoneCtrl.dispose(); emailCtrl.dispose();
  }

  bool get estRempli =>
    prenomCtrl.text.trim().isNotEmpty &&
    nomCtrl.text.trim().isNotEmpty &&
    telephoneCtrl.text.trim().length >= 10;
}
