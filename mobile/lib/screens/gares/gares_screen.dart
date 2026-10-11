import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/gare.dart';
import '../../services/gare_service.dart';
import '../../services/itineraire_service.dart';
import '../../widgets/app_snackbar.dart';
import 'departs_gare_screen.dart';
import 'widgets/fiche_gare_bottom.dart';

class GaresScreen extends StatefulWidget {
  const GaresScreen({super.key});

  @override
  State<GaresScreen> createState() => _GaresScreenState();
}

class _GaresScreenState extends State<GaresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final MapController _mapController;
  final _itineraireService = ItineraireService();
  List<Gare> _gares = Gare.mockGares();
  Gare? _gareSelectionnee;

  // Itinéraire « Y aller »
  LatLng? _position;
  Itineraire? _itineraire;
  bool _calculEnCours = false;

  static const LatLng _centreCi = LatLng(7.5400, -5.5471);
  static const double _zoomInitial = 6.5;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _mapController = MapController();
    _tab.addListener(() => setState(() {}));
    GareService().getGares().then((g) { if (mounted) setState(() => _gares = g); });
  }

  @override
  void dispose() {
    _tab.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectionnerGare(Gare gare) {
    setState(() { _gareSelectionnee = gare; _itineraire = null; });
    if (_tab.index == 1) _tab.index = 0;
    _mapController.move(LatLng(gare.latitude, gare.longitude), 13);
  }

  void _fermerFiche() => setState(() { _gareSelectionnee = null; _itineraire = null; });

  void _voirTrajets(Gare gare) => Navigator.push(context,
    MaterialPageRoute(builder: (_) => DepartsGareScreen(gare: gare)));

  Future<void> _yAller(Gare gare) async {
    setState(() => _calculEnCours = true);
    try {
      final position = await _itineraireService.positionActuelle();
      final arrivee = LatLng(gare.latitude, gare.longitude);
      final it = await _itineraireService.calculer(position, arrivee);
      if (!mounted || _gareSelectionnee?.id != gare.id) return;
      setState(() { _position = position; _itineraire = it; });
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([position, arrivee, ...it.points]),
        padding: const EdgeInsets.fromLTRB(48, 72, 48, 300)));
    } on ItineraireException catch (e) {
      if (mounted) AppSnackbar.erreur(context, e.message);
    } catch (_) {
      if (mounted) AppSnackbar.erreur(context, 'Position introuvable. Réessayez à l\'extérieur ou vérifiez le GPS.');
    } finally {
      if (mounted) setState(() => _calculEnCours = false);
    }
  }

  /// Navigation guidée dans l'application de cartes du téléphone.
  Future<void> _ouvrirGps(Gare gare) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1'
      '&destination=${gare.latitude},${gare.longitude}&travelmode=driving');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) AppSnackbar.erreur(context, "Impossible d'ouvrir l'application de cartes.");
  }

  @override
  Widget build(BuildContext context) {
    final gare = _gareSelectionnee;
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(
        children: [
          _Header(nbGares: _gares.length),
          _TabBar(controller: _tab),
          Expanded(
            // IndexedStack (et non TabBarView) : la carte reste en mémoire quand on affiche la liste,
            // sinon son contrôleur serait détruit puis réutilisé.
            child: IndexedStack(
              index: _tab.index,
              children: [
                _CarteView(
                  gares: _gares,
                  gareSelectionnee: gare,
                  mapController: _mapController,
                  onGareSelect: _selectionnerGare,
                  centreCi: _centreCi,
                  zoomInitial: _zoomInitial,
                  position: _position,
                  itineraire: _itineraire,
                  fiche: gare == null ? null : FicheGareBottom(
                    gare: gare,
                    itineraire: _itineraire,
                    calculEnCours: _calculEnCours,
                    onVoirTrajets: () => _voirTrajets(gare),
                    onYAller: () => _yAller(gare),
                    onOuvrirGps: () => _ouvrirGps(gare),
                    onFermer: _fermerFiche,
                  ),
                ),
                _ListeView(
                  gares: _gares,
                  gareSelectionnee: gare,
                  onGareSelect: _selectionnerGare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int nbGares;
  const _Header({required this.nbGares});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carte des gares',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$nbGares gares partenaires',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: TabBar(
        controller: controller,
        indicatorColor: TamBourColors.gold,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Carte'),
          Tab(icon: Icon(Icons.list_rounded, size: 18), text: 'Liste'),
        ],
      ),
    );
  }
}

// ── Carte OSM ─────────────────────────────────────────────────────────────────

class _CarteView extends StatelessWidget {
  final List<Gare> gares;
  final Gare? gareSelectionnee;
  final MapController mapController;
  final ValueChanged<Gare> onGareSelect;
  final LatLng centreCi;
  final double zoomInitial;
  final LatLng? position;
  final Itineraire? itineraire;
  final Widget? fiche;

  const _CarteView({
    required this.gares,
    required this.gareSelectionnee,
    required this.mapController,
    required this.onGareSelect,
    required this.centreCi,
    required this.zoomInitial,
    this.position,
    this.itineraire,
    this.fiche,
  });

  @override
  Widget build(BuildContext context) {
    final it = itineraire;
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: centreCi,
            initialZoom: zoomInitial,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            // Tuiles OpenStreetMap — gratuit, pas de clé API
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ci.tambour.app',
              maxZoom: 19,
            ),
            if (it != null)
              PolylineLayer(polylines: [
                Polyline(points: it.points, strokeWidth: 5, color: TamBourColors.primary,
                  borderStrokeWidth: 2, borderColor: Colors.white,
                  isDotted: it.estimation),
              ]),
            MarkerLayer(
              markers: [
                ...gares.map((gare) {
                  final estSel = gareSelectionnee?.id == gare.id;
                  return Marker(
                    point: LatLng(gare.latitude, gare.longitude),
                    width: estSel ? 96 : 44,
                    height: estSel ? 84 : 58,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => onGareSelect(gare),
                      // FittedBox : le marqueur ne déborde jamais de sa zone, quelle que soit la taille du texte
                      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
                        child: _Marqueur(gare: gare, estSelectionne: estSel)),
                    ),
                  );
                }),
                if (position != null && it != null)
                  Marker(point: position!, width: 24, height: 24, child: const _PointUtilisateur()),
              ],
            ),
          ],
        ),

        // Bouton recentrer
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => mapController.move(centreCi, zoomInitial),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TamBourColors.border, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.zoom_out_map_rounded,
                  color: TamBourColors.primary, size: 20),
            ),
          ),
        ),

        // Compteur
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TamBourColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: TamBourColors.primary),
                const SizedBox(width: 5),
                Text(
                  '${gares.length} gares',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TamBourColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Fiche gare sélectionnée (défilable si l'écran est petit)
        if (fiche != null)
          Positioned(
            bottom: 12, left: 12, right: 12,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
              child: SingleChildScrollView(child: fiche!),
            ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut).fadeIn(duration: 300.ms),
          ),
      ],
    );
  }
}

class _PointUtilisateur extends StatelessWidget {
  const _PointUtilisateur();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2F6FD6), shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [BoxShadow(color: const Color(0xFF2F6FD6).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]),
  );
}

class _Marqueur extends StatelessWidget {
  final Gare gare;
  final bool estSelectionne;

  const _Marqueur({required this.gare, required this.estSelectionne});

  @override
  Widget build(BuildContext context) {
    final taille = estSelectionne ? 44.0 : 36.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: taille,
          height: taille,
          decoration: BoxDecoration(
            color: estSelectionne ? TamBourColors.primary : gare.estPrincipale ? TamBourColors.primary : TamBourColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: TamBourColors.primary, width: estSelectionne ? 3 : 2),
            boxShadow: [BoxShadow(color: TamBourColors.primary.withOpacity(estSelectionne ? 0.4 : 0.2), blurRadius: estSelectionne ? 12 : 6, offset: const Offset(0, 3))],
          ),
          child: Center(
            child: Icon(
              Icons.directions_bus_rounded,
              size: estSelectionne ? 22 : 18,
              color: estSelectionne || gare.estPrincipale ? Colors.white : TamBourColors.primary,
            ),
          ),
        ),
        Container(width: 2.5, height: 8, color: TamBourColors.primary),
        Container(width: 7, height: 7, decoration: const BoxDecoration(color: TamBourColors.primary, shape: BoxShape.circle)),
        if (estSelectionne)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: TamBourColors.primary, borderRadius: BorderRadius.circular(5)),
            child: Text(
              gare.ville, maxLines: 1,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ── Liste ─────────────────────────────────────────────────────────────────────

class _ListeView extends StatelessWidget {
  final List<Gare> gares;
  final Gare? gareSelectionnee;
  final ValueChanged<Gare> onGareSelect;

  const _ListeView({required this.gares, required this.gareSelectionnee, required this.onGareSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: gares.length,
      itemBuilder: (context, i) {
        final gare = gares[i];
        final estSel = gareSelectionnee?.id == gare.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onGareSelect(gare),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: estSel ? TamBourColors.primaryLight : TamBourColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: estSel ? TamBourColors.primary : TamBourColors.border,
                  width: estSel ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: estSel ? TamBourColors.primary : TamBourColors.primaryLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.directions_bus_rounded, color: estSel ? Colors.white : TamBourColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(gare.nom, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: estSel ? TamBourColors.primaryDark : TamBourColors.textPrimary)),
                            ),
                            if (gare.estPrincipale)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: TamBourColors.goldLight, borderRadius: BorderRadius.circular(5)),
                                child: const Text('Principale', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w700, color: TamBourColors.gold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(gare.ville, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(gare.adresse, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (gare.compagnies.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('${gare.compagnies.length} compagnie${gare.compagnies.length > 1 ? 's' : ''} · ${gare.heuresOuverture}',
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: TamBourColors.textHint, size: 20),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50), duration: 300.ms).slideX(begin: 0.04, end: 0),
          ),
        );
      },
    );
  }
}
