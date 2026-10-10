import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paiement.dart';

class PaiementState {
  final MethodePaiement? methodeSelectionnee;
  final String telephone;
  final StatutPaiement statut;
  final PaiementResult? result;
  final String? erreur;
  final int secondesRestantes;

  const PaiementState({this.methodeSelectionnee, this.telephone = '',
    this.statut = StatutPaiement.attente, this.result, this.erreur,
    this.secondesRestantes = 120});

  PaiementState copyWith({MethodePaiement? methodeSelectionnee, String? telephone,
    StatutPaiement? statut, PaiementResult? result, String? erreur, int? secondesRestantes}) =>
    PaiementState(
      methodeSelectionnee: methodeSelectionnee ?? this.methodeSelectionnee,
      telephone: telephone ?? this.telephone,
      statut: statut ?? this.statut,
      result: result ?? this.result,
      erreur: erreur,
      secondesRestantes: secondesRestantes ?? this.secondesRestantes,
    );

  bool get peutPayer => methodeSelectionnee != null && telephone.length >= 10;
}

class PaiementNotifier extends StateNotifier<PaiementState> {
  PaiementNotifier() : super(const PaiementState());

  void selectionnerMethode(MethodePaiement m) => state = state.copyWith(methodeSelectionnee: m);
  void setTelephone(String t) => state = state.copyWith(telephone: t);

  Future<void> initierPaiement(PaiementRequest request) async {
    state = state.copyWith(statut: StatutPaiement.enCours, erreur: null, secondesRestantes: 120);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      statut: StatutPaiement.succes,
      result: PaiementResult(
        referenceTransaction: _genRef(),
        statut: StatutPaiement.succes,
        timestamp: DateTime.now(),
        montantFcfa: request.montantFcfa,
        methode: request.methode,
      ),
    );
  }

  void tickTimer() {
    if (state.secondesRestantes > 0) {
      state = state.copyWith(secondesRestantes: state.secondesRestantes - 1);
    } else {
      state = state.copyWith(statut: StatutPaiement.expire);
    }
  }

  void reinitialiser() => state = const PaiementState();

  String _genRef() {
    final now = DateTime.now();
    final rnd = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'TB${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}$rnd';
  }
}

final paiementProvider = StateNotifierProvider<PaiementNotifier, PaiementState>(
  (_) => PaiementNotifier());
