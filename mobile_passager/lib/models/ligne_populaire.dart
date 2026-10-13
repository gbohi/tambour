import 'package:tambour_passager/models/ville.dart';

class LignePopulaire {
  final String depart;
  final String arrivee;
  final String departRegion;
  final String arriveeRegion;
  final String? dureeLabel;
  final int? prixMin;
  final int trajetsParJour;
  final bool estPopulaire;

  const LignePopulaire({
    required this.depart, required this.arrivee,
    this.departRegion = '', this.arriveeRegion = '',
    this.dureeLabel, this.prixMin, this.trajetsParJour = 0, this.estPopulaire = false,
  });

  factory LignePopulaire.fromJson(Map<String, dynamic> json) => LignePopulaire(
    depart: json['depart'] as String,
    arrivee: json['arrivee'] as String,
    departRegion: json['depart_region'] as String? ?? '',
    arriveeRegion: json['arrivee_region'] as String? ?? '',
    dureeLabel: json['duree_label'] as String?,
    prixMin: json['prix_min'] as int?,
    trajetsParJour: json['trajets_par_jour'] as int? ?? 0,
    estPopulaire: json['est_populaire'] as bool? ?? false,
  );

  Ville get villeDepart => _ville(depart, departRegion);
  Ville get villeArrivee => _ville(arrivee, arriveeRegion);

  /// Retrouve la ville connue de l'application (les noms peuvent différer par les accents).
  static Ville _ville(String nom, String region) {
    final cle = _normaliser(nom);
    for (final v in Ville.mockVilles) {
      if (_normaliser(v.nom) == cle) return v;
    }
    return Ville(id: cle, nom: nom, region: region);
  }

  static String _normaliser(String s) {
    const accents = {'à': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c'};
    return s.toLowerCase().split('').map((c) => accents[c] ?? c).join();
  }

  /// Utilisées si l'API n'est pas joignable.
  static const List<LignePopulaire> parDefaut = [
    LignePopulaire(depart: 'Abidjan', arrivee: 'Bouaké', dureeLabel: '3h30', prixMin: 3500, trajetsParJour: 8, estPopulaire: true),
    LignePopulaire(depart: 'Abidjan', arrivee: 'Yamoussoukro', dureeLabel: '2h45', prixMin: 2800, trajetsParJour: 6, estPopulaire: true),
    LignePopulaire(depart: 'Abidjan', arrivee: 'San-Pédro', dureeLabel: '4h15', prixMin: 4200, trajetsParJour: 4, estPopulaire: true),
    LignePopulaire(depart: 'Abidjan', arrivee: 'Daloa', dureeLabel: '4h00', prixMin: 4000, trajetsParJour: 5),
    LignePopulaire(depart: 'Bouaké', arrivee: 'Korhogo', dureeLabel: '3h00', prixMin: 2500, trajetsParJour: 3),
    LignePopulaire(depart: 'Abidjan', arrivee: 'Man', dureeLabel: '7h00', prixMin: 6000, trajetsParJour: 3),
    LignePopulaire(depart: 'Bouaké', arrivee: 'Yamoussoukro', dureeLabel: '1h30', prixMin: 2000, trajetsParJour: 5),
    LignePopulaire(depart: 'Abidjan', arrivee: 'Korhogo', dureeLabel: '8h30', prixMin: 7000, trajetsParJour: 2),
    LignePopulaire(depart: 'Abidjan', arrivee: 'Aboisso', dureeLabel: '1h45', prixMin: 2000, trajetsParJour: 6),
    LignePopulaire(depart: 'Yamoussoukro', arrivee: 'Daloa', dureeLabel: '2h30', prixMin: 2500, trajetsParJour: 3),
  ];
}
