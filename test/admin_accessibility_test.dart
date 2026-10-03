import 'package:c_h_o_l_o_t_o_dashboard/components/admin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dialog heading and close action remain accessible at 200% text',
      (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var closed = false;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdminDialogHeader(
              title: 'Modifier le paiement',
              icon: Icons.payment,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(tester.getSemantics(find.text('Modifier le paiement')),
        matchesSemantics(label: 'Modifier le paiement', isHeader: true));
    expect(tester.getSize(find.byType(IconButton)).shortestSide,
        greaterThanOrEqualTo(48));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(closed, isTrue);
    semantics.dispose();
  });
}
