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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.alternate)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.menu_rounded, color: theme.info),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/Logo_Choloto_509.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'CHOLOTO',
              style: theme.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: theme.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
