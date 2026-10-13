import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tambour_chauffeur/services/partage_position.dart';
import 'package:tambour_commun/testing/faux_suivi.dart';

void main() {
  test('envoie la position dès le premier point GPS et récupère le temps restant', () async {
    final p = PartagePosition(service: FauxSuiviService(), autoriser: () async => EtatPartage.actif,
      flux: () => Stream.value(const PointGps(6.62, -4.62, vitesseKmh: 72)));
    await p.demarrer('t1');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(p.actif, isTrue);
    expect(p.minutesRestantes, 95);
    expect(p.dernierEnvoi, isNotNull);
    await p.arreter();
    expect(p.etat, EtatPartage.inactif);
    expect(p.trajetId, isNull);
  });

  test('explique pourquoi la position ne peut pas être partagée', () async {
    final p = PartagePosition(service: FauxSuiviService(), autoriser: () async => EtatPartage.gpsDesactive);
    await p.demarrer('t1');
    expect(p.etat, EtatPartage.gpsDesactive);
    expect(p.message, contains('localisation'));
  });

  test('continue en arrière-plan : notification permanente sur Android, mode location sur iOS', () {
    final android = PartagePosition.reglagesPour(TargetPlatform.android) as AndroidSettings;
    final notif = android.foregroundNotificationConfig!;
    expect(notif.setOngoing, isTrue);
    expect(notif.enableWakeLock, isTrue);
    expect(notif.notificationIcon.name, 'ic_notification');
    expect(android.distanceFilter, 25);

    final ios = PartagePosition.reglagesPour(TargetPlatform.iOS) as AppleSettings;
    expect(ios.allowBackgroundLocationUpdates, isTrue);
    expect(ios.pauseLocationUpdatesAutomatically, isFalse);
    expect(ios.showBackgroundLocationIndicator, isTrue);
  });
}
