import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sidenav_model.dart';
export 'sidenav_model.dart';

class SidenavWidget extends StatefulWidget {
  const SidenavWidget({super.key, this.forceVisible = false});

  final bool forceVisible;

  @override
  State<SidenavWidget> createState() => _SidenavWidgetState();
}

class _SidenavWidgetState extends State<SidenavWidget> {
  late SidenavModel _model;
  final ScrollController _navigationScrollController = ScrollController();

  static final _operationItems = <_NavItem>[
    _NavItem('Tirages', Icons.confirmation_number_rounded,
        TiragesWidget.routeName, TiragesWidget.routePath),
    _NavItem('Publications BINGO', Icons.newspaper_rounded,
        PublicationsWidget.routeName, PublicationsWidget.routePath),
    _NavItem('Prédictions', Icons.auto_graph_rounded,
        PredictionsWidget.routeName, PredictionsWidget.routePath),
    _NavItem('Croix de la chance', Icons.brightness_7_rounded,
        CroixWidget.routeName, CroixWidget.routePath),
  ];

  static final _communityItems = <_NavItem>[
    _NavItem('Utilisateurs', Icons.people_alt_rounded, UsersWidget.routeName,
        UsersWidget.routePath),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SidenavModel());
  }

  @override
  void dispose() {
    _navigationScrollController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Se déconnecter ?',
      message: 'Votre session administrateur sera fermée sur cet appareil.',
      confirmLabel: 'Déconnecter',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    if (mounted) {
      GoRouter.of(context).clearRedirectLocation();
      context.goNamedAuth(ConnexionWidget.routeName, context.mounted);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final theme = FlutterFlowTheme.of(context);
    final inModal = ModalRoute.of(context) is PopupRoute;
    final isDesktop = MediaQuery.sizeOf(context).width >= 992;
    final showNavigation = isDesktop || inModal || widget.forceVisible;
    final canCollapse = isDesktop && !widget.forceVisible && !inModal;
    final isCollapsed = canCollapse && FFAppState().sideNavCollapsed;
    final currentRoute = getCurrentRoute(context);

    if (!showNavigation) return const SizedBox.shrink();

    final email =
        currentUserEmail.isEmpty ? 'Administrateur' : currentUserEmail;

    return Material(
      color: const Color(0xFF10243A),
      child: SafeArea(
        child: SizedBox(
          width: isCollapsed ? 84 : 264,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10243A), Color(0xFF0D1D30)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCollapsed ? 10 : 14,
                18,
                isCollapsed ? 10 : 14,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isCollapsed)
                    Column(
                      children: [
                        _CollapseButton(
                          isCollapsed: true,
                          onPressed: _toggleCollapsed,
                        ),
                        const SizedBox(height: 12),
                        const _BrandLogo(size: 40),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          const _BrandLogo(size: 44),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CHOLOTO',
                                  style: theme.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -.4,
                                  ),
                                ),
                                Text(
                                  'ESPACE ADMIN',
                                  style: theme.labelSmall.copyWith(
                                    color: theme.secondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canCollapse) ...[
                            const SizedBox(width: 4),
                            _CollapseButton(
                              isCollapsed: false,
                              onPressed: _toggleCollapsed,
                            ),
                          ],
                        ],
                      ),
                    ),
                  SizedBox(height: isCollapsed ? 20 : 28),
                  Expanded(
                    child: Scrollbar(
                      controller: _navigationScrollController,
                      child: SingleChildScrollView(
                        controller: _navigationScrollController,
                        padding: const EdgeInsets.only(right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _NavMenuGroup(
                              title: 'OPÉRATIONS',
                              items: _operationItems,
                              currentRoute: currentRoute,
                              collapsed: isCollapsed,
                              onNavigate: (route) {
                                if (inModal) Navigator.of(context).pop();
                                context.goNamed(route);
                              },
                            ),
                            const SizedBox(height: 18),
                            _NavMenuGroup(
                              title: 'COMMUNAUTÉ',
                              items: _communityItems,
                              currentRoute: currentRoute,
                              collapsed: isCollapsed,
                              onNavigate: (route) {
                                if (inModal) Navigator.of(context).pop();
                                context.goNamed(route);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (!isCollapsed) ...[
                              const _NavGroupLabel('OUTILS'),
                              const SizedBox(height: 3),
                            ],
                            _NavTile(
                              label: 'Messagerie',
                              icon: Icons.alternate_email_rounded,
                              selected: false,
                              collapsed: isCollapsed,
                              onTap: () =>
                                  launchURL('https://email.choloto.com'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .055),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .07),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: theme.secondary,
                          child: Text(
                            email.characters.first.toUpperCase(),
                            style: theme.labelLarge.copyWith(
                              color: const Color(0xFF10243A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session active',
                                  style: theme.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: .48),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NavTile(
                    label: Theme.of(context).brightness == Brightness.dark
                        ? 'Mode clair'
                        : 'Mode sombre',
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    selected: false,
                    collapsed: isCollapsed,
                    onTap: () => MyApp.of(context).setThemeMode(
                      Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                  ),
                  _NavTile(
                    label: 'Déconnexion',
                    icon: Icons.logout_rounded,
                    selected: false,
                    collapsed: isCollapsed,
                    destructive: true,
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCollapsed() {
    final appState = FFAppState();
    appState.update(() {
      appState.sideNavCollapsed = !appState.sideNavCollapsed;
    });
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          'assets/images/Logo_Choloto_509.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.isCollapsed,
    required this.onPressed,
  });

  final bool isCollapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isCollapsed ? 'Agrandir le menu' : 'Réduire le menu',
      iconSize: 19,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: .76),
        backgroundColor: Colors.white.withValues(alpha: .07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(
        isCollapsed
            ? Icons.keyboard_double_arrow_right_rounded
            : Icons.keyboard_double_arrow_left_rounded,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.routeName, this.routePath);
  final String label;
  final IconData icon;
  final String routeName;
  final String routePath;
}

class _NavGroupLabel extends StatelessWidget {
  const _NavGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Text(
        label,
        style: theme.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: .38),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.15,
        ),
      ),
    );
  }
}

class _NavMenuGroup extends StatelessWidget {
  const _NavMenuGroup({
    required this.title,
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
    required this.collapsed,
  });

  final String title;
  final List<_NavItem> items;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!collapsed) ...[
          _NavGroupLabel(title),
          const SizedBox(height: 7),
        ],
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _NavTile(
              label: item.label,
              icon: item.icon,
              selected: currentRoute == item.routePath ||
                  currentRoute.startsWith('${item.routePath}/') ||
                  (currentRoute == '/' &&
                      item.routeName == UsersWidget.routeName),
              collapsed: collapsed,
              onTap: () => onNavigate(item.routeName),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.collapsed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final foreground = destructive
        ? const Color(0xFFFF8A92)
        : selected
            ? Colors.white
            : Colors.white.withValues(alpha: .67);

    final tile = Semantics(
      selected: selected,
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .105)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: .08)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 8 : 10,
              vertical: 9,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 3,
                  height: selected ? 20 : 0,
                  margin: EdgeInsets.only(right: collapsed ? 7 : 9),
                  decoration: BoxDecoration(
                    color: selected ? theme.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Icon(
                  icon,
                  size: 19,
                  color: selected ? theme.secondary : foreground,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!collapsed) return tile;
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 350),
      child: tile,
    );
  }
}
