import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'mobile_sidenav_model.dart';
export 'mobile_sidenav_model.dart';

class MobileSidenavWidget extends StatefulWidget {
  const MobileSidenavWidget({super.key});

  @override
  State<MobileSidenavWidget> createState() => _MobileSidenavWidgetState();
}

class _MobileSidenavWidgetState extends State<MobileSidenavWidget> {
  late MobileSidenavModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MobileSidenavModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.alternate.withValues(alpha: .72)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: theme.alternate),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: theme.primaryText,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
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
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHOLOTO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                    ),
                  ),
                  Text(
                    'ESPACE ADMIN',
                    style: theme.labelSmall.copyWith(
                      color: theme.secondaryText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AdminStatusPill(
              label: 'En ligne',
              color: theme.success,
              compact: true,
              leading: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: theme.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
