import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_passager/models/banniere.dart';
import 'package:tambour_passager/models/ville.dart';
import 'package:tambour_passager/providers/banniere_provider.dart';
import 'package:tambour_passager/providers/recherche_provider.dart';

/// Carrousel d'images de l'accueil. Contenu, ordre et dates de diffusion sont gérés
/// dans l'administration (Plateforme › Bannières) ; masqué s'il n'y a aucune bannière.
class CarrouselBannieres extends ConsumerStatefulWidget {
  /// Délai entre deux défilements automatiques.
  final Duration intervalle;
  const CarrouselBannieres({super.key, this.intervalle = const Duration(seconds: 5)});
  @override
  ConsumerState<CarrouselBannieres> createState() => _CarrouselBannieresState();
}

class _CarrouselBannieresState extends ConsumerState<CarrouselBannieres> {
  final _controleur = PageController(viewportFraction: 0.92);
  Timer? _minuteur;
  int _index = 0;
  int _nombre = 0;

  void _demarrer(int nombre) {
    if (nombre == _nombre) return;
    _nombre = nombre;
    _minuteur?.cancel();
    if (nombre < 2) return;
    _minuteur = Timer.periodic(widget.intervalle, (_) {
      if (!mounted || !_controleur.hasClients) return;
      final suivant = (_index + 1) % _nombre;
      _controleur.animateToPage(suivant, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _ouvrir(Banniere b) async {
    switch (b.action) {
      case 'recherche':
        if (b.departId == null || b.arriveeId == null) return;
        context.push('/resultats', extra: RechercheParams(
          villeDepart: Ville(id: b.departId!, nom: b.departNom ?? '', region: ''),
          villeArrivee: Ville(id: b.arriveeId!, nom: b.arriveeNom ?? '', region: ''),
          date: DateTime.now(), nbPassagers: 1));
      case 'page':
        final route = b.routePage;
        if (route != null) context.push(route);
      case 'lien':
        final uri = Uri.tryParse(b.lien);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannieres = ref.watch(bannieresProvider).valueOrNull ?? const <Banniere>[];
    _demarrer(bannieres.length);
    if (bannieres.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      const SizedBox(height: 28),
      SizedBox(
        // Plus haute quand l'utilisateur agrandit le texte du téléphone
        height: MediaQuery.textScalerOf(context).scale(160).clamp(160, 230).toDouble(),
        child: PageView.builder(
          controller: _controleur,
          itemCount: bannieres.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CarteBanniere(banniere: bannieres[i], onTap: () => _ouvrir(bannieres[i])),
          ),
        ),
      ),
      if (bannieres.length > 1) ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < bannieres.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 18 : 6, height: 6,
              decoration: BoxDecoration(
                color: i == _index ? TamBourColors.primary : TamBourColors.border,
                borderRadius: BorderRadius.circular(3)),
            ),
        ]),
      ],
    ]);
  }
}

class _CarteBanniere extends StatelessWidget {
  final Banniere banniere;
  final VoidCallback onTap;
  const _CarteBanniere({required this.banniere, required this.onTap});

  Color get _fond {
    final hex = banniere.couleurFond.replaceFirst('#', '');
    return hex.length == 6 ? Color(int.parse('FF$hex', radix: 16)) : TamBourColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final b = banniere;
    final cliquable = b.action != 'aucune';
    final aTexte = b.titre.isNotEmpty || b.sousTitre.isNotEmpty || b.texteBouton.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: _fond,
        child: InkWell(
          onTap: cliquable ? onTap : null,
          child: Stack(fit: StackFit.expand, children: [
            if (b.imageUrl != null)
              Image.network(b.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            if (aTexte)
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [Color(0xCC072A21), Color(0x00072A21)], stops: [0.0, 0.85]))),
            if (aTexte)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (b.titre.isNotEmpty)
                    Text(b.titre, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15)),
                  if (b.sousTitre.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(b.sousTitre, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white.withOpacity(0.9))),
                  ],
                  if (b.texteBouton.isNotEmpty && cliquable) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: TamBourColors.gold, borderRadius: BorderRadius.circular(20)),
                      child: Text(b.texteBouton, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF072A21))),
                    ),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
