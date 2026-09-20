import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  static const String routeName = 'settings';
  static const String routePath = '/settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
    if (!mounted) return;

    GoRouter.of(context).clearRedirectLocation();
    context.goNamedAuth(ConnexionWidget.routeName, context.mounted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 992;
    final email =
        currentUserEmail.isEmpty ? 'Administrateur' : currentUserEmail;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: compact ? const AdminMobileAppBar(title: 'Paramètres') : null,
      drawer: compact
          ? const Drawer(
              width: 264,
              child: SidenavWidget(forceVisible: true),
            )
          : null,
      bottomNavigationBar: compact
          ? AdminMobileBottomBar(
              activeDestination: AdminMobileDestination.more,
              onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SidenavWidget(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                    children: [
                      AdminSettingsContent(
                        email: email,
                        isDark: isDark,
                        onThemeSelected: (mode) {
                          MyApp.of(context).setThemeMode(mode);
                        },
                        onSignOut: _signOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSettingsContent extends StatelessWidget {
  const AdminSettingsContent({
    super.key,
    required this.email,
    required this.isDark,
    required this.onThemeSelected,
    required this.onSignOut,
  });

  final String email;
  final bool isDark;
  final ValueChanged<ThemeMode> onThemeSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      children: [
        const AdminSectionHeader(
          title: 'Paramètres',
          icon: Icons.settings_rounded,
        ),
        _SettingsSection(
          title: 'Session administrateur',
          subtitle: 'Compte actuellement connecté',
          icon: Icons.admin_panel_settings_rounded,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.secondary,
                child: Text(
                  email.characters.first.toUpperCase(),
                  style: theme.titleMedium.copyWith(
                    color: const Color(0xFF10243A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session active',
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusPill(
                label: 'En ligne',
                color: theme.success,
                compact: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: 'Apparence',
          subtitle: 'Choisissez le thème de l’espace admin',
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Clair'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Sombre'),
              ),
            ],
            selected: {isDark ? ThemeMode.dark : ThemeMode.light},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              onThemeSelected(selection.first);
            },
          ),
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: 'Sécurité',
          subtitle: 'Gérez l’accès à votre session',
          icon: Icons.lock_rounded,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Déconnexion'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(20),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminIconTile(icon: icon),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
