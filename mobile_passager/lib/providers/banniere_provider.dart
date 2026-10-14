import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tambour_passager/models/banniere.dart';
import 'package:tambour_passager/services/banniere_service.dart';

final bannieresProvider = FutureProvider<List<Banniere>>((_) => BanniereService().getBannieres());
