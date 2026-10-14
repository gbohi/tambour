/// Bannière de l'écran d'accueil, gérée depuis l'administration (Plateforme › Bannières).
class Banniere {
  final int id;
  final String titre;
  final String sousTitre;
  final String? imageUrl;
  final String couleurFond;
  final String texteBouton;
  /// aucune | recherche | page | lien
  final String action;
  final String? departId;
  final String? departNom;
  final String? arriveeId;
  final String? arriveeNom;
  /// fidelite | gares | lignes | aide
  final String page;
  final String lien;

  const Banniere({
    required this.id, required this.titre, this.sousTitre = '', this.imageUrl,
    this.couleurFond = '#0F4A3B', this.texteBouton = '', this.action = 'aucune',
    this.departId, this.departNom, this.arriveeId, this.arriveeNom, this.page = '', this.lien = '',
  });

  factory Banniere.fromJson(Map<String, dynamic> json) => Banniere(
    id: json['id'] as int,
    titre: json['titre'] as String? ?? '',
    sousTitre: json['sous_titre'] as String? ?? '',
    imageUrl: json['image_url'] as String?,
    couleurFond: json['couleur_fond'] as String? ?? '#0F4A3B',
    texteBouton: json['texte_bouton'] as String? ?? '',
    action: json['action'] as String? ?? 'aucune',
    departId: json['depart'] as String?,
    departNom: json['depart_nom'] as String?,
    arriveeId: json['arrivee'] as String?,
    arriveeNom: json['arrivee_nom'] as String?,
    page: json['page'] as String? ?? '',
    lien: json['lien'] as String? ?? '',
  );

  /// Route de l'application ouverte par l'action « page ».
  String? get routePage => const {
    'fidelite': '/fidelite', 'gares': '/gares', 'lignes': '/lignes-populaires', 'aide': '/aide',
  }[page];
}
