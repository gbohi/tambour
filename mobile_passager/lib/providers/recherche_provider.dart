import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_passager/models/trajet.dart';
import 'package:tambour_passager/models/ville.dart';

enum TriOption { horaire, prix, duree, note }
enum FiltreClasse { tous, standard, confort, vip }

class RechercheParams {
  final Ville villeDepart;
  final Ville villeArrivee;
  final DateTime date;
  final int nbPassagers;

  const RechercheParams({
    required this.villeDepart, required this.villeArrivee,
    required this.date, required this.nbPassagers,
  });
}

class RechercheState {
  final bool isLoading;
  final List<Trajet> resultats;
  final List<Trajet> resultatsFiltres;
  final String? erreur;
  final RechercheParams? params;
  final TriOption tri;
  final FiltreClasse filtreClasse;

  const RechercheState({
    this.isLoading = false, this.resultats = const [],
    this.resultatsFiltres = const [], this.erreur, this.params,
    this.tri = TriOption.horaire, this.filtreClasse = FiltreClasse.tous,
  });

  RechercheState copyWith({bool? isLoading, List<Trajet>? resultats,
    List<Trajet>? resultatsFiltres, String? erreur, RechercheParams? params,
    TriOption? tri, FiltreClasse? filtreClasse}) =>
    RechercheState(isLoading: isLoading ?? this.isLoading,
      resultats: resultats ?? this.resultats,
      resultatsFiltres: resultatsFiltres ?? this.resultatsFiltres,
      erreur: erreur, params: params ?? this.params,
      tri: tri ?? this.tri, filtreClasse: filtreClasse ?? this.filtreClasse);
}

class RechercheNotifier extends StateNotifier<RechercheState> {
  RechercheNotifier() : super(const RechercheState());

  Future<void> rechercher(RechercheParams params) async {
    state = state.copyWith(isLoading: true, params: params);
    await Future.delayed(const Duration(milliseconds: 900));
    final trajets = Trajet.mockTrajets(params.villeDepart.id, params.villeArrivee.id);
    final filtres = _filtrerEtTrier(trajets, state.tri, state.filtreClasse);
    state = state.copyWith(isLoading: false, resultats: trajets, resultatsFiltres: filtres, erreur: null);
  }

  void changerTri(TriOption tri) {
    state = state.copyWith(tri: tri, resultatsFiltres: _filtrerEtTrier(state.resultats, tri, state.filtreClasse));
  }

  void changerFiltreClasse(FiltreClasse classe) {
    state = state.copyWith(filtreClasse: classe, resultatsFiltres: _filtrerEtTrier(state.resultats, state.tri, classe));
  }

  List<Trajet> _filtrerEtTrier(List<Trajet> trajets, TriOption tri, FiltreClasse classe) {
    var result = List<Trajet>.from(trajets);
    if (classe != FiltreClasse.tous) {
      result = result.where((t) {
        switch (classe) {
          case FiltreClasse.standard: return t.classe == ClasseBus.standard;
          case FiltreClasse.confort: return t.classe == ClasseBus.confort;
          case FiltreClasse.vip: return t.classe == ClasseBus.vip;
          case FiltreClasse.tous: return true;
        }
      }).toList();
    }
    switch (tri) {
      case TriOption.horaire: result.sort((a, b) => a.heureDepart.compareTo(b.heureDepart));
      case TriOption.prix: result.sort((a, b) => a.prixFcfa.compareTo(b.prixFcfa));
      case TriOption.duree: result.sort((a, b) => a.duree.compareTo(b.duree));
      case TriOption.note: result.sort((a, b) => b.note.compareTo(a.note));
    }
    return result;
  }
}

final rechercheProvider = StateNotifierProvider<RechercheNotifier, RechercheState>(
  (_) => RechercheNotifier());
