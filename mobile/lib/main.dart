import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(const ProviderScope(child: TamBourApp()));
}

class TamBourApp extends StatelessWidget {
  const TamBourApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TamBour',
      debugShowCheckedModeBanner: false,
      theme: TamBourTheme.light,
      routerConfig: appRouter,
    );
  }
}
