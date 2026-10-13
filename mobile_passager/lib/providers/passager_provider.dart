import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_passager/models/passager.dart';

class PassagerState {
  final List<Passager> passagers;
  final int indexActif;
  final String emailPayeur;

  const PassagerState({
    this.passagers = const [],
    this.indexActif = 0,
    this.emailPayeur = '',
  });

  PassagerState copyWith({List<Passager>? passagers, int? indexActif, String? emailPayeur}) =>
    PassagerState(
      passagers:   passagers   ?? this.passagers,
      indexActif:  indexActif  ?? this.indexActif,
      emailPayeur: emailPayeur ?? this.emailPayeur,
    );
}

class PassagerNotifier extends StateNotifier<PassagerState> {
  PassagerNotifier() : super(const PassagerState());

  void initialiser(List<String> siegeIds) {
    state = PassagerState(
      passagers: siegeIds.map((id) => Passager(
        prenom: '', nom: '', telephone: '', email: '', siegeId: id,
      )).toList());
  }

  void mettreAJour(int index, Passager passager) {
    final liste = List<Passager>.from(state.passagers);
    liste[index] = passager;
    state = state.copyWith(passagers: liste);
  }

  void setEmailPayeur(String email) => state = state.copyWith(emailPayeur: email);
  void setIndexActif(int index)     => state = state.copyWith(indexActif: index);
}

final passagerProvider =
  StateNotifierProvider<PassagerNotifier, PassagerState>((_) => PassagerNotifier());
