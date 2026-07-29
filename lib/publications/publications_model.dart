import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'dart:ui';
import 'publications_widget.dart' show PublicationsWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PublicationsModel extends FlutterFlowModel<PublicationsWidget> {
  ///  Local state fields for this page.

  List<DataStackStruct> dataStack = [];
  void addToDataStack(DataStackStruct item) => dataStack.add(item);
  void removeFromDataStack(DataStackStruct item) => dataStack.remove(item);
  void removeAtIndexFromDataStack(int index) => dataStack.removeAt(index);
  void insertAtIndexInDataStack(int index, DataStackStruct item) =>
      dataStack.insert(index, item);
  void updateDataStackAtIndex(int index, Function(DataStackStruct) updateFn) =>
      dataStack[index] = updateFn(dataStack[index]);

  int? secondes;

  DateTime? expiration;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for sidenav component.
  late SidenavModel sidenavModel;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for numero1 widget.
  FocusNode? numero1FocusNode;
  TextEditingController? numero1TextController;
  String? Function(BuildContext, String?)? numero1TextControllerValidator;
  String? _numero1TextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Le Numero du Bingo is required';
    }

    return null;
  }

  // State field(s) for valeur1 widget.
  String? valeur1Value;
  FormFieldController<String>? valeur1ValueController;
  // State field(s) for nomtirage1 widget.
  String? nomtirage1Value;
  FormFieldController<String>? nomtirage1ValueController;
  // State field(s) for choice1 widget.
  FormFieldController<List<String>>? choice1ValueController;
  String? get choice1Value => choice1ValueController?.value?.firstOrNull;
  set choice1Value(String? val) =>
      choice1ValueController?.value = val != null ? [val] : [];
  // State field(s) for numero2 widget.
  FocusNode? numero2FocusNode;
  TextEditingController? numero2TextController;
  String? Function(BuildContext, String?)? numero2TextControllerValidator;
  // State field(s) for valeur2 widget.
  FocusNode? valeur2FocusNode;
  TextEditingController? valeur2TextController;
  String? Function(BuildContext, String?)? valeur2TextControllerValidator;
  // State field(s) for nom2 widget.
  FocusNode? nom2FocusNode;
  TextEditingController? nom2TextController;
  String? Function(BuildContext, String?)? nom2TextControllerValidator;
  // State field(s) for choice2 widget.
  FormFieldController<List<String>>? choice2ValueController;
  String? get choice2Value => choice2ValueController?.value?.firstOrNull;
  set choice2Value(String? val) =>
      choice2ValueController?.value = val != null ? [val] : [];
  // State field(s) for numero3 widget.
  FocusNode? numero3FocusNode;
  TextEditingController? numero3TextController;
  String? Function(BuildContext, String?)? numero3TextControllerValidator;
  // State field(s) for valeur3 widget.
  FocusNode? valeur3FocusNode;
  TextEditingController? valeur3TextController;
  String? Function(BuildContext, String?)? valeur3TextControllerValidator;
  // State field(s) for nom3 widget.
  FocusNode? nom3FocusNode;
  TextEditingController? nom3TextController;
  String? Function(BuildContext, String?)? nom3TextControllerValidator;
  // State field(s) for choice3 widget.
  FormFieldController<List<String>>? choice3ValueController;
  String? get choice3Value => choice3ValueController?.value?.firstOrNull;
  set choice3Value(String? val) =>
      choice3ValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {
    sidenavModel = createModel(context, () => SidenavModel());
    numero1TextControllerValidator = _numero1TextControllerValidator;
  }

  @override
  void dispose() {
    sidenavModel.dispose();
    tabBarController?.dispose();
    numero1FocusNode?.dispose();
    numero1TextController?.dispose();

    numero2FocusNode?.dispose();
    numero2TextController?.dispose();

    valeur2FocusNode?.dispose();
    valeur2TextController?.dispose();

    nom2FocusNode?.dispose();
    nom2TextController?.dispose();

    numero3FocusNode?.dispose();
    numero3TextController?.dispose();

    valeur3FocusNode?.dispose();
    valeur3TextController?.dispose();

    nom3FocusNode?.dispose();
    nom3TextController?.dispose();
  }
}
