import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support_bot_editor_test.dart' show Repository;

class _LayoutRepository extends Repository {
  @override
  Future<SupportBotConfig> load() async => SupportBotConfig.initial;
}

void main() {
  testWidgets('preview navigates locally and follows unpublished greeting',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _LayoutRepository();
    await tester.pumpWidget(
        MaterialApp(home: SupportBotEditor(repository: repository)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bonjour !');
    await tester.pump();
    expect(find.text('Bonjour !'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('preview-vip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-vip_haiti')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('preview-vip_haiti')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-vip_mon')), findsOneWidget);
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-vip_haiti')), findsOneWidget);
    await tester.tap(find.byTooltip('Recommencer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-vip')), findsOneWidget);
    expect(find.text('Bonjour !'), findsNWidgets(2));
    expect(repository.saved, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('compact editor and nested choices fit in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: SupportBotEditor(repository: _LayoutRepository()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final branch = find.byKey(const ValueKey('vip_haiti'));
      await tester.ensureVisible(branch);
      await tester
          .tap(find.descendant(of: branch, matching: find.text('Ayiti')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('preview-vip')));
      await tester.tap(find.byKey(const ValueKey('preview-vip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('preview-vip_haiti')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
