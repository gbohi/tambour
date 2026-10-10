enum StatutSiege { libre, occupe, selectionne, rezerveHandicap }

class Siege {
  final String id;
  final int rangee;
  final String colonne;
  final StatutSiege statut;

  const Siege({required this.id, required this.rangee, required this.colonne, required this.statut});

  String get label => '$rangee$colonne';
  bool get estSelectionnable => statut == StatutSiege.libre;

  Siege copyWith({StatutSiege? statut}) =>
    Siege(id: id, rangee: rangee, colonne: colonne, statut: statut ?? this.statut);

  factory Siege.fromJson(Map<String, dynamic> json) {
    final statutStr = json['statut'] as String? ?? 'libre';
    final statut = switch (statutStr) {
      'reserve' => StatutSiege.occupe, // réservé = affiché occupé côté client
      'occupe' => StatutSiege.occupe,
      'bloque' => StatutSiege.occupe,
      _ => StatutSiege.libre,
    };
    return Siege(
      id: json['numero'] as String,
      rangee: json['rangee'] as int,
      colonne: json['colonne'] as String,
      statut: statut,
    );
  }

  static List<Siege> genererBus54Places({List<String> siegesOccupes = const []}) {
    final sieges = <Siege>[];
    const colonnes = ['A', 'B', 'C', 'D'];
    for (int r = 1; r <= 13; r++) {
      for (final col in colonnes) {
        final id = '$r$col';
        sieges.add(Siege(id: id, rangee: r, colonne: col,
          statut: siegesOccupes.contains(id) ? StatutSiege.occupe : StatutSiege.libre));
      }
    }
    for (final col in ['A', 'B']) {
      final id = '14$col';
      sieges.add(Siege(id: id, rangee: 14, colonne: col,
        statut: siegesOccupes.contains(id) ? StatutSiege.occupe : StatutSiege.libre));
    }
    return sieges;
  }

  /// Attribution automatique : les `nombre` premiers sièges libres dans l'ordre du car
  /// (les passagers d'une même réservation sont ainsi placés côte à côte).
  static List<String> attribuerAuto(int nombre, {List<String> siegesOccupes = const []}) =>
    genererBus54Places(siegesOccupes: siegesOccupes)
      .where((s) => s.estSelectionnable)
      .take(nombre)
      .map((s) => s.id)
      .toList();

  static List<String> mockOccupes() => [
    '1A','1B','1C','2A','2D','3B','3C','4A','4B',
    '5C','5D','6A','6B','7D','8A','8C','9B','9D',
    '10A','10B','11C','12A','12D','13B',
  ];
}
