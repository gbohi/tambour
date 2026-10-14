// Banc de test partagé par les deux applications : rend chaque écran à plusieurs tailles
// de téléphone et échoue si un widget déborde (« A RenderFlex overflowed by N pixels »).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class Config {
  final Size taille;
  final double texte;    // facteur de taille du texte (réglage d'accessibilité du téléphone)
  final double clavier;  // hauteur du clavier ouvert
  const Config(this.taille, {this.texte = 1, this.clavier = 0});
}

const tailles = <String, Config>{
  'petit 320x568': Config(Size(320, 568)),
  'moyen 360x640': Config(Size(360, 640)),
  'grand 393x852': Config(Size(393, 852)),
  'texte agrandi 1.3 360x640': Config(Size(360, 640), texte: 1.3),
  'clavier ouvert 360x640': Config(Size(360, 640), clavier: 290),
};

typedef CasEcran = (Widget Function(), Future<void> Function(WidgetTester)?);

Future<void> chargerPolices() async {
  final dossier = '${Platform.environment['FLUTTER_ROOT'] ?? '/home/user/sdk/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  // Roboto a des métriques proches d'Outfit (police de l'application)
  for (final famille in ['Outfit', 'Roboto']) {
    final loader = FontLoader(famille);
    for (final f in ['Regular', 'Medium', 'Bold', 'Black', 'Light']) {
      loader.addFont(Future.value(ByteData.sublistView(File('$dossier/Roboto-$f.ttf').readAsBytesSync())));
    }
    await loader.load();
  }
  final icones = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$dossier/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icones.load();
}

/// Déclare un test par écran et par taille.
void testerDebordements(Map<String, CasEcran> cas, {List<Override> overrides = const [], Future<void> Function()? nettoyer}) {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
    await chargerPolices();
  });
  for (final ecran in cas.entries) {
    for (final taille in tailles.entries) {
      testWidgets('${ecran.key} — ${taille.key}', (tester) async {
        final debordements = <String>[];
        final ancien = FlutterError.onError;
        addTearDown(() => FlutterError.onError = ancien);
        FlutterError.onError = (details) {
          final texte = details.toString();
          if (texte.contains('overflowed')) {
            final source = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(texte)?.group(0) ?? '?';
            debordements.add('${details.exceptionAsString().split('\n').first} ← $source');
          } else if (!texte.contains('tile.openstreetmap.org')) {
            ancien?.call(details);  // autres erreurs : signalées normalement
          }
        };
        final c = taille.value;
        tester.view.physicalSize = c.taille * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.viewInsets = FakeViewPadding(bottom: c.clavier * 3);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Outfit', useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4A3B))),
            // Comme l'application : interface en français (calendrier…)
            locale: const Locale('fr', 'FR'),
            supportedLocales: const [Locale('fr', 'FR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.texte)),
              child: child!),
            home: ecran.value.$1()),
        ));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        final action = ecran.value.$2;
        if (action != null) {
          await action(tester);
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
        }
        await tester.pumpWidget(const SizedBox());
        if (nettoyer != null) await nettoyer();
        await tester.pump(const Duration(seconds: 5));
        FlutterError.onError = ancien;
        expect(debordements, isEmpty, reason: debordements.toSet().join('\n'));
      });
    }
  }
}
