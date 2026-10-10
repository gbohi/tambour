import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/siege.dart';
import '../models/trajet.dart';

class SiegeState {
  final List<Siege> sieges;
  final List<String> selection;
  final int nbRequis;
  final bool isLoading;

  const SiegeState({this.sieges = const [], this.selection = const [], this.nbRequis = 1, this.isLoading = false});

  SiegeState copyWith({List<Siege>? sieges, List<String>? selection, int? nbRequis, bool? isLoading}) =>
    SiegeState(sieges: sieges ?? this.sieges, selection: selection ?? this.selection,
      nbRequis: nbRequis ?? this.nbRequis, isLoading: isLoading ?? this.isLoading);

  bool get selectionComplete => selection.length == nbRequis;
  List<Siege> get siegesSelectionnes => sieges.where((s) => selection.contains(s.id)).toList();
}

class SiegeNotifier extends StateNotifier<SiegeState> {
  SiegeNotifier() : super(const SiegeState());

  Future<void> charger(Trajet trajet, int nbPassagers) async {
    state = state.copyWith(isLoading: true, nbRequis: nbPassagers);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isLoading: false,
      sieges: Siege.genererBus54Places(siegesOccupes: Siege.mockOccupes()),
      selection: [],
    );
  }

  void toggleSiege(String siegeId) {
    final siege = state.sieges.firstWhere((s) => s.id == siegeId);
    if (!siege.estSelectionnable) return;
    final sel = List<String>.from(state.selection);
    if (sel.contains(siegeId)) {
      sel.remove(siegeId);
    } else {
      if (sel.length >= state.nbRequis) sel.removeAt(0);
      sel.add(siegeId);
    }
    final siegesMaj = state.sieges.map((s) {
      if (s.id == siegeId) return s.copyWith(statut: sel.contains(siegeId) ? StatutSiege.selectionne : StatutSiege.libre);
      if (state.selection.contains(s.id) && !sel.contains(s.id)) return s.copyWith(statut: StatutSiege.libre);
      return s;
    }).toList();
    state = state.copyWith(sieges: siegesMaj, selection: sel);
  }

  void reinitialiser() {
    state = state.copyWith(
      sieges: state.sieges.map((s) => s.statut == StatutSiege.selectionne
        ? s.copyWith(statut: StatutSiege.libre) : s).toList(),
      selection: [],
    );
  }
}

final siegeProvider = StateNotifierProvider<SiegeNotifier, SiegeState>((_) => SiegeNotifier());
