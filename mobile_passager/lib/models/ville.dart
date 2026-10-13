class Ville {
  final String id;
  final String nom;
  final String region;
  final String? codeIata;

  const Ville({required this.id, required this.nom, required this.region, this.codeIata});

  factory Ville.fromJson(Map<String, dynamic> json) => Ville(
    id: json['id'] as String,
    nom: json['nom'] as String,
    region: json['region'] as String,
    codeIata: json['code_iata'] as String?,
  );

  static List<Ville> get mockVilles => [
    const Ville(id: 'abj', nom: 'Abidjan', region: 'Lagunes'),
    const Ville(id: 'bke', nom: 'Bouaké', region: 'Vallée du Bandama'),
    const Ville(id: 'yam', nom: 'Yamoussoukro', region: 'Lacs'),
    const Ville(id: 'dal', nom: 'Daloa', region: 'Haut-Sassandra'),
    const Ville(id: 'san', nom: 'San-Pédro', region: 'Bas-Sassandra'),
    const Ville(id: 'man', nom: 'Man', region: 'Tonkpi'),
    const Ville(id: 'kor', nom: 'Korhogo', region: 'Poro'),
    const Ville(id: 'odi', nom: 'Odienné', region: 'Kabadougou'),
    const Ville(id: 'abi', nom: 'Aboisso', region: 'Sud-Comoé'),
    const Ville(id: 'dim', nom: 'Dimbokro', region: "N'Zi"),
  ];
}
