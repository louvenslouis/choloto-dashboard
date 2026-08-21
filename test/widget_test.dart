import 'package:c_h_o_l_o_t_o_dashboard/components/admin_ui.dart';
import 'package:c_h_o_l_o_t_o_dashboard/components/mobile_sidenav_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/components/paiement_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/components/prediction_card_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/components/user_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/backend/schema/enums/enums.dart';
import 'package:c_h_o_l_o_t_o_dashboard/flutter_flow/internationalization.dart';
import 'package:c_h_o_l_o_t_o_dashboard/users/users_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the mobile administration header is visible and accessible',
      (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MobileSidenavWidget(),
        ),
      ),
    );

    expect(find.text('CHOLOTO'), findsOneWidget);
    expect(find.text('ESPACE ADMIN'), findsOneWidget);
    expect(find.text('En ligne'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('En ligne'), findsOneWidget);
    expect(find.byTooltip('Ouvrir le menu'), findsOneWidget);
  });

  testWidgets('the compact app bar fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AdminMobileAppBar(title: 'Publications BINGO'),
          drawer: Drawer(child: Text('Navigation')),
        ),
      ),
    );

    expect(find.text('Publications BINGO'), findsOneWidget);
    expect(find.text('En ligne'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mobile navigation exposes frequent destinations and menu',
      (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Drawer(child: Text('Navigation complète')),
          bottomNavigationBar: AdminMobileBottomBar(
            activeDestination: AdminMobileDestination.dashboard,
            onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
          ),
        ),
      ),
    );

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Tirages'), findsOneWidget);
    expect(find.text('Prévisions'), findsOneWidget);
    expect(find.text('Membres'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Navigation complète'), findsOneWidget);
  });

  testWidgets('section headings provide context before page controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSectionHeader(
            title: 'Utilisateurs',
            icon: Icons.people_alt_rounded,
          ),
        ),
      ),
    );

    expect(find.text('ESPACE DE GESTION'), findsOneWidget);
    expect(find.text('Utilisateurs'), findsOneWidget);
  });

  testWidgets('user sorting switches between alphabetical and recent changes',
      (tester) async {
    var selectedMode = UserSortMode.alphabetical;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Center(
              child: UserSortControl(
                value: selectedMode,
                onChanged: (mode) => setState(() => selectedMode = mode),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Alphabétique'), findsOneWidget);
    await tester.tap(find.byType(UserSortControl));
    await tester.pumpAndSettle();

    expect(find.text('Ordre alphabétique'), findsOneWidget);
    expect(find.text('Dernière modification'), findsOneWidget);

    await tester.tap(find.text('Dernière modification'));
    await tester.pumpAndSettle();

    expect(selectedMode, UserSortMode.lastModified);
    expect(find.text('Modifiés récemment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prediction cards reorganize inputs on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PredictionCardWidget(parameter1: Predictions.boulFavoris),
        ),
      ),
    );

    expect(find.text('Boules favorites'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('administration dialogs remain usable on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AdminDialogFrame(
                  child: UserWidget(infos: null),
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Profil du membre'), findsOneWidget);
    expect(find.text('ABONNEMENT INACTIF'), findsOneWidget);
    expect(find.byTooltip('Fermer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the payment dialog fits a narrow phone without scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: [Locale('fr')],
        localizationsDelegates: [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: AdminDialogFrame(
            maxWidth: 760,
            scrollable: false,
            child: PaiementWidget(refUser: null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abonnement VIP'), findsOneWidget);
    expect(find.text('Méthode de paiement (optionnelle)'), findsOneWidget);
    expect(find.text('Montant (optionnel)'), findsOneWidget);
    expect(find.text('GDS'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<String>>(
            find.byType(SegmentedButton<String>),
          )
          .selected,
      {'GDS'},
    );

    await tester.tap(find.text('USD'));
    await tester.pump();

    expect(
      tester
          .widget<SegmentedButton<String>>(
            find.byType(SegmentedButton<String>),
          )
          .selected,
      {'USD'},
    );
    expect(find.text('Enregistrer et générer le reçu'), findsOneWidget);
    expect(
      find.text('La transaction sera archivée et son reçu PDF téléchargé.'),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation dialogs use clear mobile actions', (tester) async {
    tester.view.physicalSize = const Size(340, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminConfirmDialog(
            title: 'Supprimer ?',
            message: 'Cette action est définitive.',
            confirmLabel: 'Supprimer',
            cancelLabel: 'Annuler',
            icon: Icons.delete_outline_rounded,
            destructive: true,
          ),
        ),
      ),
    );

    expect(find.text('Supprimer'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
