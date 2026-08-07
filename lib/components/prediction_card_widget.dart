import '/backend/schema/enums/enums.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'prediction_card_model.dart';
export 'prediction_card_model.dart';

class PredictionCardWidget extends StatefulWidget {
  const PredictionCardWidget({
    super.key,
    this.parameter1,
    this.list,
  });

  final Predictions? parameter1;
  final Future Function()? list;

  @override
  State<PredictionCardWidget> createState() => _PredictionCardWidgetState();
}

class _PredictionCardWidgetState extends State<PredictionCardWidget> {
  late PredictionCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PredictionCardModel());
    _model.id0TextController ??= TextEditingController();
    _model.id0FocusNode ??= FocusNode();
    _model.id1TextController ??= TextEditingController();
    _model.id1FocusNode ??= FocusNode();
    _model.id2TextController ??= TextEditingController();
    _model.id2FocusNode ??= FocusNode();
    _model.id3TextController ??= TextEditingController();
    _model.id3FocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final prediction = widget.parameter1;

    return AdminSurface(
      padding: EdgeInsets.zero,
      radius: 20,
      showShadow: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final padding = compact ? 14.0 : 18.0;
          final contentWidth = constraints.maxWidth - padding * 2;
          const gap = 10.0;
          final columns = compact ? 2 : 4;
          final fieldWidth = (contentWidth - gap * (columns - 1)) / columns;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AdminIconTile(
                      icon: _iconForPrediction(prediction),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? theme.secondary
                          : theme.primary,
                      size: 42,
                      iconSize: 21,
                      radius: 13,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelForPrediction(prediction),
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saisissez les 4 valeurs',
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminStatusPill(
                      label: '4 NUMÉROS',
                      color: theme.secondaryText,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _PredictionInput(
                      width: fieldWidth,
                      index: 1,
                      controller: _model.id0TextController!,
                      focusNode: _model.id0FocusNode!,
                      validator: _model.id0TextControllerValidator,
                      onChanged: () => safeSetState(() {}),
                    ),
                    _PredictionInput(
                      width: fieldWidth,
                      index: 2,
                      controller: _model.id1TextController!,
                      focusNode: _model.id1FocusNode!,
                      validator: _model.id1TextControllerValidator,
                      onChanged: () => safeSetState(() {}),
                    ),
                    _PredictionInput(
                      width: fieldWidth,
                      index: 3,
                      controller: _model.id2TextController!,
                      focusNode: _model.id2FocusNode!,
                      validator: _model.id2TextControllerValidator,
                      onChanged: () => safeSetState(() {}),
                    ),
                    _PredictionInput(
                      width: fieldWidth,
                      index: 4,
                      controller: _model.id3TextController!,
                      focusNode: _model.id3FocusNode!,
                      validator: _model.id3TextControllerValidator,
                      onChanged: () => safeSetState(() {}),
                      last: true,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _labelForPrediction(Predictions? prediction) {
    switch (prediction) {
      case Predictions.boulFavoris:
        return 'Boules favorites';
      case Predictions.boloto:
        return 'Boloto';
      case Predictions.extra:
        return 'Extra';
      case Predictions.chif3:
        return 'Chiffre 3';
      case Predictions.chif4:
        return 'Chiffre 4';
      case Predictions.mariages:
        return 'Mariages';
      case Predictions.ggNyFloNy:
        return 'GG · NY · FL';
      case Predictions.soutni:
        return 'Soutni';
      case null:
        return 'Prédiction';
    }
  }

  IconData _iconForPrediction(Predictions? prediction) {
    switch (prediction) {
      case Predictions.mariages:
        return Icons.favorite_rounded;
      case Predictions.chif3:
      case Predictions.chif4:
        return Icons.pin_rounded;
      case Predictions.ggNyFloNy:
        return Icons.public_rounded;
      default:
        return Icons.auto_graph_rounded;
    }
  }
}

class _PredictionInput extends StatelessWidget {
  const _PredictionInput({
    required this.width,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
    this.last = false,
  });

  final double width;
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? Function(BuildContext, String?)? validator;
  final VoidCallback onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) => onChanged(),
        keyboardType: TextInputType.number,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        textAlign: TextAlign.center,
        maxLength: 10,
        buildCounter: (_, {currentLength = 0, isFocused = false, maxLength}) =>
            null,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: theme.primaryBackground,
          labelText: 'N° $index',
          hintText: '—',
          labelStyle: theme.labelMedium.copyWith(
            color: theme.secondaryText,
            fontWeight: FontWeight.w700,
          ),
          floatingLabelStyle: theme.labelSmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? theme.secondary
                : theme.tertiary,
            fontWeight: FontWeight.w800,
          ),
          floatingLabelAlignment: FloatingLabelAlignment.center,
          contentPadding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: theme.secondaryText,
                  ),
                ),
        ),
        style: theme.titleMedium.copyWith(fontWeight: FontWeight.w800),
        validator:
            validator == null ? null : (value) => validator!(context, value),
      ),
    );
  }
}
