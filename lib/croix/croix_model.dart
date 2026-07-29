import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'dart:ui';
import 'croix_widget.dart' show CroixWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CroixModel extends FlutterFlowModel<CroixWidget> {
  ///  Local state fields for this page.

  List<String> list = [];
  void addToList(String item) => list.add(item);
  void removeFromList(String item) => list.remove(item);
  void removeAtIndexFromList(int index) => list.removeAt(index);
  void insertAtIndexInList(int index, String item) => list.insert(index, item);
  void updateListAtIndex(int index, Function(String) updateFn) =>
      list[index] = updateFn(list[index]);

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for sidenav component.
  late SidenavModel sidenavModel;
  // State field(s) for zero widget.
  FocusNode? zeroFocusNode;
  TextEditingController? zeroTextController;
  String? Function(BuildContext, String?)? zeroTextControllerValidator;
  String? _zeroTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for un widget.
  FocusNode? unFocusNode;
  TextEditingController? unTextController;
  String? Function(BuildContext, String?)? unTextControllerValidator;
  String? _unTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for deux widget.
  FocusNode? deuxFocusNode;
  TextEditingController? deuxTextController;
  String? Function(BuildContext, String?)? deuxTextControllerValidator;
  String? _deuxTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for trois widget.
  FocusNode? troisFocusNode;
  TextEditingController? troisTextController;
  String? Function(BuildContext, String?)? troisTextControllerValidator;
  String? _troisTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for quatrevide widget.
  FocusNode? quatrevideFocusNode;
  TextEditingController? quatrevideTextController;
  String? Function(BuildContext, String?)? quatrevideTextControllerValidator;
  // State field(s) for cinq widget.
  FocusNode? cinqFocusNode;
  TextEditingController? cinqTextController;
  String? Function(BuildContext, String?)? cinqTextControllerValidator;
  String? _cinqTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for six widget.
  FocusNode? sixFocusNode;
  TextEditingController? sixTextController;
  String? Function(BuildContext, String?)? sixTextControllerValidator;
  String? _sixTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for sept widget.
  FocusNode? septFocusNode;
  TextEditingController? septTextController;
  String? Function(BuildContext, String?)? septTextControllerValidator;
  String? _septTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  // State field(s) for huit widget.
  FocusNode? huitFocusNode;
  TextEditingController? huitTextController;
  String? Function(BuildContext, String?)? huitTextControllerValidator;
  String? _huitTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return '00 is required';
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    sidenavModel = createModel(context, () => SidenavModel());
    zeroTextControllerValidator = _zeroTextControllerValidator;
    unTextControllerValidator = _unTextControllerValidator;
    deuxTextControllerValidator = _deuxTextControllerValidator;
    troisTextControllerValidator = _troisTextControllerValidator;
    cinqTextControllerValidator = _cinqTextControllerValidator;
    sixTextControllerValidator = _sixTextControllerValidator;
    septTextControllerValidator = _septTextControllerValidator;
    huitTextControllerValidator = _huitTextControllerValidator;
  }

  @override
  void dispose() {
    sidenavModel.dispose();
    zeroFocusNode?.dispose();
    zeroTextController?.dispose();

    unFocusNode?.dispose();
    unTextController?.dispose();

    deuxFocusNode?.dispose();
    deuxTextController?.dispose();

    troisFocusNode?.dispose();
    troisTextController?.dispose();

    quatrevideFocusNode?.dispose();
    quatrevideTextController?.dispose();

    cinqFocusNode?.dispose();
    cinqTextController?.dispose();

    sixFocusNode?.dispose();
    sixTextController?.dispose();

    septFocusNode?.dispose();
    septTextController?.dispose();

    huitFocusNode?.dispose();
    huitTextController?.dispose();
  }
}
