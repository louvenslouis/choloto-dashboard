import '/backend/backend.dart';
import '/components/mobile_sidenav_widget.dart';
import '/components/paiement_widget.dart';
import '/components/user_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'dart:ui';
import 'users_widget.dart' show UsersWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:text_search/text_search.dart';

class UsersModel extends FlutterFlowModel<UsersWidget> {
  ///  Local state fields for this page.

  List<int> selected = [];
  void addToSelected(int item) => selected.add(item);
  void removeFromSelected(int item) => selected.remove(item);
  void removeAtIndexFromSelected(int index) => selected.removeAt(index);
  void insertAtIndexInSelected(int index, int item) =>
      selected.insert(index, item);
  void updateSelectedAtIndex(int index, Function(int) updateFn) =>
      selected[index] = updateFn(selected[index]);

  String filtres = 'Tout';

  ///  State fields for stateful widgets in this page.

  // Model for mobileSidenav component.
  late MobileSidenavModel mobileSidenavModel;
  // Model for sidenav component.
  late SidenavModel sidenavModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  List<UserRecord> simpleSearchResults = [];
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // State field(s) for PaginatedDataTable widget.
  final paginatedDataTableController =
      FlutterFlowDataTableController<UserRecord>();

  @override
  void initState(BuildContext context) {
    mobileSidenavModel = createModel(context, () => MobileSidenavModel());
    sidenavModel = createModel(context, () => SidenavModel());
  }

  @override
  void dispose() {
    mobileSidenavModel.dispose();
    sidenavModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    paginatedDataTableController.dispose();
  }
}
