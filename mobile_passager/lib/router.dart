import 'package:go_router/go_router.dart';
import 'package:tambour_passager/screens/auth/auth_screen.dart';
import 'package:tambour_passager/screens/home/home_screen.dart';
import 'package:tambour_passager/screens/resultats/resultats_screen.dart';
import 'package:tambour_passager/screens/passagers/passagers_screen.dart';
import 'package:tambour_passager/screens/paiement/paiement_screen.dart';
import 'package:tambour_passager/screens/billet/billet_screen.dart';
import 'package:tambour_passager/screens/billets/mes_billets_screen.dart';
import 'package:tambour_passager/screens/compte/compte_screen.dart';
import 'package:tambour_passager/screens/notifications/notifications_screen.dart';
import 'package:tambour_passager/screens/gares/gares_screen.dart';
import 'package:tambour_passager/screens/profil/profil_edit_screen.dart';
import 'package:tambour_passager/screens/lignes/lignes_populaires_screen.dart';
import 'package:tambour_passager/screens/fidelite/fidelite_screen.dart';
import 'package:tambour_passager/screens/support/centre_aide_screen.dart';
import 'package:tambour_passager/screens/support/contact_support_screen.dart';
import 'package:tambour_passager/screens/support/noter_app_screen.dart';
import 'package:tambour_passager/screens/support/reclamations_screen.dart';
import 'package:tambour_passager/providers/recherche_provider.dart';
import 'package:tambour_passager/models/paiement.dart';
import 'package:tambour_passager/models/trajet.dart';

/// Navigation de l'application voyageurs « TamBour ».
GoRouter creerRouteur() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(
      path: '/resultats',
      builder: (_, state) => ResultatsScreen(params: state.extra as RechercheParams),
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
    GoRoute(path: '/lignes-populaires', builder: (_, __) => const LignesPopulairesScreen()),
    GoRoute(path: '/fidelite', builder: (_, __) => const FideliteScreen()),
    GoRoute(path: '/aide', builder: (_, __) => const CentreAideScreen()),
    GoRoute(path: '/support', builder: (_, __) => const ContactSupportScreen()),
    GoRoute(path: '/noter', builder: (_, __) => const NoterAppScreen()),
    GoRoute(path: '/reclamations', builder: (_, __) => const ReclamationsScreen()),
  ],
);
