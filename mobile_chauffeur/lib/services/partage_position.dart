import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tambour_commun/services/suivi_service.dart';

enum EtatPartage { inactif, demarrage, actif, refuse, gpsDesactive, erreur }

/// Point GPS lu sur le téléphone (indépendant du plugin, pour les tests).
class PointGps {
  final double latitude, longitude;
  final double? vitesseKmh, cap, precisionM;
  const PointGps(this.latitude, this.longitude, {this.vitesseKmh, this.cap, this.precisionM});
}

/// Partage la position du car pendant le trajet : lit le GPS du téléphone et l'envoie
/// au serveur toutes les [intervalle] (15 s), pour le suivi des voyageurs.
///
/// Une seule instance pour toute l'application ([instance]) : le partage continue quand le
/// chauffeur quitte l'écran du trajet, et s'arrête à la fin du trajet ou à la déconnexion.
class PartagePosition extends ChangeNotifier {
  static final PartagePosition instance = PartagePosition();

  final SuiviService _service;
  final Duration intervalle;
  final Future<EtatPartage> Function() _autoriser;
  final Stream<PointGps> Function() _flux;

  PartagePosition({SuiviService? service, this.intervalle = const Duration(seconds: 15),
      Future<EtatPartage> Function()? autoriser, Stream<PointGps> Function()? flux})
    : _service = service ?? SuiviService(),
      _autoriser = autoriser ?? _autorisationGps,
      _flux = flux ?? _fluxGps;

  EtatPartage etat = EtatPartage.inactif;
  String? trajetId;
  String? message;
  DateTime? dernierEnvoi;
  int? minutesRestantes;
  PointGps? _dernier;
  StreamSubscription<PointGps>? _abonnement;
  Timer? _minuteur;
  bool _envoiEnCours = false;

  bool get actif => etat == EtatPartage.actif;

  Future<void> demarrer(String id) async {
    if (trajetId == id && (etat == EtatPartage.actif || etat == EtatPartage.demarrage)) return;
    await arreter();
    trajetId = id;
    _changer(EtatPartage.demarrage);
    final autorisation = await _autoriser();
    if (trajetId != id) return;
    if (autorisation != EtatPartage.actif) {
      message = autorisation == EtatPartage.gpsDesactive
        ? 'Activez la localisation du téléphone pour partager la position du car.'
        : 'Autorisez TamBour Pro à utiliser la position pour que les voyageurs suivent le car.';
      _changer(autorisation);
      return;
    }
    message = null;
    _abonnement = _flux().listen((p) {
      final premier = _dernier == null;
      _dernier = p;
      if (premier) _envoyer();
    }, onError: (Object e) {
      message = 'Position GPS indisponible.';
      _changer(EtatPartage.erreur);
    });
    _minuteur = Timer.periodic(intervalle, (_) => _envoyer());
    _changer(EtatPartage.actif);
  }

  Future<void> _envoyer() async {
    final p = _dernier, id = trajetId;
    if (p == null || id == null || _envoiEnCours) return;
    _envoiEnCours = true;
    try {
      minutesRestantes = await _service.envoyerPosition(id, latitude: p.latitude, longitude: p.longitude,
        vitesseKmh: p.vitesseKmh, cap: p.cap, precisionM: p.precisionM);
      dernierEnvoi = DateTime.now();
      message = null;
      if (etat != EtatPartage.actif) etat = EtatPartage.actif;
    } on SuiviException catch (e) {
      message = e.message;   // nouvel essai au prochain intervalle
    } finally {
      _envoiEnCours = false;
      notifyListeners();
    }
  }

  Future<void> arreter() async {
    _minuteur?.cancel();
    _minuteur = null;
    // Pas d'attente : la fermeture du flux GPS n'a rien à rendre, on ne bloque pas l'arrêt.
    unawaited(_abonnement?.cancel());
    _abonnement = null;
    _dernier = null;
    trajetId = null;
    if (etat != EtatPartage.inactif) _changer(EtatPartage.inactif);
  }

  void _changer(EtatPartage e) { etat = e; notifyListeners(); }

  @override
  void dispose() {
    _minuteur?.cancel();
    _abonnement?.cancel();
    super.dispose();
  }

  static Future<EtatPartage> _autorisationGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return EtatPartage.gpsDesactive;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      return p == LocationPermission.denied || p == LocationPermission.deniedForever
        ? EtatPartage.refuse : EtatPartage.actif;
    } catch (_) {
      return EtatPartage.erreur;
    }
  }

  static Stream<PointGps> _fluxGps() => Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25))
    .map((p) => PointGps(p.latitude, p.longitude,
      vitesseKmh: p.speed >= 0 ? p.speed * 3.6 : null, cap: p.heading >= 0 ? p.heading : null, precisionM: p.accuracy));
}
