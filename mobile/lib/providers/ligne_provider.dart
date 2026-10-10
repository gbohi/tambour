import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ligne_populaire.dart';
import '../services/ligne_service.dart';

final lignesPopulairesProvider = FutureProvider<List<LignePopulaire>>(
  (_) => LigneService().getLignesPopulaires());
