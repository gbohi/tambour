class UserModel {
  final String id;
  final String prenom;
  final String nom;
  final String email;
  final String telephone;
  final String? avatarUrl;
  final DateTime dateInscription;
  final int pointsFidelite;
  final int nbVoyages;
  final String codeParrainage;

  const UserModel({
    required this.id, required this.prenom, required this.nom,
    required this.email, required this.telephone, this.avatarUrl,
    required this.dateInscription, this.pointsFidelite = 0, this.nbVoyages = 0,
    this.codeParrainage = '',
  });

  String get nomComplet => '$prenom $nom';
  String get initiales =>
    '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  UserModel copyWith({String? prenom, String? nom, String? email, String? telephone}) =>
    UserModel(id: id, prenom: prenom ?? this.prenom, nom: nom ?? this.nom,
      email: email ?? this.email, telephone: telephone ?? this.telephone,
      avatarUrl: avatarUrl, dateInscription: dateInscription,
      pointsFidelite: pointsFidelite, nbVoyages: nbVoyages, codeParrainage: codeParrainage);

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String, prenom: json['prenom'] as String,
    nom: json['nom'] as String, email: json['email'] as String,
    telephone: json['telephone'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    dateInscription: DateTime.parse(json['date_inscription'] as String),
    pointsFidelite: json['points_fidelite'] as int? ?? 0,
    nbVoyages: json['nb_voyages'] as int? ?? 0,
    codeParrainage: json['code_parrainage'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'prenom': prenom, 'nom': nom, 'email': email,
    'telephone': telephone, 'avatar_url': avatarUrl,
    'date_inscription': dateInscription.toIso8601String(),
    'points_fidelite': pointsFidelite, 'nb_voyages': nbVoyages,
    'code_parrainage': codeParrainage,
  };
}
