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
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: theme.secondaryBackground,
      surfaceTintColor: theme.secondaryBackground,
      foregroundColor: theme.primaryText,
      titleSpacing: 4,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/Logo_Choloto_509.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Administration CHOLOTO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.copyWith(
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w500,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(99),
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
                  const SizedBox(width: 6),
                  Text(
                    'En ligne',
                    style: theme.labelSmall.copyWith(
                      color: theme.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      shape: Border(
        bottom: BorderSide(color: theme.alternate.withValues(alpha: .8)),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.eyebrow = 'ESPACE DE GESTION',
  });

  final String title;
  final String description;
  final IconData icon;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 4, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.secondary.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: theme.secondary.withValues(alpha: .34),
                ),
              ),
              child: Icon(icon, color: theme.primary, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: theme.labelSmall.copyWith(
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                      height: 1.45,
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
