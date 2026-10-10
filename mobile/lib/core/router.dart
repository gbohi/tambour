import 'package:go_router/go_router.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/resultats/resultats_screen.dart';
import '../screens/siege/siege_screen.dart';
import '../screens/passagers/passagers_screen.dart';
import '../screens/paiement/paiement_screen.dart';
import '../screens/billet/billet_screen.dart';
import '../screens/billets/mes_billets_screen.dart';
import '../screens/compte/compte_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/gares/gares_screen.dart';
import '../screens/profil/profil_edit_screen.dart';
import '../providers/recherche_provider.dart';
import '../models/paiement.dart';
import '../models/trajet.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(
      path: '/resultats',
      builder: (_, state) => ResultatsScreen(params: state.extra as RechercheParams),
    ),
    GoRoute(
      path: '/siege',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SiegeScreen(trajet: extra['trajet'] as Trajet, params: extra['params'] as RechercheParams);
      },
    ),
    GoRoute(
      path: '/passagers',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PassagersScreen(trajet: extra['trajet'] as Trajet, params: extra['params'] as RechercheParams);
      },
    ),
    GoRoute(
      path: '/paiement',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PaiementScreen(trajet: extra['trajet'] as Trajet, params: extra['params'] as RechercheParams);
      },
    ),
    GoRoute(
      path: '/billet',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BilletScreen(trajet: extra['trajet'] as Trajet, params: extra['params'] as RechercheParams, result: extra['result'] as PaiementResult);
      },
    ),
    GoRoute(path: '/mes-billets', builder: (_, __) => const MesBilletsScreen()),
    GoRoute(path: '/compte', builder: (_, __) => const CompteScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/gares', builder: (_, __) => const GaresScreen()),
    GoRoute(path: '/profil/edit', builder: (_, __) => const ProfilEditScreen()),
  ],
);
