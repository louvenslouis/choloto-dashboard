import 'package:c_h_o_l_o_t_o_dashboard/settings/settings_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('settings groups session, appearance and sign out at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                AdminSettingsContent(
                  email: 'admin@choloto.com',
                  isDark: false,
                  onThemeSelected: (_) {},
                  onSignOut: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session administrateur'), findsOneWidget);
      expect(find.text('Clair'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
      expect(find.text('Déconnexion'), findsOneWidget);
      expect(find.text('Messagerie'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
