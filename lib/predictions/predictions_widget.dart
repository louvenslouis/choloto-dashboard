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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'predictions_model.dart';
export 'predictions_model.dart';

class PredictionsWidget extends StatefulWidget {
  const PredictionsWidget({super.key});

  static String routeName = 'predictions';
  static String routePath = '/predictions';

  @override
  State<PredictionsWidget> createState() => _PredictionsWidgetState();
}

class _PredictionsWidgetState extends State<PredictionsWidget>
    with TickerProviderStateMixin {
  late PredictionsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PredictionsModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'predictions'});
    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.sidenavModel,
                updateCallback: () => safeSetState(() {}),
                child: SidenavWidget(),
              ),
              Expanded(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment(0.0, 0),
                      child: FlutterFlowButtonTabBar(
                        useToggleButtonStyle: false,
                        labelStyle:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                        unselectedLabelStyle:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                        labelColor: FlutterFlowTheme.of(context).primaryText,
                        unselectedLabelColor:
                            FlutterFlowTheme.of(context).secondaryText,
                        backgroundColor: FlutterFlowTheme.of(context).accent1,
                        unselectedBackgroundColor:
                            FlutterFlowTheme.of(context).alternate,
                        borderColor: FlutterFlowTheme.of(context).primary,
                        unselectedBorderColor:
                            FlutterFlowTheme.of(context).alternate,
                        borderWidth: 2.0,
                        borderRadius: 8.0,
                        elevation: 0.0,
                        buttonMargin:
                            EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                        tabs: [
                          Tab(
                            text: 'Predictions',
                          ),
                          Tab(
                            text: 'Historique',
                          ),
                        ],
                        controller: _model.tabBarController,
                        onTap: (i) async {
                          [() async {}, () async {}][i]();
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _model.tabBarController,
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, -1.0),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: BoxConstraints(
                                        maxWidth: 970.0,
                                      ),
                                      decoration: BoxDecoration(),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Form(
                                              key: _model.formKey,
                                              autovalidateMode:
                                                  AutovalidateMode.disabled,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    wrapWithModel(
                                                      model:
                                                          _model.favorisModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1: Predictions
                                                            .boulFavoris,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                    wrapWithModel(
                                                      model: _model.soutniModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1:
                                                            Predictions.soutni,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                    wrapWithModel(
                                                      model: _model.bolotoModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1:
                                                            Predictions.boloto,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                    wrapWithModel(
                                                      model:
                                                          _model.mariagesModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1: Predictions
                                                            .mariages,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                    wrapWithModel(
                                                      model: _model.chif3Model,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1:
                                                            Predictions.chif3,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                    wrapWithModel(
                                                      model: _model.chif4Model,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1:
                                                            Predictions.chif4,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                    wrapWithModel(
                                                      model: _model.extraModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          PredictionCardWidget(
                                                        parameter1:
                                                            Predictions.extra,
                                                        list: () async {},
                                                      ),
                                                    ),
                                                  ]
                                                      .divide(
                                                          SizedBox(height: 8.0))
                                                      .addToEnd(SizedBox(
                                                          height: 15.0)),
                                                ),
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 0.0,
                                              runSpacing: 0.0,
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              direction: Axis.horizontal,
                                              runAlignment:
                                                  WrapAlignment.center,
                                              verticalDirection:
                                                  VerticalDirection.down,
                                              clipBehavior: Clip.none,
                                              children: [
                                                FlutterFlowDropDown<String>(
                                                  controller: _model
                                                          .periodeValueController ??=
                                                      FormFieldController<
                                                          String>(
                                                    _model.periodeValue ??= '',
                                                  ),
                                                  options: List<String>.from([
                                                    'Matin',
                                                    'Midi',
                                                    'Soir'
                                                  ]),
                                                  optionLabels: [
                                                    'Matin',
                                                    'Midi',
                                                    'Soir'
                                                  ],
                                                  onChanged: (val) =>
                                                      safeSetState(() => _model
                                                          .periodeValue = val),
                                                  width: 200.0,
                                                  height: 40.0,
                                                  textStyle: FlutterFlowTheme
                                                          .of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                  hintText: 'Période',
                                                  icon: Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    size: 24.0,
                                                  ),
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground,
                                                  elevation: 2.0,
                                                  borderColor:
                                                      Colors.transparent,
                                                  borderWidth: 0.0,
                                                  borderRadius: 8.0,
                                                  margin: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  hidesUnderline: true,
                                                  isOverButton: false,
                                                  isSearchable: false,
                                                  isMultiSelect: false,
                                                ),
                                                Container(
                                                  width: 120.0,
                                                  height: 40.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    shape: BoxShape.rectangle,
                                                  ),
                                                  child:
                                                      FlutterFlowCountController(
                                                    decrementIconBuilder:
                                                        (enabled) => Icon(
                                                      Icons.remove_rounded,
                                                      color: enabled
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
                                                      size: 24.0,
                                                    ),
                                                    incrementIconBuilder:
                                                        (enabled) => Icon(
                                                      Icons.add_rounded,
                                                      color: enabled
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
                                                      size: 24.0,
                                                    ),
                                                    countBuilder: (count) =>
                                                        Text(
                                                      count.toString(),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleLarge
                                                              .override(
                                                                font: GoogleFonts
                                                                    .interTight(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                    count: _model
                                                        .pourcentageValue ??= 80,
                                                    updateCount: (count) =>
                                                        safeSetState(() => _model
                                                                .pourcentageValue =
                                                            count),
                                                    stepSize: 5,
                                                    contentPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                  ),
                                                ),
                                                FFButtonWidget(
                                                  onPressed: () async {
                                                    logFirebaseEvent(
                                                        'PREDICTIONS_PAGE_UPDATE_BTN_ON_TAP');
                                                    logFirebaseEvent(
                                                        'Button_update_page_state');
                                                    _model.predictions = null;
                                                    logFirebaseEvent(
                                                        'Button_show_snack_bar');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'step 1 block test',
                                                          style: TextStyle(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                          ),
                                                        ),
                                                        duration: Duration(
                                                            milliseconds: 4000),
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
                                                      ),
                                                    );
                                                    await Future.wait([
                                                      Future(() async {
                                                        // id0
                                                        logFirebaseEvent(
                                                            'Button_id0');
                                                        _model
                                                            .updatePredictionsStruct(
                                                          (e) => e
                                                            ..updateBoloto(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .bolotoModel
                                                                      .id0TextController
                                                                      .text),
                                                            )
                                                            ..updateChif3(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .chif3Model
                                                                      .id0TextController
                                                                      .text),
                                                            )
                                                            ..updateChif4(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .chif4Model
                                                                      .id0TextController
                                                                      .text),
                                                            )
                                                            ..updateMariage(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .mariagesModel
                                                                      .id0TextController
                                                                      .text),
                                                            )
                                                            ..updateFavori(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .favorisModel
                                                                      .id0TextController
                                                                      .text),
                                                            )
                                                            ..updateSoutni(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .soutniModel
                                                                      .id0TextController
                                                                      .text),
                                                            )
                                                            ..updateExtra(
                                                              (e) => e.insert(
                                                                  0,
                                                                  _model
                                                                      .extraModel
                                                                      .id0TextController
                                                                      .text),
                                                            ),
                                                        );
                                                      }),
                                                      Future(() async {
                                                        // id1
                                                        logFirebaseEvent(
                                                            'Button_id1');
                                                        _model
                                                            .updatePredictionsStruct(
                                                          (e) => e
                                                            ..updateBoloto(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .bolotoModel
                                                                      .id1TextController
                                                                      .text),
                                                            )
                                                            ..updateChif3(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .chif3Model
                                                                      .id1TextController
                                                                      .text),
                                                            )
                                                            ..updateChif4(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .chif4Model
                                                                      .id1TextController
                                                                      .text),
                                                            )
                                                            ..updateMariage(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .mariagesModel
                                                                      .id1TextController
                                                                      .text),
                                                            )
                                                            ..updateFavori(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .favorisModel
                                                                      .id1TextController
                                                                      .text),
                                                            )
                                                            ..updateSoutni(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .soutniModel
                                                                      .id1TextController
                                                                      .text),
                                                            )
                                                            ..updateExtra(
                                                              (e) => e.insert(
                                                                  1,
                                                                  _model
                                                                      .extraModel
                                                                      .id1TextController
                                                                      .text),
                                                            ),
                                                        );
                                                      }),
                                                      Future(() async {
                                                        // id2
                                                        logFirebaseEvent(
                                                            'Button_id2');
                                                        _model
                                                            .updatePredictionsStruct(
                                                          (e) => e
                                                            ..updateBoloto(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .bolotoModel
                                                                      .id2TextController
                                                                      .text),
                                                            )
                                                            ..updateChif3(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .chif3Model
                                                                      .id2TextController
                                                                      .text),
                                                            )
                                                            ..updateChif4(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .chif4Model
                                                                      .id2TextController
                                                                      .text),
                                                            )
                                                            ..updateMariage(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .mariagesModel
                                                                      .id2TextController
                                                                      .text),
                                                            )
                                                            ..updateFavori(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .favorisModel
                                                                      .id2TextController
                                                                      .text),
                                                            )
                                                            ..updateSoutni(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .soutniModel
                                                                      .id2TextController
                                                                      .text),
                                                            )
                                                            ..updateExtra(
                                                              (e) => e.insert(
                                                                  2,
                                                                  _model
                                                                      .extraModel
                                                                      .id2TextController
                                                                      .text),
                                                            ),
                                                        );
                                                      }),
                                                      Future(() async {
                                                        // id3
                                                        logFirebaseEvent(
                                                            'Button_id3');
                                                        _model
                                                            .updatePredictionsStruct(
                                                          (e) => e
                                                            ..updateBoloto(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .bolotoModel
                                                                      .id3TextController
                                                                      .text),
                                                            )
                                                            ..updateChif3(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .chif3Model
                                                                      .id3TextController
                                                                      .text),
                                                            )
                                                            ..updateChif4(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .chif4Model
                                                                      .id3TextController
                                                                      .text),
                                                            )
                                                            ..updateMariage(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .mariagesModel
                                                                      .id3TextController
                                                                      .text),
                                                            )
                                                            ..updateFavori(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .favorisModel
                                                                      .id3TextController
                                                                      .text),
                                                            )
                                                            ..updateSoutni(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .soutniModel
                                                                      .id3TextController
                                                                      .text),
                                                            )
                                                            ..updateExtra(
                                                              (e) => e.insert(
                                                                  3,
                                                                  _model
                                                                      .extraModel
                                                                      .id3TextController
                                                                      .text),
                                                            ),
                                                        );
                                                      }),
                                                    ]);
                                                    logFirebaseEvent(
                                                        'Button_wait__delay');
                                                    await Future.delayed(
                                                      Duration(
                                                        milliseconds: 2000,
                                                      ),
                                                    );
                                                    logFirebaseEvent(
                                                        'Button_show_snack_bar');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Suivant',
                                                          style: TextStyle(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                          ),
                                                        ),
                                                        duration: Duration(
                                                            milliseconds: 4000),
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
                                                      ),
                                                    );
                                                    logFirebaseEvent(
                                                        'Button_backend_call');

                                                    var predictionRecordReference =
                                                        PredictionRecord
                                                            .collection
                                                            .doc();
                                                    await predictionRecordReference
                                                        .set({
                                                      ...createPredictionRecordData(
                                                        boloto:
                                                            createPredictionsStruct(
                                                          name: 'BOLOTO',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.boloto,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        chif3:
                                                            createPredictionsStruct(
                                                          name: '3 CHIFFRES',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.chif3,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        chif4:
                                                            createPredictionsStruct(
                                                          name: '4 CHIFFRES',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.chif4,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        mariage:
                                                            createPredictionsStruct(
                                                          name: 'MARIAGE',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.mariage,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        periode:
                                                            _model.periodeValue,
                                                        pourcentage: _model
                                                            .pourcentageValue,
                                                        createdBy:
                                                            currentUserUid,
                                                        soutni:
                                                            createPredictionsStruct(
                                                          name: 'SOUTNI',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.soutni,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        extra:
                                                            createPredictionsStruct(
                                                          name: 'EXTRA',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.extra,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        favori:
                                                            createPredictionsStruct(
                                                          name: 'FAVORI',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.favori,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                      ),
                                                      ...mapToFirestore(
                                                        {
                                                          'date': FieldValue
                                                              .serverTimestamp(),
                                                        },
                                                      ),
                                                    });
                                                    _model.predictionreference =
                                                        PredictionRecord
                                                            .getDocumentFromData({
                                                      ...createPredictionRecordData(
                                                        boloto:
                                                            createPredictionsStruct(
                                                          name: 'BOLOTO',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.boloto,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        chif3:
                                                            createPredictionsStruct(
                                                          name: '3 CHIFFRES',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.chif3,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        chif4:
                                                            createPredictionsStruct(
                                                          name: '4 CHIFFRES',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.chif4,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        mariage:
                                                            createPredictionsStruct(
                                                          name: 'MARIAGE',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.mariage,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        periode:
                                                            _model.periodeValue,
                                                        pourcentage: _model
                                                            .pourcentageValue,
                                                        createdBy:
                                                            currentUserUid,
                                                        soutni:
                                                            createPredictionsStruct(
                                                          name: 'SOUTNI',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.soutni,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        extra:
                                                            createPredictionsStruct(
                                                          name: 'EXTRA',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.extra,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        favori:
                                                            createPredictionsStruct(
                                                          name: 'FAVORI',
                                                          fieldValues: {
                                                            'boul': _model
                                                                .predictions
                                                                ?.favori,
                                                          },
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                      ),
                                                      ...mapToFirestore(
                                                        {
                                                          'date':
                                                              DateTime.now(),
                                                        },
                                                      ),
                                                    }, predictionRecordReference);
                                                    logFirebaseEvent(
                                                        'Button_show_snack_bar');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'creation1',
                                                          style: TextStyle(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                          ),
                                                        ),
                                                        duration: Duration(
                                                            milliseconds: 4000),
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
                                                      ),
                                                    );

                                                    safeSetState(() {});
                                                  },
                                                  text: 'UPDATE',
                                                  options: FFButtonOptions(
                                                    height: 40.0,
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(16.0, 0.0,
                                                                16.0, 0.0),
                                                    iconPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .interTight(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .fontStyle,
                                                        ),
                                                    elevation: 0.0,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ].addToEnd(SizedBox(height: 35.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    logFirebaseEvent(
                                        'PREDICTIONS_SUPPRIMER_LA_DERNIRE_PUBLICA');
                                    logFirebaseEvent('Button_alert_dialog');
                                    var confirmDialogResponse =
                                        await showDialog<bool>(
                                              context: context,
                                              builder: (alertDialogContext) {
                                                return AlertDialog(
                                                  title: Text(
                                                      'Supprimer la dernière prédiction'),
                                                  content: Text(
                                                      'Voulez-vous vraiment supprimer la dernière prédiction ?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              alertDialogContext,
                                                              false),
                                                      child: Text('Fermer'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              alertDialogContext,
                                                              true),
                                                      child: Text('Supprimer'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ) ??
                                            false;
                                    if (confirmDialogResponse) {
                                      logFirebaseEvent('Button_show_snack_bar');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Impossible de supprimmer, veuillez reessayer',
                                            style: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                          duration:
                                              Duration(milliseconds: 4000),
                                          backgroundColor: Color(0xFFFF0000),
                                        ),
                                      );
                                    } else {
                                      logFirebaseEvent(
                                          'Button_close_dialog_drawer_etc');
                                      Navigator.pop(context);
                                    }
                                  },
                                  text: 'Supprimer la dernière publication',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final ae = _model.predictions?.favori
                                              ?.toList() ??
                                          [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(ae.length, (aeIndex) {
                                          final aeItem = ae[aeIndex];
                                          return Text(
                                            aeItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final af = _model.predictions?.soutni
                                              ?.toList() ??
                                          [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(af.length, (afIndex) {
                                          final afItem = af[afIndex];
                                          return Text(
                                            afItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final aa = _model.predictions?.boloto
                                              ?.toList() ??
                                          [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(aa.length, (aaIndex) {
                                          final aaItem = aa[aaIndex];
                                          return Text(
                                            aaItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final ad = _model.predictions?.mariage
                                              ?.toList() ??
                                          [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(ad.length, (adIndex) {
                                          final adItem = ad[adIndex];
                                          return Text(
                                            adItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final ab =
                                          _model.predictions?.chif3?.toList() ??
                                              [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(ab.length, (abIndex) {
                                          final abItem = ab[abIndex];
                                          return Text(
                                            abItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final ac =
                                          _model.predictions?.chif4?.toList() ??
                                              [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(ac.length, (acIndex) {
                                          final acItem = ac[acIndex];
                                          return Text(
                                            acItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final ag =
                                          _model.predictions?.extra?.toList() ??
                                              [];

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(ag.length, (agIndex) {
                                          final agItem = ag[agIndex];
                                          return Text(
                                            agItem,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
