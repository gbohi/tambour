import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/ligne_populaire.dart';
import '../../models/ville.dart';
import '../../providers/ligne_provider.dart';
import '../../providers/recherche_provider.dart';
import '../../widgets/ligne_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/logo_tambour.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TamBourColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const _GreenBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HeroHeader(),
                        const _SearchCard(),
                        const SizedBox(height: 28),
                        const _PromoBanner(),
                        const SizedBox(height: 28),
                        const _LignesPopulaires(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentNavIndex,
        onTap: (i) {
          setState(() => _currentNavIndex = i);
          switch (i) {
            case 1: context.push('/mes-billets'); break;
            case 2: context.push('/gares'); break;
            case 3: context.push('/compte'); break;
            default: break;
          }
        },
      ),
    );
  }
}

class _GreenBackground extends StatelessWidget {
  const _GreenBackground();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 340,
          decoration: const BoxDecoration(
            color: TamBourColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -40, right: -40, child: Container(width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: TamBourColors.primaryDark.withOpacity(0.5)))),
              Positioned(top: 60, right: 20, child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: TamBourColors.gold.withOpacity(0.15)))),
            ],
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const LogoTamBour(taille: 24).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
          const Spacer(),
          _IconBtn(icon: Icons.notifications_outlined, onTap: () => context.push('/notifications')).animate().fadeIn(delay: 200.ms),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.person_outline_rounded, onTap: () => context.push('/compte')).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.15)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bonjour 👋', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Colors.white.withOpacity(0.8))).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 4),
          const Text("Où allez-vous\naujourd'hui ?", style: TextStyle(fontFamily: 'Outfit', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SearchCard extends ConsumerStatefulWidget {
  const _SearchCard();
  @override
  ConsumerState<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends ConsumerState<_SearchCard> {
  Ville? _villeDepart;
  Ville? _villeArrivee;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _passagers = 1;
  final List<Ville> _villes = Ville.mockVilles;

  String get _dateLabel {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (_date.year == now.year && _date.month == now.month && _date.day == now.day) return "Aujourd'hui";
    if (_date.year == tomorrow.year && _date.month == tomorrow.month && _date.day == tomorrow.day) return 'Demain';
    return DateFormat('EEE d MMM', 'fr_FR').format(_date);
  }

  void _swap() => setState(() { final t = _villeDepart; _villeDepart = _villeArrivee; _villeArrivee = t; });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: TamBourColors.primary, onPrimary: Colors.white)),
        child: child!));
    if (picked != null) setState(() => _date = picked);
  }

  void _pickVille(bool isDepart) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _VillePickerSheet(
        villes: _villes, selected: isDepart ? _villeDepart : _villeArrivee,
        titre: isDepart ? 'Ville de départ' : "Ville d'arrivée",
        onSelected: (v) { setState(() { if (isDepart) _villeDepart = v; else _villeArrivee = v; }); Navigator.pop(context); }));
  }

  void _rechercher() {
    if (_villeDepart == null || _villeArrivee == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Veuillez choisir votre départ et arrivée'),
        backgroundColor: TamBourColors.primary, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    if (_villeDepart!.id == _villeArrivee!.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Départ et arrivée doivent être différents'),
        backgroundColor: TamBourColors.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    context.push('/resultats', extra: RechercheParams(
      villeDepart: _villeDepart!, villeArrivee: _villeArrivee!,
      date: _date, nbPassagers: _passagers));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: TamBourColors.surface, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))]),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _VilleField(label: 'Départ', icon: Icons.radio_button_checked_rounded, iconColor: TamBourColors.primary, ville: _villeDepart, onTap: () => _pickVille(true)),
                      _RouteLine(),
                      _VilleField(label: 'Arrivée', icon: Icons.location_on_rounded, iconColor: TamBourColors.gold, ville: _villeArrivee, onTap: () => _pickVille(false)),
                    ],
                  ),
                  Positioned(right: 0, top: 0, bottom: 0, child: Center(child: _SwapButton(onTap: _swap))),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(child: _InfoChip(icon: Icons.calendar_today_rounded, label: 'Date', value: _dateLabel, onTap: _pickDate)),
                  const SizedBox(width: 12),
                  Expanded(child: _PassagersChip(count: _passagers,
                    onDecrement: () { if (_passagers > 1) setState(() => _passagers--); },
                    onIncrement: () { if (_passagers < 9) setState(() => _passagers++); })),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                onPressed: _rechercher,
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text('Rechercher un trajet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TamBourColors.primary, foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0, textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700))),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.15, end: 0, delay: 300.ms, curve: Curves.easeOut),
    );
  }
}

class _VilleField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Ville? ville;
  final VoidCallback onTap;
  const _VilleField({required this.label, required this.icon, required this.iconColor, required this.ville, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textHint, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(ville?.nom ?? 'Choisir une ville', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                fontWeight: ville != null ? FontWeight.w700 : FontWeight.w400,
                color: ville != null ? TamBourColors.textPrimary : TamBourColors.textHint)),
            ])),
            if (ville != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(6)),
              child: Text(ville!.region.split(' ').first, style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: TamBourColors.primary, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 8, child: Row(children: [const SizedBox(width: 29), Container(width: 2, height: 8, color: TamBourColors.border)]));
  }
}

class _SwapButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SwapButton({required this.onTap});
  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  void _onTap() { _ctrl.forward(from: 0).then((_) => _ctrl.reverse()); widget.onTap(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (_, child) => Transform.rotate(angle: _rotation.value * 3.14159, child: child),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: TamBourColors.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: TamBourColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
          child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 20)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _InfoChip({required this.icon, required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 18, color: TamBourColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textHint, fontWeight: FontWeight.w500)),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
          ])),
        ]),
      ),
    );
  }
}

class _PassagersChip extends StatelessWidget {
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _PassagersChip({required this.count, required this.onDecrement, required this.onIncrement});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: TamBourColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(builder: (context, c) => Row(children: [
        // L'icône est masquée sur les petits écrans pour laisser la place aux boutons
        if (c.maxWidth >= 140) ...[
          const Icon(Icons.person_outline_rounded, size: 18, color: TamBourColors.primary),
          const SizedBox(width: 6),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Passagers', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: TamBourColors.textHint, fontWeight: FontWeight.w500)),
          Text('$count', style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
        ])),
        _CounterBtn(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: 4),
        _CounterBtn(icon: Icons.add, onTap: onIncrement),
      ])),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 26, height: 26,
        decoration: BoxDecoration(color: TamBourColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: TamBourColors.primary)),
    );
  }
}

class _VillePickerSheet extends StatefulWidget {
  final List<Ville> villes;
  final Ville? selected;
  final String titre;
  final ValueChanged<Ville> onSelected;
  const _VillePickerSheet({required this.villes, required this.selected, required this.titre, required this.onSelected});
  @override
  State<_VillePickerSheet> createState() => _VillePickerSheetState();
}

class _VillePickerSheetState extends State<_VillePickerSheet> {
  late List<Ville> _filtered;
  @override
  void initState() { super.initState(); _filtered = widget.villes; }
  void _filter(String q) => setState(() {
    _filtered = widget.villes.where((v) => v.nom.toLowerCase().contains(q.toLowerCase()) || v.region.toLowerCase().contains(q.toLowerCase())).toList();
  });
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.92, minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(color: TamBourColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: TamBourColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.titre, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: TamBourColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                onChanged: _filter, autofocus: true,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Rechercher une ville...', prefixIcon: const Icon(Icons.search_rounded, color: TamBourColors.textHint, size: 20),
                  filled: true, fillColor: TamBourColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16))),
              const SizedBox(height: 16),
            ])),
          Expanded(child: _filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off_rounded, size: 48, color: TamBourColors.textHint),
                const SizedBox(height: 12),
                const Text('Aucune ville trouvée', style: TextStyle(fontFamily: 'Outfit', color: TamBourColors.textHint, fontSize: 15))]))
            : Material(type: MaterialType.transparency, child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final v = _filtered[i];
                  final isSel = widget.selected?.id == v.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(width: 42, height: 42,
                      decoration: BoxDecoration(color: isSel ? TamBourColors.primary : TamBourColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.location_city_rounded, color: isSel ? Colors.white : TamBourColors.primary, size: 20)),
                    title: Text(v.nom, style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: TamBourColors.textPrimary)),
                    subtitle: Text(v.region, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.textSecondary)),
                    trailing: isSel ? const Icon(Icons.check_circle_rounded, color: TamBourColors.primary, size: 20) : null,
                    onTap: () => widget.onSelected(v));
                }))),
        ]),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(color: TamBourColors.goldLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: TamBourColors.gold.withOpacity(0.3))),
        child: Row(children: [
          const SizedBox(width: 20),
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: TamBourColors.gold.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_rounded, color: TamBourColors.gold, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Offre de lancement', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF7A4F00))),
            const SizedBox(height: 4),
            Text('-15% sur votre 1er trajet avec le code TAMBOUR15', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: TamBourColors.gold.withOpacity(0.8))),
          ])),
          const SizedBox(width: 16),
        ]),
      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: 0.1, end: 0, delay: 500.ms),
    );
  }
}

class _LignesPopulaires extends ConsumerWidget {
  const _LignesPopulaires();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lignes = ref.watch(lignesPopulairesProvider).valueOrNull ?? LignePopulaire.parDefaut;
    final apercu = lignes.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(titre: 'Lignes populaires', actionLabel: 'Voir tout',
        onAction: () => context.push('/lignes-populaires')),
      const SizedBox(height: 16),
      SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: apercu.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => LigneCard(ligne: apercu[i])
            .animate().fadeIn(delay: Duration(milliseconds: 600 + i * 80)).slideX(begin: 0.1, end: 0)),
      ),
    ]);
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TamBourColors.surface,
        border: const Border(top: BorderSide(color: TamBourColors.border, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex, onTap: onTap, elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: TamBourColors.primary, unselectedItemColor: TamBourColors.textHint,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Recherche'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), activeIcon: Icon(Icons.confirmation_number_rounded), label: 'Mes billets'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on_rounded), label: 'Gares'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Compte'),
          ]),
      ),
    );
  }
}
