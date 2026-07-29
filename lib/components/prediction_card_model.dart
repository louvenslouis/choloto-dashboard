import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'prediction_card_widget.dart' show PredictionCardWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PredictionCardModel extends FlutterFlowModel<PredictionCardWidget> {
  ///  Local state fields for this component.

  List<String> bouls = [];
  void addToBouls(String item) => bouls.add(item);
  void removeFromBouls(String item) => bouls.remove(item);
  void removeAtIndexFromBouls(int index) => bouls.removeAt(index);
  void insertAtIndexInBouls(int index, String item) =>
      bouls.insert(index, item);
  void updateBoulsAtIndex(int index, Function(String) updateFn) =>
      bouls[index] = updateFn(bouls[index]);

  ///  State fields for stateful widgets in this component.

  // State field(s) for id0 widget.
  FocusNode? id0FocusNode;
  TextEditingController? id0TextController;
  String? Function(BuildContext, String?)? id0TextControllerValidator;
  // State field(s) for id1 widget.
  FocusNode? id1FocusNode;
  TextEditingController? id1TextController;
  String? Function(BuildContext, String?)? id1TextControllerValidator;
  // State field(s) for id2 widget.
  FocusNode? id2FocusNode;
  TextEditingController? id2TextController;
  String? Function(BuildContext, String?)? id2TextControllerValidator;
  // State field(s) for id3 widget.
  FocusNode? id3FocusNode;
  TextEditingController? id3TextController;
  String? Function(BuildContext, String?)? id3TextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    id0FocusNode?.dispose();
    id0TextController?.dispose();

    id1FocusNode?.dispose();
    id1TextController?.dispose();

    id2FocusNode?.dispose();
    id2TextController?.dispose();

    id3FocusNode?.dispose();
    id3TextController?.dispose();
  }
}
