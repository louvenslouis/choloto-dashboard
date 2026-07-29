import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'dart:ui';
import 'tirages_widget.dart' show TiragesWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TiragesModel extends FlutterFlowModel<TiragesWidget> {
  ///  Local state fields for this page.

  List<String> ny = [];
  void addToNy(String item) => ny.add(item);
  void removeFromNy(String item) => ny.remove(item);
  void removeAtIndexFromNy(int index) => ny.removeAt(index);
  void insertAtIndexInNy(int index, String item) => ny.insert(index, item);
  void updateNyAtIndex(int index, Function(String) updateFn) =>
      ny[index] = updateFn(ny[index]);

  List<String> fl = [];
  void addToFl(String item) => fl.add(item);
  void removeFromFl(String item) => fl.remove(item);
  void removeAtIndexFromFl(int index) => fl.removeAt(index);
  void insertAtIndexInFl(int index, String item) => fl.insert(index, item);
  void updateFlAtIndex(int index, Function(String) updateFn) =>
      fl[index] = updateFn(fl[index]);

  ///  State fields for stateful widgets in this page.

  // Model for sidenav component.
  late SidenavModel sidenavModel;
  // State field(s) for cf3 widget.
  FocusNode? cf3FocusNode;
  TextEditingController? cf3TextController;
  String? Function(BuildContext, String?)? cf3TextControllerValidator;
  // State field(s) for un widget.
  FocusNode? unFocusNode;
  TextEditingController? unTextController;
  String? Function(BuildContext, String?)? unTextControllerValidator;
  // State field(s) for lo3 widget.
  FocusNode? lo3FocusNode;
  TextEditingController? lo3TextController;
  String? Function(BuildContext, String?)? lo3TextControllerValidator;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // State field(s) for pk2 widget.
  FocusNode? pk2FocusNode;
  TextEditingController? pk2TextController;
  String? Function(BuildContext, String?)? pk2TextControllerValidator;
  // State field(s) for pk3 widget.
  FocusNode? pk3FocusNode;
  TextEditingController? pk3TextController;
  String? Function(BuildContext, String?)? pk3TextControllerValidator;
  // State field(s) for pk41 widget.
  FocusNode? pk41FocusNode;
  TextEditingController? pk41TextController;
  String? Function(BuildContext, String?)? pk41TextControllerValidator;
  // State field(s) for pk42 widget.
  FocusNode? pk42FocusNode;
  TextEditingController? pk42TextController;
  String? Function(BuildContext, String?)? pk42TextControllerValidator;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {
    sidenavModel = createModel(context, () => SidenavModel());
  }

  @override
  void dispose() {
    sidenavModel.dispose();
    cf3FocusNode?.dispose();
    cf3TextController?.dispose();

    unFocusNode?.dispose();
    unTextController?.dispose();

    lo3FocusNode?.dispose();
    lo3TextController?.dispose();

    pk2FocusNode?.dispose();
    pk2TextController?.dispose();

    pk3FocusNode?.dispose();
    pk3TextController?.dispose();

    pk41FocusNode?.dispose();
    pk41TextController?.dispose();

    pk42FocusNode?.dispose();
    pk42TextController?.dispose();
  }
}
