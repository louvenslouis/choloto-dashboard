import 'dart:io';
import 'dart:convert';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;

import 'dart:ui' as ui;
import 'package:c_h_o_l_o_t_o_dashboard/predictions/predictions_widget.dart';
import 'package:firebase_core/firebase_core.dart';
// Test transport only; this never connects to a Firebase project.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mobile_admin_layout_test.dart' show app, phone;

class _LocalFontManifest extends Fake implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['Inter', 'InterTight'])
          for (final weight in [
            'Regular',
            'Medium',
            'SemiBold',
            'Bold',
            'ExtraBold'
          ])
            '$family-$weight.ttf',
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.logEvent',
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    fonts.assetManifest = _LocalFontManifest();
    final fallback = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final assetManifest = await rootBundle.load('AssetManifest.bin');
    final materialIcons =
        await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    final logo = await rootBundle.load('assets/images/Logo_Choloto_509.png');
    final inter = const bool.fromEnvironment('CAPTURE_MOBILE_UI')
        ? ByteData.sublistView(
            await File('/tmp/choloto-inter.ttf').readAsBytes())
        : fallback;
    final tight = const bool.fromEnvironment('CAPTURE_MOBILE_UI')
        ? ByteData.sublistView(
            await File('/tmp/choloto-inter-tight.ttf').readAsBytes())
        : fallback;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final path = utf8.decode(message!.buffer.asUint8List());
        if (path == 'AssetManifest.bin') return assetManifest;
        if (path.endsWith('.ttf')) {
          return path.startsWith('InterTight') ? tight : inter;
        }
        if (path.endsWith('MaterialIcons-Regular.otf')) return materialIcons;
        if (path.endsWith('Logo_Choloto_509.png')) return logo;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.cloud_firestore_platform_interface.FirebaseFirestoreHostApi.documentReferenceSet',
      (_) async => const StandardMessageCodec()
          .encodeMessage(['unavailable', 'Simulated offline write', null]),
    );
    if (const bool.fromEnvironment('CAPTURE_MOBILE_UI')) {
      for (final entry in {
        'Inter': '/tmp/choloto-inter.ttf',
        'InterTight': '/tmp/choloto-inter-tight.ttf',
      }.entries) {
        final bytes =
            ByteData.sublistView(await File(entry.value).readAsBytes());
        for (final suffix in ['', '_regular', '_500', '_600', '_700', '_800']) {
          await (FontLoader('${entry.key}$suffix')
                ..addFont(Future.value(bytes)))
              .load();
        }
      }
      await (FontLoader('MaterialIcons')..addFont(Future.value(materialIcons)))
          .load();
    }
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
        'prediction form scrolls and preserves input after failure at $width',
        (tester) async {
      phone(tester, width);
      await tester.pumpWidget(app(
        const RepaintBoundary(
            key: ValueKey('capture-mobile'), child: PredictionsWidget()),
        theme: ThemeData(
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF12263F)),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          )),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
          find.text('Prédictions'), findsNWidgets(3)); // title, tab, navigation
      expect(find.byType(TextFormField), findsNWidgets(28));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matin').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '12');
      final save = find.widgetWithText(FilledButton, 'Publier les prédictions');
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(524));
      expect(find.text('12'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      if (const bool.fromEnvironment('CAPTURE_MOBILE_UI')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture-mobile')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/choloto-mobile-predictions-${width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      // The mock transport rejects persistence; the form must retain the draft.
      await tester.tap(save);
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
      expect(find.text('Publication impossible. Veuillez réessayer.'),
          findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
}
