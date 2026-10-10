import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fidelite.dart';
import '../services/fidelite_service.dart';

final fideliteProvider = FutureProvider.autoDispose<FideliteInfo>(
  (_) => FideliteService().getFidelite());
