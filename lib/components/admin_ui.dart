import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

enum AdminMobileDestination {
  dashboard,
  tirages,
  predictions,
  users,
  more,
}

/// Neutral content surface shared by cards, summaries and dialog sections.
/// It deliberately carries no interaction so wrapping existing controls does
/// not change their behavior.
class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 18,
    this.showShadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.secondaryBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? theme.alternate),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: theme.primaryText.withValues(alpha: .055),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Branded icon treatment used across headings, cards and dialogs.
class AdminIconTile extends StatelessWidget {
  const AdminIconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 22,
    this.radius = 14,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = color ?? theme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: .16)),
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}

/// Small status or metadata label with one consistent pill treatment.
class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.leading,
    this.compact = false,
    this.foregroundColor,
  });

  final String label;
  final Color color;
  final Widget? leading;
  final bool compact;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        border: Border.all(color: color.withValues(alpha: .17)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: foregroundColor ?? color,
              fontSize: compact ? 10 : null,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? .35 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared presentation widgets for the administration workspace.
///
/// Keeping the page heading and the mobile navigation in one place makes the
/// generated FlutterFlow screens feel like one coherent product.
class AdminMobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminMobileAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 370;

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.secondaryBackground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: theme.primaryText,
      leadingWidth: 60,
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10),
          child: IconButton(
            tooltip: 'Ouvrir le menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: theme.primaryText,
              backgroundColor: theme.primaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: BorderSide(color: theme.alternate),
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: Row(
        children: [
          if (!compact) ...[
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: theme.alternate),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/Logo_Choloto_509.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Semantics(
            label: 'Système opérationnel',
            child: MediaQuery.sizeOf(context).width >= 410
                ? AdminStatusPill(
                    label: 'En ligne',
                    color: theme.success,
                    compact: compact,
                    leading: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: theme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.success.withValues(alpha: .10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.success.withValues(alpha: .17),
                      ),
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
          ),
        ),
      ],
      shape: Border(
        bottom: BorderSide(color: theme.alternate.withValues(alpha: .72)),
      ),
    );
  }
}

/// Persistent shortcuts for the most common administration tasks on phones.
/// Secondary screens stay available from the drawer via the "Menu" item.
class AdminMobileBottomBar extends StatelessWidget {
  const AdminMobileBottomBar({
    super.key,
    required this.activeDestination,
    required this.onOpenMenu,
  });

  final AdminMobileDestination activeDestination;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selectedIndex = activeDestination.index;

    return Material(
      color: theme.secondaryBackground,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.alternate.withValues(alpha: .9)),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryText.withValues(alpha: .055),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return theme.labelSmall.copyWith(
                  color: selected ? theme.primaryText : theme.secondaryText,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10.5,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  color: selected ? theme.primary : theme.secondaryText,
                  size: selected ? 24 : 22,
                );
              }),
            ),
            child: NavigationBar(
              height: 68,
              selectedIndex: selectedIndex,
              animationDuration: const Duration(milliseconds: 280),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              backgroundColor: theme.secondaryBackground,
              indicatorColor: theme.secondary.withValues(alpha: .22),
              surfaceTintColor: Colors.transparent,
              onDestinationSelected: (index) {
                if (index == selectedIndex && index != 4) return;
                switch (index) {
                  case 0:
                    context.goNamed('Dashboard');
                    return;
                  case 1:
                    context.goNamed('tirages');
                    return;
                  case 2:
                    context.goNamed('predictions');
                    return;
                  case 3:
                    context.goNamed('users');
                    return;
                  case 4:
                    onOpenMenu();
                    return;
                }
              },
              destinations: const [
                NavigationDestination(
                  tooltip: 'Tableau de bord',
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  tooltip: 'Gérer les tirages',
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number_rounded),
                  label: 'Tirages',
                ),
                NavigationDestination(
                  tooltip: 'Gérer les prédictions',
                  icon: Icon(Icons.auto_graph_outlined),
                  selectedIcon: Icon(Icons.auto_graph_rounded),
                  label: 'Prévisions',
                ),
                NavigationDestination(
                  tooltip: 'Gérer les membres',
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt_rounded),
                  label: 'Membres',
                ),
                NavigationDestination(
                  tooltip: 'Ouvrir le menu complet',
                  icon: Icon(Icons.menu_rounded),
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDialogFrame extends StatelessWidget {
  const AdminDialogFrame({
    super.key,
    required this.child,
    this.maxWidth = 520,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 600;

    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 28,
        vertical: mobile ? 16 : 28,
      ),
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: size.height * .9,
          ),
          child: Material(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 12,
            shadowColor:
                FlutterFlowTheme.of(context).primaryText.withValues(alpha: .14),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(mobile ? 24 : 28),
              side: BorderSide(
                color: FlutterFlowTheme.of(context).alternate,
              ),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDialogHeader extends StatelessWidget {
  const AdminDialogHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.onClose,
    this.subtitle,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = iconColor ?? theme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminIconTile(icon: icon, color: color),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.35,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Fermer',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: 21),
          style: IconButton.styleFrom(
            backgroundColor: theme.primaryBackground,
            foregroundColor: theme.secondaryText,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(color: theme.alternate),
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> showAdminConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AdminConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          icon: icon,
          destructive: destructive,
        ),
      ) ??
      false;
}

class AdminConfirmDialog extends StatelessWidget {
  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final actionColor = destructive ? theme.error : theme.primary;

    return AdminDialogFrame(
      maxWidth: 440,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminDialogHeader(
              title: title,
              icon: icon,
              iconColor: actionColor,
              onClose: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 330;
                final cancel = OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(cancelLabel),
                );
                final confirm = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(icon, size: 18),
                  label: Text(confirmLabel),
                );

                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      confirm,
                      const SizedBox(height: 10),
                      cancel,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: 12),
                    Expanded(child: confirm),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAdminNoticeDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonLabel = 'Compris',
  IconData icon = Icons.info_outline_rounded,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AdminDialogFrame(
      maxWidth: 440,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminDialogHeader(
              title: title,
              icon: icon,
              onClose: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: FlutterFlowTheme.of(dialogContext).bodyMedium.copyWith(
                    color: FlutterFlowTheme.of(dialogContext).secondaryText,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.eyebrow = 'ESPACE DE GESTION',
    this.dense = false,
  });

  final String title;
  final IconData icon;
  final String eyebrow;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Semantics(
      header: true,
      child: Padding(
        padding: dense
            ? const EdgeInsets.fromLTRB(2, 16, 2, 14)
            : EdgeInsets.fromLTRB(
                2,
                compact ? 24 : 34,
                2,
                compact ? 20 : 26,
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminIconTile(
              icon: icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? theme.secondary
                  : theme.primary,
              size: compact ? 42 : 46,
              iconSize: compact ? 21 : 23,
            ),
            SizedBox(width: compact ? 13 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: theme.labelSmall.copyWith(
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style:
                        (compact ? theme.headlineSmall : theme.headlineMedium)
                            .copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                      height: 1.12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
