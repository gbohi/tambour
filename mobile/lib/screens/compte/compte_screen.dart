import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class CompteScreen extends ConsumerWidget {
  const CompteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(
        children: [
          _Header(
            nom: user?.nomComplet ?? 'Voyageur TamBour',
            email: user?.email ?? '',
            initiales: user?.initiales ?? 'TB',
            nbVoyages: user?.nbVoyages ?? 0,
            points: user?.pointsFidelite ?? 0,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                children: [
                  _Section(titre: 'Mon compte', items: [
                    _Item(icon: Icons.person_rounded, label: 'Modifier mon profil', onTap: () => context.push('/profil/edit')),
                    _Item(icon: Icons.confirmation_number_rounded, label: 'Mes billets', onTap: () => context.push('/mes-billets')),
                    _Item(icon: Icons.notifications_rounded, label: 'Notifications', onTap: () => context.push('/notifications')),
                    _Item(icon: Icons.location_on_rounded, label: 'Carte des gares', onTap: () => context.push('/gares')),
                  ]).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  _Section(titre: 'Fidélité & avantages', items: [
                    _Item(icon: Icons.star_rounded, label: 'Programme fidélité', trailing: _Badge('${user?.pointsFidelite ?? 0} pts', TamBourColors.gold), onTap: () {}),
                    _Item(icon: Icons.local_offer_rounded, label: 'Mes coupons & promos', onTap: () {}),
                  ]).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 16),
                  _Section(titre: 'Aide & support', items: [
                    _Item(icon: Icons.help_outline_rounded, label: 'Centre d\'aide', onTap: () {}),
                    _Item(icon: Icons.headset_mic_rounded, label: 'Contacter le support', onTap: () {}),
                    _Item(icon: Icons.star_outline_rounded, label: 'Noter l\'application', onTap: () {}),
                  ]).animate().fadeIn(delay: 260.ms),
                  const SizedBox(height: 16),
                  _DeconnexionBtn(
                    onTap: () async {
                      await ref.read(authProvider.notifier).deconnecter();
                      if (context.mounted) context.go('/auth');
                    },
                  ).animate().fadeIn(delay: 340.ms),
                  const SizedBox(height: 20),
                  Text(
                    'TamBour v1.0.0 · Côte d\'Ivoire',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: TamBourColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nom, email, initiales;
  final int nbVoyages, points;

  const _Header({
    required this.nom, required this.email, required this.initiales,
    required this.nbVoyages, required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TamBourColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Mon compte',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: Colors.white, size: 18),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 68, height: 68,
                    decoration: const BoxDecoration(
                      color: TamBourColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initiales,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(label: 'Voyages', value: '$nbVoyages', icon: Icons.directions_bus_rounded),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Points fidélité', value: '$points', icon: Icons.star_rounded, highlight: true),
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

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;

  const _StatCard({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? TamBourColors.gold.withOpacity(0.15) : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? TamBourColors.gold.withOpacity(0.3) : Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: highlight ? TamBourColors.gold : Colors.white70, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: highlight ? TamBourColors.gold : Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: highlight ? TamBourColors.gold.withOpacity(0.8) : Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String titre;
  final List<_Item> items;

  const _Section({required this.titre, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titre,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TamBourColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: TamBourColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TamBourColors.border, width: 0.5),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _Item({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: TamBourColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: TamBourColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TamBourColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            const Icon(Icons.chevron_right_rounded,
                color: TamBourColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DeconnexionBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DeconnexionBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: TamBourColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: TamBourColors.error.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: TamBourColors.error, size: 18),
            SizedBox(width: 10),
            Text(
              'Se déconnecter',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TamBourColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
