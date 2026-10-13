import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_passager/models/ligne_populaire.dart';
import 'package:tambour_passager/services/ligne_service.dart';

final lignesPopulairesProvider = FutureProvider<List<LignePopulaire>>(
  (_) => LigneService().getLignesPopulaires());
