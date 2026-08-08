import '/flutter_flow/flutter_flow_model.dart';
import '/pages/sidenav/sidenav_model.dart';
import 'package:flutter/material.dart';
import 'users_widget.dart' show UsersWidget;

class UsersModel extends FlutterFlowModel<UsersWidget> {
  String filtres = 'Tout';

  late SidenavModel sidenavModel;
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;

  @override
  void initState(BuildContext context) {
    sidenavModel = createModel(context, () => SidenavModel());
  }

  @override
  void dispose() {
    sidenavModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
