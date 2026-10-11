class Gare {
  final String id;
  final String nom;
  final String ville;
  final String adresse;
  final double latitude;
  final double longitude;
  final String telephone;
  final String heuresOuverture;
  final List<String> compagnies;
  final List<String> lignes;
  final bool estPrincipale;

  const Gare({
    required this.id, required this.nom, required this.ville,
    required this.adresse, required this.latitude, required this.longitude,
    required this.telephone, required this.heuresOuverture,
    required this.compagnies, required this.lignes, this.estPrincipale = false,
  });

  factory Gare.fromJson(Map<String, dynamic> json) => Gare(
    id: json['id'] as String, nom: json['nom'] as String,
    ville: json['ville_nom'] as String, adresse: json['adresse'] as String,
    // DRF renvoie les décimaux sous forme de texte
    latitude: double.parse('${json['latitude']}'),
    longitude: double.parse('${json['longitude']}'),
    telephone: json['telephone'] as String? ?? '',
    heuresOuverture: json['heures_ouverture'] as String? ?? '05h00 – 22h00',
    compagnies: List<String>.from(json['compagnies'] as List? ?? []),
    lignes: List<String>.from(json['lignes'] as List? ?? []),
    estPrincipale: json['est_principale'] as bool? ?? false,
  );

  static List<Gare> mockGares() => const [
    Gare(id: 'g1', nom: "Gare d'Adjamé Sud", ville: 'Abidjan',
      adresse: 'Boulevard de la République, Adjamé, Abidjan',
      latitude: 5.3600, longitude: -4.0167, telephone: '27 20 37 25 00',
      heuresOuverture: '05h00 – 22h00',
      compagnies: ['Trans Ivoire', 'Confort Express', 'VIP Voyages'],
      lignes: ['Abidjan → Bouaké', 'Abidjan → Yamoussoukro', 'Abidjan → Daloa'],
      estPrincipale: true),
    Gare(id: 'g2', nom: 'Gare de Yopougon', ville: 'Abidjan',
      adresse: 'Rue des Transporteurs, Yopougon',
      latitude: 5.3453, longitude: -4.0714, telephone: '27 20 45 12 33',
      heuresOuverture: '05h30 – 21h00',
      compagnies: ['Trans Ivoire', 'Gbaka Plus'],
      lignes: ['Abidjan → San-Pédro', 'Abidjan → Man']),
    Gare(id: 'g3', nom: 'Gare Routière de Bouaké', ville: 'Bouaké',
      adresse: 'Avenue Houphouët-Boigny, Bouaké',
      latitude: 7.6899, longitude: -5.0317, telephone: '27 31 63 14 00',
      heuresOuverture: '05h00 – 21h30',
      compagnies: ['Trans Ivoire', 'Confort Express'],
      lignes: ['Bouaké → Abidjan', 'Bouaké → Korhogo'], estPrincipale: true),
    Gare(id: 'g4', nom: 'Gare de Yamoussoukro', ville: 'Yamoussoukro',
      adresse: 'Route de Toumodi, Yamoussoukro',
      latitude: 6.8276, longitude: -5.2893, telephone: '27 30 64 00 12',
      heuresOuverture: '05h30 – 20h30',
      compagnies: ['Trans Ivoire', 'VIP Voyages'],
      lignes: ['Yamoussoukro → Abidjan']),
    Gare(id: 'g5', nom: 'Gare de San-Pédro', ville: 'San-Pédro',
      adresse: 'Quartier Balmer, San-Pédro',
      latitude: 4.7485, longitude: -6.6363, telephone: '27 34 71 20 45',
      heuresOuverture: '05h00 – 20h00',
      compagnies: ['Trans Ivoire'], lignes: ['San-Pédro → Abidjan']),
    Gare(id: 'g6', nom: 'Gare Routière de Korhogo', ville: 'Korhogo',
      adresse: 'Avenue de la Gare, Korhogo',
      latitude: 9.4580, longitude: -5.6296, telephone: '27 36 86 10 22',
      heuresOuverture: '05h00 – 20h00',
      compagnies: ['Trans Ivoire'], lignes: ['Korhogo → Bouaké']),
    Gare(id: 'g7', nom: 'Gare de Daloa', ville: 'Daloa',
      adresse: 'Boulevard du Commerce, Daloa',
      latitude: 6.8774, longitude: -6.4502, telephone: '27 32 78 15 09',
      heuresOuverture: '05h00 – 21h00',
      compagnies: ['Trans Ivoire', 'Confort Express'],
      lignes: ['Daloa → Abidjan', 'Daloa → Man']),
    Gare(id: 'g8', nom: 'Gare de Man', ville: 'Man',
      adresse: 'Quartier Domoraud, Man',
      latitude: 7.4126, longitude: -7.5535, telephone: '27 33 79 08 11',
      heuresOuverture: '05h30 – 19h30',
      compagnies: ['Gbaka Plus'], lignes: ['Man → Abidjan']),
  ];
}
