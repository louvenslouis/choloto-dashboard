import 'package:c_h_o_l_o_t_o_dashboard/components/mobile_sidenav_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the mobile administration header is visible and accessible',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MobileSidenavWidget(),
        ),
      ),
    );

    expect(find.text('CHOLOTO'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });
}
