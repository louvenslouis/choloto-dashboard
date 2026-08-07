import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = cHOLOTODashboardFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CHOLOTO',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('fr'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF12263F),
          primary: const Color(0xFF12263F),
          onPrimary: Colors.white,
          secondary: const Color(0xFFF6C744),
          onSecondary: const Color(0xFF12263F),
          surface: Colors.white,
          onSurface: const Color(0xFF142033),
          error: const Color(0xFFE14F5A),
          outline: const Color(0xFFCBD5E1),
          outlineVariant: const Color(0xFFE4EAF1),
        ),
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF142033),
          displayColor: const Color(0xFF142033),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        canvasColor: Colors.white,
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE4EAF1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF142033),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE4EAF1)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE4EAF1),
          thickness: 1,
          space: 1,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF12263F),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: const Color(0xFF66758A),
          textColor: const Color(0xFF142033),
          minLeadingWidth: 22,
          minTileHeight: 48,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF344156),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: Color(0xFF8C9AAD)),
          labelStyle: const TextStyle(color: Color(0xFF66758A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E1EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2878B8), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE14F5A)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE14F5A), width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8EDF3)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF5F7FA),
          selectedColor: const Color(0x29F6C744),
          disabledColor: const Color(0xFFF1F4F8),
          side: const BorderSide(color: Color(0xFFE4EAF1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF344156),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            color: const Color(0xFF12263F),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          checkmarkColor: const Color(0xFF12263F),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0x29F6C744),
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF12263F)
                    : const Color(0xFF66758A),
                size: states.contains(WidgetState.selected) ? 24 : 22,
              )),
          labelTextStyle:
              WidgetStateProperty.resolveWith((states) => GoogleFonts.inter(
                    color: states.contains(WidgetState.selected)
                        ? const Color(0xFF142033)
                        : const Color(0xFF66758A),
                    fontSize: 11,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w800
                        : FontWeight.w600,
                  )),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE4EAF1)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          modalBackgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          dragHandleColor: Color(0xFFCBD5E1),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE4EAF1)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF12263F),
          contentTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 450),
          decoration: BoxDecoration(
            color: const Color(0xFF12263F),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? const Color(0xFF8C9AAD)
                : const Color(0xFFCBD5E1),
          ),
          thumbVisibility: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered),
          ),
          radius: const Radius.circular(99),
          thickness: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? 7 : 4,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF2878B8),
          linearTrackColor: Color(0xFFE4EAF1),
          circularTrackColor: Color(0xFFE4EAF1),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF7F9FC)),
          dataRowColor: const WidgetStatePropertyAll(Colors.white),
          headingTextStyle: GoogleFonts.inter(
            color: const Color(0xFF142033),
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: GoogleFonts.inter(color: const Color(0xFF344156)),
          dividerThickness: .7,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE4EAF1)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF2878B8),
          selectionColor: Color(0x332878B8),
          selectionHandleColor: Color(0xFF2878B8),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF2F82B7),
          primary: const Color(0xFF2F82B7),
          onPrimary: Colors.white,
          secondary: const Color(0xFFFFD447),
          onSecondary: const Color(0xFF102A43),
          surface: const Color(0xFF132333),
          onSurface: const Color(0xFFF4F7FA),
          error: const Color(0xFFFF6677),
          onError: const Color(0xFF2A090D),
          outline: const Color(0xFF52677A),
          outlineVariant: const Color(0xFF2C4053),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: const Color(0xFFF4F7FA),
          displayColor: const Color(0xFFF4F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFF09131E),
        canvasColor: const Color(0xFF132333),
        cardColor: const Color(0xFF132333),
        dividerColor: const Color(0xFF2C4053),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF132333),
          foregroundColor: Color(0xFFF4F7FA),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF132333),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF26394B)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2C4053),
          thickness: 1,
          space: 1,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF10243A),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: const Color(0xFFA9B6C5),
          textColor: const Color(0xFFF4F7FA),
          minLeadingWidth: 22,
          minTileHeight: 48,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFD8E2EA),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF132333),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: Color(0xFF8293A5)),
          labelStyle: const TextStyle(color: Color(0xFFA9B6C5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2C4053)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2C4053)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFD447), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF6677)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF8793), width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF223344)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF4F7FA),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: const BorderSide(color: Color(0xFF3C4B5D)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF70B9E8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF172A3A),
          selectedColor: const Color(0x33FFD447),
          disabledColor: const Color(0xFF101D29),
          side: const BorderSide(color: Color(0xFF2C4053)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFFD8E2EA),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            color: const Color(0xFFFFD447),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          checkmarkColor: const Color(0xFFFFD447),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          backgroundColor: const Color(0xFF132333),
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0x33FFD447),
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFFFFD447)
                    : const Color(0xFFA9B6C5),
                size: states.contains(WidgetState.selected) ? 24 : 22,
              )),
          labelTextStyle:
              WidgetStateProperty.resolveWith((states) => GoogleFonts.inter(
                    color: states.contains(WidgetState.selected)
                        ? const Color(0xFFF4F7FA)
                        : const Color(0xFFA9B6C5),
                    fontSize: 11,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w800
                        : FontWeight.w600,
                  )),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF132333),
          surfaceTintColor: Colors.transparent,
          iconColor: const Color(0xFFFFD447),
          titleTextStyle: GoogleFonts.interTight(
            color: const Color(0xFFF4F7FA),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: GoogleFonts.inter(
            color: const Color(0xFFA9B6C5),
            fontSize: 14,
            height: 1.45,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF2C4053)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF132333),
          modalBackgroundColor: Color(0xFF132333),
          surfaceTintColor: Colors.transparent,
          dragHandleColor: Color(0xFF52677A),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF172A3A),
          surfaceTintColor: Colors.transparent,
          textStyle: GoogleFonts.inter(color: const Color(0xFFF4F7FA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2C4053)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A3042),
          actionTextColor: const Color(0xFFFFD447),
          closeIconColor: const Color(0xFFF4F7FA),
          contentTextStyle: GoogleFonts.inter(
            color: const Color(0xFFF4F7FA),
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF355066)),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 450),
          decoration: BoxDecoration(
            color: const Color(0xFF20384B),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            color: Color(0xFFF4F7FA),
            fontSize: 12,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFFFD447),
          linearTrackColor: Color(0xFF2C4053),
          circularTrackColor: Color(0xFF2C4053),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFF172A3A)),
          dataRowColor: const WidgetStatePropertyAll(Color(0xFF132333)),
          headingTextStyle: GoogleFonts.inter(
            color: const Color(0xFFF4F7FA),
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: GoogleFonts.inter(
            color: const Color(0xFFE4EBF1),
          ),
          dividerThickness: .7,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2C4053)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFFD447),
          selectionColor: Color(0x55FFD447),
          selectionHandleColor: Color(0xFFFFD447),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? const Color(0xFF6F8496)
                : const Color(0xFF52677A),
          ),
          trackColor: const WidgetStatePropertyAll(Color(0xFF132333)),
          thumbVisibility: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered),
          ),
          radius: const Radius.circular(99),
          thickness: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? 7 : 4,
          ),
        ),
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
