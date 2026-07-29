import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/components/prediction_card_widget.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_count_controller.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'dart:ui';
import 'predictions_widget.dart' show PredictionsWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PredictionsModel extends FlutterFlowModel<PredictionsWidget> {
  ///  Local state fields for this page.

  List<int> list = [];
  void addToList(int item) => list.add(item);
  void removeFromList(int item) => list.remove(item);
  void removeAtIndexFromList(int index) => list.removeAt(index);
  void insertAtIndexInList(int index, int item) => list.insert(index, item);
  void updateListAtIndex(int index, Function(int) updateFn) =>
      list[index] = updateFn(list[index]);

  IdPredictionsStruct? predictions;
  void updatePredictionsStruct(Function(IdPredictionsStruct) updateFn) {
    updateFn(predictions ??= IdPredictionsStruct());
  }

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

  // Model for favoris.
  late PredictionCardModel favorisModel;
  // Model for soutni.
  late PredictionCardModel soutniModel;
  // Model for boloto.
  late PredictionCardModel bolotoModel;
  // Model for mariages.
  late PredictionCardModel mariagesModel;
  // Model for chif3.
  late PredictionCardModel chif3Model;
  // Model for chif4.
  late PredictionCardModel chif4Model;
  // Model for extra.
  late PredictionCardModel extraModel;
  // State field(s) for periode widget.
  String? periodeValue;
  FormFieldController<String>? periodeValueController;
  // State field(s) for pourcentage widget.
  int? pourcentageValue;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  PredictionRecord? predictionreference;

  @override
  void initState(BuildContext context) {
    sidenavModel = createModel(context, () => SidenavModel());
    favorisModel = createModel(context, () => PredictionCardModel());
    soutniModel = createModel(context, () => PredictionCardModel());
    bolotoModel = createModel(context, () => PredictionCardModel());
    mariagesModel = createModel(context, () => PredictionCardModel());
    chif3Model = createModel(context, () => PredictionCardModel());
    chif4Model = createModel(context, () => PredictionCardModel());
    extraModel = createModel(context, () => PredictionCardModel());
  }

  @override
  void dispose() {
    sidenavModel.dispose();
    tabBarController?.dispose();
    favorisModel.dispose();
    soutniModel.dispose();
    bolotoModel.dispose();
    mariagesModel.dispose();
    chif3Model.dispose();
    chif4Model.dispose();
    extraModel.dispose();
  }
}
