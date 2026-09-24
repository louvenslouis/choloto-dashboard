import 'package:c_h_o_l_o_t_o_dashboard/components/admin_ui.dart';
import 'package:c_h_o_l_o_t_o_dashboard/components/paiement_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/flutter_flow/internationalization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {double scale = 1, ThemeData? theme}) => MaterialApp(
      theme: theme,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void phone(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets('mobile tasks and member actions fit $width at scale $scale',
          (tester) async {
        phone(tester, width);
        var opened = false;
        var payment = false;
        await tester.pumpWidget(app(
          Scaffold(
            appBar: const AdminMobileAppBar(title: 'Membres'),
            bottomNavigationBar: AdminMobileBottomBar(
              activeDestination: AdminMobileDestination.users,
              onOpenMenu: () {},
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AdminTaskList(children: [
                  for (final title in [
                    'Paiements à traiter',
                    'Service client',
                    'Activité BINGO'
                  ])
                    ListTile(title: Text(title), onTap: () {}),
                ]),
                AdminMemberRow(
                  name: 'Marie Jean-Baptiste Louis',
                  status: 'VIP',
                  deadline: '30 sept. 2026',
                  active: true,
                  avatar: const CircleAvatar(child: Text('M')),
                  onOpen: () => opened = true,
                  onPayment: () => payment = true,
                ),
              ],
            ),
          ),
          scale: scale,
        ));
        await tester.pumpAndSettle();
        for (final title in [
          'Paiements à traiter',
          'Service client',
          'Activité BINGO'
        ]) {
          expect(find.text(title).hitTestable(), findsOneWidget);
        }
        expect(tester.getTopLeft(find.text('Paiements à traiter')).dx,
            tester.getTopLeft(find.text('Activité BINGO')).dx);
        expect(tester.getSize(find.byTooltip('Paiement')).shortestSide,
            greaterThanOrEqualTo(48));
        await tester.tap(find.byTooltip('Paiement'));
        expect(payment, isTrue);
        expect(opened, isFalse);
        await tester.tap(find.text('Marie Jean-Baptiste Louis'));
        expect(opened, isTrue);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'payment action stays above the keyboard at $width scale $scale',
          (tester) async {
        phone(tester, width);
        await tester.pumpWidget(app(
          const Scaffold(
              body: AdminDialogFrame(
            maxWidth: 760,
            fullscreenOnMobile: true,
            scrollable: false,
            child: PaiementWidget(refUser: null),
          )),
          scale: scale,
        ));
        await tester.pumpAndSettle();
        final amount = find.widgetWithText(TextField, 'Montant (optionnel)');
        await tester.enterText(amount, '1500');
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        final save =
            find.widgetWithText(FilledButton, 'Enregistrer et générer le reçu');
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(524));
        expect(find.text('1500'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('long edit forms keep the footer pinned while content scrolls',
      (tester) async {
    phone(tester, 360);
    var saved = false;
    await tester.pumpWidget(app(
      Scaffold(
          body: AdminDialogFrame(
        fullscreenOnMobile: true,
        footer: FilledButton(
          onPressed: () => saved = true,
          child: const Text('Enregistrer'),
        ),
        child: Column(children: [
          for (var i = 0; i < 20; i++)
            Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'Valeur $i'),
                )),
        ]),
      )),
    ));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Enregistrer');
    final initialPosition = tester.getTopLeft(save);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(save), initialPosition);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(524));
    await tester.tap(save);
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
  });
}
