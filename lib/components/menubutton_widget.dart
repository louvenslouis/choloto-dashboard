import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'menubutton_model.dart';
export 'menubutton_model.dart';

class MenubuttonWidget extends StatefulWidget {
  const MenubuttonWidget({
    super.key,
    required this.icon,
    required this.name,
    this.bgColor,
  });

  final Widget? icon;
  final String? name;
  final Color? bgColor;

  @override
  State<MenubuttonWidget> createState() => _MenubuttonWidgetState();
}

class _MenubuttonWidgetState extends State<MenubuttonWidget> {
  late MenubuttonModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenubuttonModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selected = widget.bgColor != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: widget.bgColor ?? theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.secondary.withValues(alpha: .32)
                : theme.alternate,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryText.withValues(alpha: .045),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? theme.secondary.withValues(alpha: .18)
                    : theme.primaryBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: selected ? theme.primary : theme.secondaryText,
                  size: 19,
                ),
                child: widget.icon ?? const Icon(Icons.circle_outlined),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                valueOrDefault<String>(widget.name, 'Menu'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
