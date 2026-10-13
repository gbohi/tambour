enum TypeNotification { confirmation, rappel, retard, promotion, info }

class NotificationItem {
  final String id;
  final TypeNotification type;
  final String titre;
  final String message;
  final DateTime date;
  final bool lue;
  final String? trajetId;

  const NotificationItem({
    required this.id, required this.type, required this.titre,
    required this.message, required this.date, this.lue = false, this.trajetId,
  });

  NotificationItem copyWith({bool? lue}) => NotificationItem(
    id: id, type: type, titre: titre, message: message,
    date: date, lue: lue ?? this.lue, trajetId: trajetId);

  static List<NotificationItem> mockNotifications() => [
    NotificationItem(id: 'n1', type: TypeNotification.confirmation,
      titre: 'Réservation confirmée',
      message: 'Votre billet Abidjan → Bouaké du 8 mai a été confirmé. Siège 7A.',
      date: DateTime.now().subtract(const Duration(minutes: 15)), lue: false),
    NotificationItem(id: 'n2', type: TypeNotification.rappel,
      titre: 'Départ dans 2 heures',
      message: 'Rappel : votre bus Abidjan → Yamoussoukro part à 08h30. Soyez à la gare 30 min avant.',
      date: DateTime.now().subtract(const Duration(hours: 2)), lue: false),
    NotificationItem(id: 'n3', type: TypeNotification.retard,
      titre: 'Léger retard signalé',
      message: 'Le bus Trans Ivoire AB-2341-CI accuse un retard de 20 minutes. Nouveau départ estimé : 06h20.',
      date: DateTime.now().subtract(const Duration(hours: 5)), lue: true),
    NotificationItem(id: 'n4', type: TypeNotification.promotion,
      titre: 'Offre flash — 20% de réduction',
      message: 'Ce week-end : -20% sur Abidjan → San-Pédro. Code : WEEKEND20.',
      date: DateTime.now().subtract(const Duration(days: 1)), lue: true),
    NotificationItem(id: 'n5', type: TypeNotification.confirmation,
      titre: 'Réservation confirmée',
      message: 'Billet Abidjan → Daloa du 2 mai confirmé. Réf. YB202605021089.',
      date: DateTime.now().subtract(const Duration(days: 5)), lue: true),
    NotificationItem(id: 'n6', type: TypeNotification.info,
      titre: 'Nouveau : sièges VIP disponibles',
      message: 'La ligne Abidjan → Korhogo propose désormais des sièges VIP avec Wi-Fi.',
      date: DateTime.now().subtract(const Duration(days: 7)), lue: true),
  ];
}
