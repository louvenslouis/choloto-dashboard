import 'package:c_h_o_l_o_t_o_dashboard/components/admin_ui.dart';
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

  testWidgets('the shared mobile app bar exposes its page and status',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AdminMobileAppBar(title: 'Tirages'),
          drawer: Drawer(child: Text('Navigation')),
        ),
      ),
    );

    expect(find.text('Tirages'), findsOneWidget);
    expect(find.text('Administration CHOLOTO'), findsOneWidget);
    expect(find.text('En ligne'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
  });

  testWidgets('section headings provide context before page controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSectionHeader(
            title: 'Utilisateurs',
            description: 'Gérez les membres de la communauté.',
            icon: Icons.people_alt_rounded,
          ),
        ),
      ),
    );

    expect(find.text('ESPACE DE GESTION'), findsOneWidget);
    expect(find.text('Utilisateurs'), findsOneWidget);
    expect(find.text('Gérez les membres de la communauté.'), findsOneWidget);
  });
}
