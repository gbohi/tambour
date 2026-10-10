import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support.dart';
import '../services/support_service.dart';

final supportServiceProvider = Provider((_) => SupportService());

final faqProvider = FutureProvider<List<CategorieFAQ>>(
  (ref) => ref.read(supportServiceProvider).getFaq());

final infosContactProvider = FutureProvider<InfosContact>(
  (ref) => ref.read(supportServiceProvider).getInfosContact());

final reclamationsProvider = FutureProvider.autoDispose<List<Reclamation>>(
  (ref) => ref.read(supportServiceProvider).getReclamations());
