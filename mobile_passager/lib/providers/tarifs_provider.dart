import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_passager/models/tarifs.dart';
import 'package:tambour_passager/services/tarifs_service.dart';

final tarifsProvider = FutureProvider<TarifsPlateforme>((_) => TarifsService().getTarifs());

/// Tarifs connus à l'instant (valeur par défaut pendant le chargement ou hors ligne).
final tarifsActuelsProvider = Provider<TarifsPlateforme>(
  (ref) => ref.watch(tarifsProvider).valueOrNull ?? TarifsPlateforme.parDefaut);
