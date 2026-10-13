class MouvementPoints {
  final int points;
  final String motif;
  final String motifLabel;
  final String description;
  final DateTime date;

  const MouvementPoints({required this.points, required this.motif, required this.motifLabel,
    required this.description, required this.date});

  factory MouvementPoints.fromJson(Map<String, dynamic> json) => MouvementPoints(
    points: json['points'] as int,
    motif: json['motif'] as String,
    motifLabel: json['motif_label'] as String? ?? '',
    description: json['description'] as String? ?? '',
    date: DateTime.parse(json['created_at'] as String),
  );
}

class FideliteInfo {
  final int points;
  final int nbVoyages;
  final String codeParrainage;
  final int nbFilleuls;
  final int pointsParrainage;
  final int pointsParrain;   // gagnés par le parrain à chaque ami inscrit
  final int pointsFilleul;   // offerts à l'ami qui s'inscrit avec le code
  final String messagePartage;
  final List<MouvementPoints> historique;

  const FideliteInfo({required this.points, required this.nbVoyages, required this.codeParrainage,
    required this.nbFilleuls, required this.pointsParrainage, required this.pointsParrain,
    required this.pointsFilleul, required this.messagePartage, required this.historique});

  factory FideliteInfo.fromJson(Map<String, dynamic> json) => FideliteInfo(
    points: json['points'] as int? ?? 0,
    nbVoyages: json['nb_voyages'] as int? ?? 0,
    codeParrainage: json['code_parrainage'] as String? ?? '',
    nbFilleuls: json['nb_filleuls'] as int? ?? 0,
    pointsParrainage: json['points_parrainage'] as int? ?? 0,
    pointsParrain: json['points_parrain'] as int? ?? 0,
    pointsFilleul: json['points_filleul'] as int? ?? 0,
    messagePartage: json['message_partage'] as String? ?? '',
    historique: (json['historique'] as List? ?? [])
      .map((m) => MouvementPoints.fromJson(m as Map<String, dynamic>)).toList(),
  );
}
