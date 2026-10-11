class TrajetChauffeur {
  final String id;
  final String depart, arrivee;
  final String? gareDepart;
  final DateTime heureDepart, heureArriveeEstimee;
  final DateTime? heureArriveeReelle;
  final String statut, statutLabel;
  final int retardMinutes;
  final String compagnie, busImmatriculation, busModele;
  final int placesTotal, nbPassagers, nbEmbarques;
  final List<PassagerChauffeur> passagers;

  const TrajetChauffeur({required this.id, required this.depart, required this.arrivee, this.gareDepart,
    required this.heureDepart, required this.heureArriveeEstimee, this.heureArriveeReelle,
    required this.statut, required this.statutLabel, this.retardMinutes = 0,
    required this.compagnie, required this.busImmatriculation, this.busModele = '',
    required this.placesTotal, required this.nbPassagers, required this.nbEmbarques,
    this.passagers = const []});

  bool get estEnCours => statut == 'en_cours';
  bool get estTermine => statut == 'termine' || statut == 'annule';
  bool get peutDemarrer => statut == 'planifie' || statut == 'retarde';

  factory TrajetChauffeur.fromJson(Map<String, dynamic> j) => TrajetChauffeur(
    id: j['id'] as String,
    depart: j['depart'] as String, arrivee: j['arrivee'] as String,
    gareDepart: j['gare_depart'] as String?,
    heureDepart: DateTime.parse(j['heure_depart'] as String).toLocal(),
    heureArriveeEstimee: DateTime.parse(j['heure_arrivee_estimee'] as String).toLocal(),
    heureArriveeReelle: j['heure_arrivee_reelle'] == null ? null
      : DateTime.parse(j['heure_arrivee_reelle'] as String).toLocal(),
    statut: j['statut'] as String, statutLabel: j['statut_label'] as String? ?? '',
    retardMinutes: j['retard_minutes'] as int? ?? 0,
    compagnie: j['compagnie'] as String? ?? '',
    busImmatriculation: j['bus_immatriculation'] as String? ?? '',
    busModele: j['bus_modele'] as String? ?? '',
    placesTotal: j['places_total'] as int? ?? 0,
    nbPassagers: j['nb_passagers'] as int? ?? 0,
    nbEmbarques: j['nb_embarques'] as int? ?? 0,
    passagers: (j['passagers'] as List? ?? [])
      .map((p) => PassagerChauffeur.fromJson(p as Map<String, dynamic>)).toList());
}

class PassagerChauffeur {
  final String id, nomComplet, telephone, siege, reservation, referenceBillet;
  final bool embarque;
  final DateTime? embarqueLe;

  const PassagerChauffeur({required this.id, required this.nomComplet, required this.telephone,
    required this.siege, required this.reservation, required this.referenceBillet,
    required this.embarque, this.embarqueLe});

  factory PassagerChauffeur.fromJson(Map<String, dynamic> j) => PassagerChauffeur(
    id: j['id'] as String, nomComplet: j['nom_complet'] as String,
    telephone: j['telephone'] as String? ?? '', siege: j['siege'] as String? ?? '',
    reservation: j['reservation'] as String? ?? '',
    referenceBillet: j['reference_billet'] as String? ?? '',
    embarque: j['embarque'] as bool? ?? false,
    embarqueLe: j['embarque_le'] == null ? null : DateTime.parse(j['embarque_le'] as String).toLocal());
}

/// Résultat d'un scan : succès (passager embarqué) ou refus avec la raison.
class ResultatScan {
  final bool ok;
  final String message;
  final PassagerChauffeur? passager;
  final String? code;  // deja_utilise, autre_trajet, non_paye, introuvable…
  const ResultatScan({required this.ok, required this.message, this.passager, this.code});
}
