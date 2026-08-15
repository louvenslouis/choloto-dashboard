import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';
import 'publications_widget.dart' show PublicationsWidget;

class PublicationsModel extends FlutterFlowModel<PublicationsWidget> {
  late SidenavModel sidenavModel;

  @override
  void initState(BuildContext context) {
    sidenavModel = createModel(context, () => SidenavModel());
  }

  @override
  void dispose() {
    sidenavModel.dispose();
  }
}
