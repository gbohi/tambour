import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../models/gare.dart';

class GaresScreen extends StatefulWidget {
  const GaresScreen({super.key});

  @override
  State<GaresScreen> createState() => _GaresScreenState();
}

class _GaresScreenState extends State<GaresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final List<Gare> _gares = Gare.mockGares();
  Gare? _gareSelectionnee;
  late final MapController _mapController;
  bool _afficherCarte = true;

  static const LatLng _centreCi = LatLng(7.5400, -5.5471);
  static const double _zoomInitial = 6.5;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _mapController = MapController();
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectionnerGare(Gare gare) {
    setState(() => _gareSelectionnee = gare);
    _mapController.move(LatLng(gare.latitude, gare.longitude), 11.5);
    if (_tab.index == 1) _tab.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YoBusColors.background,
      body: Column(
        children: [
          _Header(nbGares: _gares.length),
          _TabBar(controller: _tab),
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CarteView(
                  gares: _gares,
                  gareSelectionnee: _gareSelectionnee,
                  mapController: _mapController,
                  onGareSelect: _selectionnerGare,
                  centreCi: _centreCi,
                  zoomInitial: _zoomInitial,
                ),
                _ListeView(
                  gares: _gares,
                  gareSelectionnee: _gareSelectionnee,
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
      color: YoBusColors.primary,
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
      color: YoBusColors.primary,
      child: TabBar(
        controller: controller,
        indicatorColor: YoBusColors.gold,
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

  const _CarteView({
    required this.gares,
    required this.gareSelectionnee,
    required this.mapController,
    required this.onGareSelect,
    required this.centreCi,
    required this.zoomInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: centreCi,
            initialZoom: zoomInitial,
            minZoom: 5.0,
            maxZoom: 16.0,
          ),
          children: [
            // Tuiles OpenStreetMap — gratuit, pas de clé API
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ci.yobus.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: gares.map((gare) {
                final estSel = gareSelectionnee?.id == gare.id;
                return Marker(
                  point: LatLng(gare.latitude, gare.longitude),
                  width: estSel ? 56 : 44,
                  height: estSel ? 72 : 58,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () => onGareSelect(gare),
                    child: _Marqueur(gare: gare, estSelectionne: estSel),
                  ),
                );
              }).toList(),
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
                border: Border.all(color: YoBusColors.border, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: YoBusColors.primary, size: 20),
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
              border: Border.all(color: YoBusColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: YoBusColors.primary),
                const SizedBox(width: 5),
                Text(
                  '${gares.length} gares',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: YoBusColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Fiche gare sélectionnée
        if (gareSelectionnee != null)
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: _FicheGare(
              gare: gareSelectionnee!,
              onNaviguer: () => mapController.move(
                LatLng(gareSelectionnee!.latitude, gareSelectionnee!.longitude),
                13,
              ),
            ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut).fadeIn(duration: 300.ms),
          ),
      ],
    );
  }
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
            color: estSelectionne ? YoBusColors.primary : gare.estPrincipale ? YoBusColors.primary : YoBusColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: YoBusColors.primary, width: estSelectionne ? 3 : 2),
            boxShadow: [BoxShadow(color: YoBusColors.primary.withOpacity(estSelectionne ? 0.4 : 0.2), blurRadius: estSelectionne ? 12 : 6, offset: const Offset(0, 3))],
          ),
          child: Center(
            child: Icon(
              Icons.directions_bus_rounded,
              size: estSelectionne ? 22 : 18,
              color: estSelectionne || gare.estPrincipale ? Colors.white : YoBusColors.primary,
            ),
          ),
        ),
        Container(width: 2.5, height: 8, color: YoBusColors.primary),
        Container(width: 7, height: 7, decoration: const BoxDecoration(color: YoBusColors.primary, shape: BoxShape.circle)),
        if (estSelectionne)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: YoBusColors.primary, borderRadius: BorderRadius.circular(5)),
            child: Text(
              gare.ville,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _FicheGare extends StatelessWidget {
  final Gare gare;
  final VoidCallback onNaviguer;

  const _FicheGare({required this.gare, required this.onNaviguer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YoBusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YoBusColors.primary, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: YoBusColors.primary, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gare.nom, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: YoBusColors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: YoBusColors.textHint),
                      const SizedBox(width: 4),
                      Text(gare.heuresOuverture, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: YoBusColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  gare.adresse,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (gare.compagnies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: gare.compagnies.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: YoBusColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                child: Text(c, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600, color: YoBusColors.textSecondary)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Voir les trajets'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YoBusColors.primary,
                    side: const BorderSide(color: YoBusColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNaviguer,
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Y aller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YoBusColors.primary, foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                color: estSel ? YoBusColors.primaryLight : YoBusColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: estSel ? YoBusColors.primary : YoBusColors.border,
                  width: estSel ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: estSel ? YoBusColors.primary : YoBusColors.primaryLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.directions_bus_rounded, color: estSel ? Colors.white : YoBusColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(gare.nom, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: estSel ? YoBusColors.primaryDark : YoBusColors.textPrimary)),
                            ),
                            if (gare.estPrincipale)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: YoBusColors.goldLight, borderRadius: BorderRadius.circular(5)),
                                child: const Text('Principale', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w700, color: YoBusColors.gold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(gare.ville, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: YoBusColors.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(gare.adresse, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (gare.compagnies.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('${gare.compagnies.length} compagnie${gare.compagnies.length > 1 ? 's' : ''} · ${gare.heuresOuverture}',
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: YoBusColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: YoBusColors.textHint, size: 20),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50), duration: 300.ms).slideX(begin: 0.04, end: 0),
          ),
        );
      },
    );
  }
}
