import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatut { initial, chargement, connecte, deconnecte, erreur }

class AuthState {
  final AuthStatut statut;
  final UserModel? user;
  final String? erreur;

  const AuthState({this.statut = AuthStatut.initial, this.user, this.erreur});

  AuthState copyWith({AuthStatut? statut, UserModel? user, String? erreur}) =>
    AuthState(statut: statut ?? this.statut, user: user ?? this.user, erreur: erreur);

  bool get estConnecte => statut == AuthStatut.connecte;
  bool get estChargement => statut == AuthStatut.chargement;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) { _verifierSession(); }

  Future<void> _verifierSession() async {
    state = state.copyWith(statut: AuthStatut.chargement);
    try {
      if (await _service.estConnecte) {
        final user = await _service.getProfile();
        state = state.copyWith(statut: AuthStatut.connecte, user: user);
      } else {
        state = state.copyWith(statut: AuthStatut.deconnecte);
      }
    } catch (_) {
      state = state.copyWith(statut: AuthStatut.deconnecte);
    }
  }

  Future<bool> login({required String email, required String motDePasse}) async {
    state = state.copyWith(statut: AuthStatut.chargement, erreur: null);
    try {
      await _service.login(email: email, motDePasse: motDePasse);
      final user = await _service.getProfile();
      state = state.copyWith(statut: AuthStatut.connecte, user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(statut: AuthStatut.erreur, erreur: e.message);
      return false;
    }
  }

  Future<bool> inscrire({required String prenom, required String nom,
    required String email, required String telephone, required String motDePasse}) async {
    state = state.copyWith(statut: AuthStatut.chargement, erreur: null);
    try {
      await _service.inscrire(prenom: prenom, nom: nom, email: email,
        telephone: telephone, motDePasse: motDePasse);
      final user = await _service.getProfile();
      state = state.copyWith(statut: AuthStatut.connecte, user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(statut: AuthStatut.erreur, erreur: e.message);
      return false;
    }
  }

  Future<bool> mettreAJourProfil(Map<String, dynamic> data) async {
    state = state.copyWith(statut: AuthStatut.chargement, erreur: null);
    try {
      final user = await _service.mettreAJourProfil(data);
      state = state.copyWith(statut: AuthStatut.connecte, user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(statut: AuthStatut.erreur, erreur: e.message);
      return false;
    }
  }

  Future<void> deconnecter() async {
    await _service.deconnecter();
    state = const AuthState(statut: AuthStatut.deconnecte);
  }
}

final authServiceProvider = Provider((_) => AuthService());
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)));
