class QuestionFAQ {
  final String question;
  final String reponse;
  const QuestionFAQ(this.question, this.reponse);

  factory QuestionFAQ.fromJson(Map<String, dynamic> json) =>
    QuestionFAQ(json['question'] as String, json['reponse'] as String);
}

class CategorieFAQ {
  final String code;
  final String label;
  final List<QuestionFAQ> questions;
  const CategorieFAQ(this.code, this.label, this.questions);

  factory CategorieFAQ.fromJson(Map<String, dynamic> json) => CategorieFAQ(
    json['code'] as String, json['label'] as String,
    (json['questions'] as List).map((q) => QuestionFAQ.fromJson(q as Map<String, dynamic>)).toList());

  /// Affichée si l'API n'est pas joignable.
  static const List<CategorieFAQ> parDefaut = [
    CategorieFAQ('reservation', 'Réservation', [
      QuestionFAQ('Comment réserver un billet ?',
        "Sur l'accueil, choisissez départ, arrivée, date et nombre de passagers, puis « Rechercher un trajet ». "
        'Choisissez un départ, renseignez les passagers et payez. Vos billets arrivent dans « Mes billets ».'),
      QuestionFAQ('Puis-je choisir mon siège ?',
        "Les sièges sont attribués automatiquement parmi les places disponibles. Les passagers d'une même "
        'réservation sont placés le plus près possible les uns des autres.'),
    ]),
    CategorieFAQ('paiement', 'Paiement', [
      QuestionFAQ('Quels moyens de paiement sont acceptés ?', 'MTN Mobile Money, Orange Money, Wave et carte bancaire.'),
      QuestionFAQ("J'ai été débité mais je n'ai pas reçu mon billet",
        "Patientez quelques minutes puis ouvrez « Mes billets ». Sinon, faites une réclamation depuis « Mon compte »."),
    ]),
    CategorieFAQ('fidelite', 'Fidélité & parrainage', [
      QuestionFAQ('Comment gagner des points ?',
        'À chaque voyage payé, et en parrainant vos amis : vous et votre ami recevez des points à son inscription.'),
    ]),
  ];
}

class InfosContact {
  final String telephone, whatsapp, email, horaires;
  const InfosContact({required this.telephone, required this.whatsapp, required this.email, required this.horaires});

  factory InfosContact.fromJson(Map<String, dynamic> json) => InfosContact(
    telephone: json['telephone'] as String, whatsapp: json['whatsapp'] as String,
    email: json['email'] as String, horaires: json['horaires'] as String);

  static const parDefaut = InfosContact(telephone: '+225 07 00 00 00 00', whatsapp: '+2250700000000',
    email: 'support@tambour.ci', horaires: 'Tous les jours, 6h – 22h');
}

enum StatutReclamation { ouverte, enCours, resolue, rejetee }

class Reclamation {
  final String id, reference, categorie, categorieLabel, sujet, description, referenceReservation, reponse;
  final StatutReclamation statut;
  final String statutLabel;
  final DateTime date;

  const Reclamation({required this.id, required this.reference, required this.categorie,
    required this.categorieLabel, required this.sujet, required this.description,
    required this.referenceReservation, required this.reponse, required this.statut,
    required this.statutLabel, required this.date});

  factory Reclamation.fromJson(Map<String, dynamic> json) => Reclamation(
    id: json['id'] as String,
    reference: json['reference'] as String,
    categorie: json['categorie'] as String,
    categorieLabel: json['categorie_label'] as String? ?? '',
    sujet: json['sujet'] as String,
    description: json['description'] as String,
    referenceReservation: json['reference_reservation'] as String? ?? '',
    reponse: json['reponse'] as String? ?? '',
    statut: switch (json['statut']) {
      'en_cours' => StatutReclamation.enCours,
      'resolue' => StatutReclamation.resolue,
      'rejetee' => StatutReclamation.rejetee,
      _ => StatutReclamation.ouverte,
    },
    statutLabel: json['statut_label'] as String? ?? '',
    date: DateTime.parse(json['created_at'] as String),
  );

  /// Catégories proposées dans le formulaire (codes identiques au backend).
  static const categories = {
    'paiement': 'Problème de paiement',
    'billet': 'Billet non reçu ou invalide',
    'remboursement': 'Annulation / remboursement',
    'retard': 'Retard ou annulation du car',
    'bagage': 'Bagage perdu ou endommagé',
    'service': 'Accueil ou comportement du personnel',
    'autre': 'Autre',
  };
}
