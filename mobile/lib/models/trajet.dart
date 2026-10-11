import 'ville.dart';

enum ClasseBus { standard, confort, vip }

class Trajet {
  final String id;
  final Ville depart;
  final Ville arrivee;
  final DateTime heureDepart;
  final DateTime heureArrivee;
  final int prixFcfa;
  final int placesDisponibles;
  final int placesTotal;
  final String compagnie;
  final String busImmatriculation;
  final ClasseBus classe;
  final List<String> amenities;
  final double note;
  final int nombreAvis;

  const Trajet({
    required this.id, required this.depart, required this.arrivee,
    required this.heureDepart, required this.heureArrivee,
    required this.prixFcfa, required this.placesDisponibles,
    required this.placesTotal, required this.compagnie,
    required this.busImmatriculation, required this.classe,
    required this.amenities, required this.note, required this.nombreAvis,
  });

  Duration get duree => heureArrivee.difference(heureDepart);

  String get dureeLabel {
    final h = duree.inHours;
    final m = duree.inMinutes.remainder(60);
    final mStr = m.toString().padLeft(2, '0');
    return m == 0 ? '${h}h' : '${h}h$mStr';
  }

  bool get presqueComplet => placesDisponibles <= 5;

  factory Trajet.fromJson(Map<String, dynamic> json) => Trajet(
    id: json['id'] as String,
    depart: Ville.fromJson(json['depart'] as Map<String, dynamic>),
    arrivee: Ville.fromJson(json['arrivee'] as Map<String, dynamic>),
    heureDepart: DateTime.parse(json['heure_depart'] as String),
    heureArrivee: DateTime.parse(json['heure_arrivee_estimee'] as String),
    prixFcfa: (json['prix_actuel'] ?? json['prix_fcfa']) as int,
    placesDisponibles: json['places_disponibles'] as int,
    placesTotal: json['places_total'] as int,
    compagnie: json['compagnie'] as String,
    busImmatriculation: json['bus_immatriculation'] as String? ?? '',
    classe: ClasseBus.values.firstWhere((c) => c.name == json['bus_classe'], orElse: () => ClasseBus.standard),
    amenities: List<String>.from(json['amenities'] as List? ?? const []),
    // DRF renvoie les décimaux sous forme de texte
    note: double.tryParse('${json['note_moyenne']}') ?? 0,
    nombreAvis: json['nombre_avis'] as int,
  );

  static List<Trajet> mockTrajets(String departId, String arriveeId) {
    final depart = Ville.mockVilles.firstWhere((v) => v.id == departId, orElse: () => Ville.mockVilles.first);
    final arrivee = Ville.mockVilles.firstWhere((v) => v.id == arriveeId, orElse: () => Ville.mockVilles[1]);
    final base = DateTime.now().add(const Duration(days: 1));
    return [
      Trajet(id: 't1', depart: depart, arrivee: arrivee,
        heureDepart: DateTime(base.year, base.month, base.day, 6, 0),
        heureArrivee: DateTime(base.year, base.month, base.day, 9, 30),
        prixFcfa: 3500, placesDisponibles: 32, placesTotal: 54,
        compagnie: 'Trans Ivoire', busImmatriculation: 'AB-2341-CI',
        classe: ClasseBus.standard, amenities: ['wifi', 'clim'], note: 4.2, nombreAvis: 128),
      Trajet(id: 't2', depart: depart, arrivee: arrivee,
        heureDepart: DateTime(base.year, base.month, base.day, 8, 30),
        heureArrivee: DateTime(base.year, base.month, base.day, 12, 0),
        prixFcfa: 4500, placesDisponibles: 4, placesTotal: 36,
        compagnie: 'Confort Express', busImmatriculation: 'AB-5892-CI',
        classe: ClasseBus.confort, amenities: ['wifi', 'clim', 'usb', 'eau'], note: 4.7, nombreAvis: 214),
      Trajet(id: 't3', depart: depart, arrivee: arrivee,
        heureDepart: DateTime(base.year, base.month, base.day, 10, 0),
        heureArrivee: DateTime(base.year, base.month, base.day, 13, 30),
        prixFcfa: 3500, placesDisponibles: 18, placesTotal: 54,
        compagnie: 'Trans Ivoire', busImmatriculation: 'AB-0021-CI',
        classe: ClasseBus.standard, amenities: ['clim'], note: 4.0, nombreAvis: 87),
      Trajet(id: 't4', depart: depart, arrivee: arrivee,
        heureDepart: DateTime(base.year, base.month, base.day, 14, 0),
        heureArrivee: DateTime(base.year, base.month, base.day, 22, 0),
        prixFcfa: 7500, placesDisponibles: 12, placesTotal: 28,
        compagnie: 'VIP Voyages', busImmatriculation: 'AB-7743-CI',
        classe: ClasseBus.vip, amenities: ['wifi', 'clim', 'usb', 'eau', 'snack'], note: 4.9, nombreAvis: 63),
      Trajet(id: 't5', depart: depart, arrivee: arrivee,
        heureDepart: DateTime(base.year, base.month, base.day, 16, 0),
        heureArrivee: DateTime(base.year, base.month, base.day, 19, 30),
        prixFcfa: 3500, placesDisponibles: 41, placesTotal: 54,
        compagnie: 'Trans Ivoire', busImmatriculation: 'AB-3398-CI',
        classe: ClasseBus.standard, amenities: ['clim'], note: 3.8, nombreAvis: 55),
    ];
  }
}
