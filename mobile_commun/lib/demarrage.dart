import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'core/variante.dart';

/// Démarrage commun aux deux applications (TamBour et TamBour Pro).
Future<void> lancerTamBour(Variante variante, GoRouter Function() routeur) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppVariante.courante = variante;
  await initializeDateFormatting('fr_FR', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(ProviderScope(child: TamBourApp(router: routeur())));
}

class TamBourApp extends StatelessWidget {
  final GoRouter router;
  const TamBourApp({super.key, required this.router});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppVariante.nom,
      debugShowCheckedModeBanner: false,
      theme: TamBourTheme.light,
      routerConfig: router,
      // Interface en français : calendriers, sélecteurs d'heure, boutons des boîtes de dialogue…
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
