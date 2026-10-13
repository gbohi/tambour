import 'package:go_router/go_router.dart';
import 'screens/chauffeur_racine.dart';

/// Navigation de TamBour Pro : connexion puis espace chauffeur.
GoRouter creerRouteur() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const ChauffeurRacine()),
    // La déconnexion renvoie sur /auth : même écran racine, qui affiche la connexion.
    GoRoute(path: '/auth', builder: (_, __) => const ChauffeurRacine()),
  ],
);
