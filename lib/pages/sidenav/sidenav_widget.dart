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

  static final _items = <_NavItem>[
    _NavItem('Dashboard', Icons.grid_view_rounded, DashboardWidget.routeName),
    _NavItem('Utilisateurs', Icons.people_alt_rounded, UsersWidget.routeName),
    _NavItem(
        'Tirages', Icons.confirmation_number_rounded, TiragesWidget.routeName),
    _NavItem('Publications BINGO', Icons.newspaper_rounded,
        PublicationsWidget.routeName),
    _NavItem(
        'Prédictions', Icons.auto_graph_rounded, PredictionsWidget.routeName),
    _NavItem('Croix de la chance', Icons.brightness_7_rounded,
        CroixWidget.routeName),
    _NavItem('Chaîne YouTube', Icons.play_circle_fill_rounded,
        YoutubeWidget.routeName),
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
      color: theme.secondaryBackground,
      child: SafeArea(
        child: SizedBox(
          width: 280,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: theme.alternate.withValues(alpha: .7)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                                  letterSpacing: -.4,
                                ),
                              ),
                              Text(
                                'Espace administration',
                                style: theme.labelSmall.copyWith(
                                  color: theme.secondaryText,
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
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return _NavTile(
                            label: 'Messagerie',
                            icon: Icons.alternate_email_rounded,
                            selected: false,
                            onTap: () => launchURL('https://email.choloto.com'),
                          );
                        }
                        final item = _items[index];
                        return _NavTile(
                          label: item.label,
                          icon: item.icon,
                          selected: currentRoute == item.route,
                          onTap: () {
                            if (inModal) Navigator.of(context).pop();
                            context.goNamed(item.route);
                          },
                        );
                      },
                    ),
                  ),
                  Divider(color: theme.alternate),
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
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
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
        ? theme.error
        : selected
            ? theme.primary
            : theme.secondaryText;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? theme.accent1 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
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
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
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
