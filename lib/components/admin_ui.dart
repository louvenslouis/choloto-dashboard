import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

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
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 390;

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.secondaryBackground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: theme.primaryText,
      titleSpacing: 2,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: theme.accent1,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              size: 19,
              color: Theme.of(context).brightness == Brightness.dark
                  ? theme.secondary
                  : theme.primary,
            ),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.only(right: 12),
          child: Semantics(
            label: 'Système opérationnel',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: theme.success.withValues(alpha: .16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      'En ligne',
                      style: theme.labelSmall.copyWith(
                        color: theme.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
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
            Container(
              width: compact ? 42 : 46,
              height: compact ? 42 : 46,
              decoration: BoxDecoration(
                color: theme.accent1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.secondary.withValues(alpha: .24),
                ),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? theme.secondary
                    : theme.primary,
                size: compact ? 21 : 23,
              ),
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
