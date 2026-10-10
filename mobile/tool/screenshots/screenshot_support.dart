import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Utilitários das capturas de tela determinísticas.
///
/// As capturas usam as fontes reais (Poppins do projeto, Roboto e Material
/// Icons do SDK) para que a revisão visual não dependa da fonte de teste.
abstract final class ScreenshotSupport {
  static const phone = Size(390, 844);
  static const smallPhone = Size(320, 568);

  static final rootKey = GlobalKey(debugLabel: 'screenshot-root');

  static String get outputDirectory =>
      Platform.environment['ZELO_SCREENSHOTS_DIR'] ?? 'build/screenshots';

  static Future<void> loadFonts() async {
    final poppins = FontLoader('Poppins');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      poppins.addFont(
        rootBundle.load('assets/fonts/poppins/Poppins-$weight.ttf'),
      );
    }
    await poppins.load();

    final sdkFonts = _sdkMaterialFontsDirectory();
    final roboto = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      roboto.addFont(_readFont('${sdkFonts.path}/roboto-$weight.ttf'));
    }
    await roboto.load();

    final icons = FontLoader('MaterialIcons')
      ..addFont(_readFont('${sdkFonts.path}/materialicons-regular.otf'));
    await icons.load();
  }

  /// Configura uma tela de celular com barra de status e área inferior.
  static void configureView(
    WidgetTester tester, {
    Size size = phone,
    double devicePixelRatio = 3,
  }) {
    tester.view
      ..devicePixelRatio = devicePixelRatio
      ..physicalSize = size * devicePixelRatio
      ..padding = FakeViewPadding(
        top: 24 * devicePixelRatio,
        bottom: 12 * devicePixelRatio,
      )
      ..viewPadding = FakeViewPadding(
        top: 24 * devicePixelRatio,
        bottom: 12 * devicePixelRatio,
      );
    addTearDown(tester.view.reset);
  }

  static Widget frame(Widget app) => RepaintBoundary(key: rootKey, child: app);

  static Future<void> precacheBrand(WidgetTester tester) async {
    final context = rootKey.currentContext;
    if (context == null) {
      return;
    }
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/zelo-symbol.png'),
        context,
      ),
    );
    await tester.pump();
  }

  static Future<void> capture(WidgetTester tester, String name) async {
    await precacheBrand(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(rootKey),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final file = File('$outputDirectory/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
    debugPrint('captura: ${file.path}');
  }

  /// Executa [body] com sombras reais, restaurando o padrão dos testes.
  static Future<void> withShadows(Future<void> Function() body) async {
    debugDisableShadows = false;
    try {
      await body();
    } finally {
      debugDisableShadows = true;
    }
  }

  static Directory _sdkMaterialFontsDirectory() {
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable)
            .parent
            .parent
            .parent
            .parent
            .parent
            .parent
            .path;
    return Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  }

  static Future<ByteData> _readFont(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
}
