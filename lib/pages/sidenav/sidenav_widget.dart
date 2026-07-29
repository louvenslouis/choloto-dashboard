import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
import 'package:flutter/material.dart';
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

  static final _pilotageItems = <_NavItem>[
    _NavItem('Vue d’ensemble', Icons.grid_view_rounded,
        DashboardWidget.routeName, DashboardWidget.routePath),
  ];

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
    _NavItem('Chaîne YouTube', Icons.play_circle_fill_rounded,
        YoutubeWidget.routeName, YoutubeWidget.routePath),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SidenavModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Se déconnecter ?'),
            content: const Text(
              'Votre session administrateur sera fermée sur cet appareil.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Déconnecter'),
              ),
            ],
          ),
        ) ??
        false;
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
    final theme = FlutterFlowTheme.of(context);
    final inModal = ModalRoute.of(context) is PopupRoute;
    final showNavigation = MediaQuery.sizeOf(context).width >= 992 ||
        inModal ||
        widget.forceVisible;
    final currentRoute = getCurrentRoute(context);

    if (!showNavigation) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF102A43),
      child: SafeArea(
        child: SizedBox(
          width: 288,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/Logo_Choloto_509.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHOLOTO',
                                style: theme.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -.4,
                                ),
                              ),
                              Text(
                                'Espace administration',
                                style: theme.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: .58),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'NAVIGATION',
                      style: theme.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: .42),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _NavMenuGroup(
                          title: 'PILOTAGE',
                          items: _pilotageItems,
                          currentRoute: currentRoute,
                          onNavigate: (route) {
                            if (inModal) Navigator.of(context).pop();
                            context.goNamed(route);
                          },
                        ),
                        const SizedBox(height: 18),
                        _NavMenuGroup(
                          title: 'OPÉRATIONS',
                          items: _operationItems,
                          currentRoute: currentRoute,
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
                          onNavigate: (route) {
                            if (inModal) Navigator.of(context).pop();
                            context.goNamed(route);
                          },
                        ),
                        const SizedBox(height: 18),
                        const _NavGroupLabel('OUTILS'),
                        const SizedBox(height: 5),
                        _NavTile(
                          label: 'Messagerie',
                          icon: Icons.alternate_email_rounded,
                          selected: false,
                          onTap: () => launchURL('https://email.choloto.com'),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: .10)),
                  const SizedBox(height: 4),
                  _NavTile(
                    label: Theme.of(context).brightness == Brightness.dark
                        ? 'Mode clair'
                        : 'Mode sombre',
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    selected: false,
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
      padding: const EdgeInsets.only(left: 13),
      child: Text(
        label,
        style: theme.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: .36),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
  });

  final String title;
  final List<_NavItem> items;
  final String currentRoute;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NavGroupLabel(title),
        const SizedBox(height: 5),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _NavTile(
              label: item.label,
              icon: item.icon,
              selected: currentRoute == item.routePath ||
                  (currentRoute == '/' &&
                      item.routeName == UsersWidget.routeName),
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
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final foreground = destructive
        ? const Color(0xFFFF8A92)
        : selected
            ? const Color(0xFF102A43)
            : Colors.white.withValues(alpha: .68);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? theme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 4 : 0,
                  height: 22,
                  margin: EdgeInsets.only(right: selected ? 10 : 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Icon(icon, size: 21, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
