import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_passager/models/fidelite.dart';
import 'package:tambour_passager/services/fidelite_service.dart';

final fideliteProvider = FutureProvider.autoDispose<FideliteInfo>(
  (_) => FideliteService().getFidelite());
