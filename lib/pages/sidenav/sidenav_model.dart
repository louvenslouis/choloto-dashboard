import '/auth/firebase_auth/auth_util.dart';
import '/components/menubutton_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'sidenav_widget.dart' show SidenavWidget;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SidenavModel extends FlutterFlowModel<SidenavWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for menubutton component.
  late MenubuttonModel menubuttonModel;

  @override
  void initState(BuildContext context) {
    menubuttonModel = createModel(context, () => MenubuttonModel());
  }

  @override
  void dispose() {
    menubuttonModel.dispose();
  }
}
