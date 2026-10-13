import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/models/suivi.dart';

/// Carte du suivi : ligne prévue (pointillés), parcours réel, gares de départ/arrivée et position du car.
class CarteSuivi extends StatefulWidget {
  final SuiviTrajet suivi;
  /// Identifiant transmis au serveur de tuiles OpenStreetMap.
  final String userAgent;
  const CarteSuivi({super.key, required this.suivi, this.userAgent = 'ci.tambour.app'});
  @override
  State<CarteSuivi> createState() => _CarteSuiviState();
}

class _CarteSuiviState extends State<CarteSuivi> {
  final _controleur = MapController();
  bool _pret = false;

  List<LatLng> get _points => [
    if (widget.suivi.pointDepart != null) widget.suivi.pointDepart!.position,
    if (widget.suivi.pointArrivee != null) widget.suivi.pointArrivee!.position,
    if (widget.suivi.position != null) widget.suivi.position!.position,
  ];

  void _recadrer() {
    final pts = _points;
    if (!_pret || pts.isEmpty) return;
    if (pts.length == 1) { _controleur.move(pts.first, 11); return; }
    _controleur.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(56)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suivi;
    final pts = _points;
    final centre = pts.isEmpty ? const LatLng(7.54, -5.55) : pts.first;
    return Stack(children: [
      FlutterMap(
        mapController: _controleur,
        options: MapOptions(
          initialCenter: centre, initialZoom: 7,
          initialCameraFit: pts.length >= 2
            ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(56)) : null,
          onMapReady: () => _pret = true,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: widget.userAgent, maxZoom: 19),
          PolylineLayer(polylines: [
            if (s.pointDepart != null && s.pointArrivee != null)
              Polyline(points: [s.pointDepart!.position, s.pointArrivee!.position],
                color: TamBourColors.marque.withValues(alpha: 0.35), strokeWidth: 3, isDotted: true),
            if (s.trace.length >= 2)
              Polyline(points: s.trace, color: TamBourColors.primary, strokeWidth: 5,
                borderColor: Colors.white, borderStrokeWidth: 2),
          ]),
          MarkerLayer(markers: [
            if (s.pointDepart != null)
              Marker(point: s.pointDepart!.position, width: 22, height: 22,
                child: const _Pastille(couleur: TamBourColors.primary)),
            if (s.pointArrivee != null)
              Marker(point: s.pointArrivee!.position, width: 40, height: 40, alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on_rounded, size: 40, color: TamBourColors.gold)),
            if (s.position != null)
              Marker(point: s.position!.position, width: 46, height: 46, child: _MarqueurCar(actif: s.source == 'gps')),
          ]),
          const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
        ],
      ),
      Positioned(right: 12, top: 12, child: Material(
        color: Colors.white, shape: const CircleBorder(), elevation: 3,
        child: IconButton(tooltip: 'Recentrer', onPressed: _recadrer,
          icon: const Icon(Icons.center_focus_strong_rounded, color: TamBourColors.marque)))),
    ]);
  }
}

class _Pastille extends StatelessWidget {
  final Color couleur;
  const _Pastille({required this.couleur});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: couleur, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]));
}

class _MarqueurCar extends StatelessWidget {
  final bool actif;
  const _MarqueurCar({required this.actif});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: actif ? TamBourColors.marque : TamBourColors.textSecondary, shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [BoxShadow(color: TamBourColors.marque.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 4)]),
    child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22));
}
