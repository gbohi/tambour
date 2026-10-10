import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = NotificationItem.mockNotifications();
  }

  void _marquerToutesLues() {
    setState(() {
      _notifs = _notifs.map((n) => n.copyWith(lue: true)).toList();
    });
  }

  void _marquerLue(String id) {
    setState(() {
      _notifs = _notifs.map((n) => n.id == id ? n.copyWith(lue: true) : n).toList();
    });
  }

  int get _nbNonLues => _notifs.where((n) => !n.lue).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YoBusColors.background,
      body: Column(
        children: [
          _Header(nbNonLues: _nbNonLues, onToutLire: _marquerToutesLues),
          Expanded(
            child: _notifs.isEmpty
                ? _Vide()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _notifs.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotifCard(
                          notif: _notifs[i],
                          index: i,
                          onTap: () => _marquerLue(_notifs[i].id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int nbNonLues;
  final VoidCallback onToutLire;

  const _Header({required this.nbNonLues, required this.onToutLire});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YoBusColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (nbNonLues > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(
                          color: YoBusColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$nbNonLues',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (nbNonLues > 0)
                GestureDetector(
                  onTap: onToutLire,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tout lire',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationItem notif;
  final int index;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.index, required this.onTap});

  Color get _iconBg => switch (notif.type) {
    TypeNotification.confirmation => YoBusColors.primaryLight,
    TypeNotification.rappel => const Color(0xFFF0F8FF),
    TypeNotification.retard => const Color(0xFFFFF3CD),
    TypeNotification.promotion => const Color(0xFFFFF8EC),
    TypeNotification.info => YoBusColors.surfaceVariant,
  };

  Color get _iconColor => switch (notif.type) {
    TypeNotification.confirmation => YoBusColors.primary,
    TypeNotification.rappel => const Color(0xFF0066CC),
    TypeNotification.retard => YoBusColors.warning,
    TypeNotification.promotion => YoBusColors.gold,
    TypeNotification.info => YoBusColors.textSecondary,
  };

  IconData get _icon => switch (notif.type) {
    TypeNotification.confirmation => Icons.check_circle_rounded,
    TypeNotification.rappel => Icons.alarm_rounded,
    TypeNotification.retard => Icons.schedule_rounded,
    TypeNotification.promotion => Icons.local_offer_rounded,
    TypeNotification.info => Icons.info_rounded,
  };

  String _tempsEcoule(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.lue ? YoBusColors.surface : YoBusColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.lue ? YoBusColors.border : YoBusColors.primary.withOpacity(0.2),
            width: notif.lue ? 0.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: notif.lue ? FontWeight.w600 : FontWeight.w800,
                            color: YoBusColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.lue)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: YoBusColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: YoBusColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tempsEcoule(notif.date),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: YoBusColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
        delay: Duration(milliseconds: 60 + index * 60),
        duration: 300.ms,
      ).slideX(begin: 0.05, end: 0),
    );
  }
}

class _Vide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: YoBusColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_rounded,
                color: YoBusColors.primary, size: 38),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: YoBusColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous serez notifié de vos réservations\net des offres disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: YoBusColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
