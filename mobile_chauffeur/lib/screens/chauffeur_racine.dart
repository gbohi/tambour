import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_commun/core/theme.dart';
import 'package:tambour_commun/providers/auth_provider.dart';
import 'package:tambour_chauffeur/screens/chauffeur_accueil_screen.dart';
import 'package:tambour_chauffeur/screens/connexion_chauffeur_screen.dart';

/// Racine de TamBour Pro : écran de connexion tant qu'aucun chauffeur n'est connecté.
class ChauffeurRacine extends ConsumerWidget {
  const ChauffeurRacine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.estConnecte) return const ChauffeurAccueilScreen();
    if (auth.statut == AuthStatut.initial) {
      return const Scaffold(backgroundColor: TamBourColors.marque,
        body: Center(child: CircularProgressIndicator(color: TamBourColors.gold)));
    }
    return const ConnexionChauffeurScreen();
  }
}
