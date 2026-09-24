import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_ui.dart';
import '/components/prediction_card_widget.dart';
import '/components/predictions_history_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late PredictionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _saving = false;
  bool _historyVisited = false;
  int _historyVersion = 0;
  final _formScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PredictionsModel());
    _model.pourcentageValue = 80;
    _model.tabBarController = TabController(vsync: this, length: 2)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _historyVisited = _historyVisited || _model.tabBarCurrentIndex == 1;
          });
        }
      });
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'predictions'});
  }

  @override
  void dispose() {
    _formScrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_saving) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) {
      _formScrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      logFirebaseEvent('PREDICTIONS_PAGE_UPDATE_BTN_ON_TAP');
      logFirebaseEvent('Button_update_page_state');
      _model.predictions = null;
      logFirebaseEvent('Button_show_snack_bar');
      await Future.wait([
        Future(() async {
          // id0
          logFirebaseEvent('Button_id0');
          _model.updatePredictionsStruct(
            (e) => e
              ..updateBoloto(
                (e) => e.insert(0, _model.bolotoModel.id0TextController.text),
              )
              ..updateChif3(
                (e) => e.insert(0, _model.chif3Model.id0TextController.text),
              )
              ..updateChif4(
                (e) => e.insert(0, _model.chif4Model.id0TextController.text),
              )
              ..updateMariage(
                (e) => e.insert(0, _model.mariagesModel.id0TextController.text),
              )
              ..updateFavori(
                (e) => e.insert(0, _model.favorisModel.id0TextController.text),
              )
              ..updateSoutni(
                (e) => e.insert(0, _model.soutniModel.id0TextController.text),
              )
              ..updateExtra(
                (e) => e.insert(0, _model.extraModel.id0TextController.text),
              ),
          );
        }),
        Future(() async {
          // id1
          logFirebaseEvent('Button_id1');
          _model.updatePredictionsStruct(
            (e) => e
              ..updateBoloto(
                (e) => e.insert(1, _model.bolotoModel.id1TextController.text),
              )
              ..updateChif3(
                (e) => e.insert(1, _model.chif3Model.id1TextController.text),
              )
              ..updateChif4(
                (e) => e.insert(1, _model.chif4Model.id1TextController.text),
              )
              ..updateMariage(
                (e) => e.insert(1, _model.mariagesModel.id1TextController.text),
              )
              ..updateFavori(
                (e) => e.insert(1, _model.favorisModel.id1TextController.text),
              )
              ..updateSoutni(
                (e) => e.insert(1, _model.soutniModel.id1TextController.text),
              )
              ..updateExtra(
                (e) => e.insert(1, _model.extraModel.id1TextController.text),
              ),
          );
        }),
        Future(() async {
          // id2
          logFirebaseEvent('Button_id2');
          _model.updatePredictionsStruct(
            (e) => e
              ..updateBoloto(
                (e) => e.insert(2, _model.bolotoModel.id2TextController.text),
              )
              ..updateChif3(
                (e) => e.insert(2, _model.chif3Model.id2TextController.text),
              )
              ..updateChif4(
                (e) => e.insert(2, _model.chif4Model.id2TextController.text),
              )
              ..updateMariage(
                (e) => e.insert(2, _model.mariagesModel.id2TextController.text),
              )
              ..updateFavori(
                (e) => e.insert(2, _model.favorisModel.id2TextController.text),
              )
              ..updateSoutni(
                (e) => e.insert(2, _model.soutniModel.id2TextController.text),
              )
              ..updateExtra(
                (e) => e.insert(2, _model.extraModel.id2TextController.text),
              ),
          );
        }),
        Future(() async {
          // id3
          logFirebaseEvent('Button_id3');
          _model.updatePredictionsStruct(
            (e) => e
              ..updateBoloto(
                (e) => e.insert(3, _model.bolotoModel.id3TextController.text),
              )
              ..updateChif3(
                (e) => e.insert(3, _model.chif3Model.id3TextController.text),
              )
              ..updateChif4(
                (e) => e.insert(3, _model.chif4Model.id3TextController.text),
              )
              ..updateMariage(
                (e) => e.insert(3, _model.mariagesModel.id3TextController.text),
              )
              ..updateFavori(
                (e) => e.insert(3, _model.favorisModel.id3TextController.text),
              )
              ..updateSoutni(
                (e) => e.insert(3, _model.soutniModel.id3TextController.text),
              )
              ..updateExtra(
                (e) => e.insert(3, _model.extraModel.id3TextController.text),
              ),
          );
        }),
      ]);
      var predictionRecordReference = PredictionRecord.collection.doc();
      await predictionRecordReference.set({
        ...createPredictionRecordData(
          boloto: createPredictionsStruct(
            name: 'BOLOTO',
            fieldValues: {
              'boul': _model.predictions?.boloto,
            },
            clearUnsetFields: false,
            create: true,
          ),
          chif3: createPredictionsStruct(
            name: '3 CHIFFRES',
            fieldValues: {
              'boul': _model.predictions?.chif3,
            },
            clearUnsetFields: false,
            create: true,
          ),
          chif4: createPredictionsStruct(
            name: '4 CHIFFRES',
            fieldValues: {
              'boul': _model.predictions?.chif4,
            },
            clearUnsetFields: false,
            create: true,
          ),
          mariage: createPredictionsStruct(
            name: 'MARIAGE',
            fieldValues: {
              'boul': _model.predictions?.mariage,
            },
            clearUnsetFields: false,
            create: true,
          ),
          periode: _model.periodeValue,
          pourcentage: _model.pourcentageValue,
          createdBy: currentUserUid,
          soutni: createPredictionsStruct(
            name: 'SOUTNI',
            fieldValues: {
              'boul': _model.predictions?.soutni,
            },
            clearUnsetFields: false,
            create: true,
          ),
          extra: createPredictionsStruct(
            name: 'EXTRA',
            fieldValues: {
              'boul': _model.predictions?.extra,
            },
            clearUnsetFields: false,
            create: true,
          ),
          favori: createPredictionsStruct(
            name: 'FAVORI',
            fieldValues: {
              'boul': _model.predictions?.favori,
            },
            clearUnsetFields: false,
            create: true,
          ),
        ),
        ...mapToFirestore(
          {
            'date': FieldValue.serverTimestamp(),
          },
        ),
      });
      _model.predictionreference = PredictionRecord.getDocumentFromData({
        ...createPredictionRecordData(
          boloto: createPredictionsStruct(
            name: 'BOLOTO',
            fieldValues: {
              'boul': _model.predictions?.boloto,
            },
            clearUnsetFields: false,
            create: true,
          ),
          chif3: createPredictionsStruct(
            name: '3 CHIFFRES',
            fieldValues: {
              'boul': _model.predictions?.chif3,
            },
            clearUnsetFields: false,
            create: true,
          ),
          chif4: createPredictionsStruct(
            name: '4 CHIFFRES',
            fieldValues: {
              'boul': _model.predictions?.chif4,
            },
            clearUnsetFields: false,
            create: true,
          ),
          mariage: createPredictionsStruct(
            name: 'MARIAGE',
            fieldValues: {
              'boul': _model.predictions?.mariage,
            },
            clearUnsetFields: false,
            create: true,
          ),
          periode: _model.periodeValue,
          pourcentage: _model.pourcentageValue,
          createdBy: currentUserUid,
          soutni: createPredictionsStruct(
            name: 'SOUTNI',
            fieldValues: {
              'boul': _model.predictions?.soutni,
            },
            clearUnsetFields: false,
            create: true,
          ),
          extra: createPredictionsStruct(
            name: 'EXTRA',
            fieldValues: {
              'boul': _model.predictions?.extra,
            },
            clearUnsetFields: false,
            create: true,
          ),
          favori: createPredictionsStruct(
            name: 'FAVORI',
            fieldValues: {
              'boul': _model.predictions?.favori,
            },
            clearUnsetFields: false,
            create: true,
          ),
        ),
        ...mapToFirestore(
          {
            'date': DateTime.now(),
          },
        ),
      }, predictionRecordReference);
      logFirebaseEvent('Button_show_snack_bar');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Prédictions '
            'publiées avec '
            'succès.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );

      setState(() => _historyVersion++);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Publication impossible. Veuillez réessayer.'),
        ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mobile = MediaQuery.sizeOf(context).width < 992;
    final categories = [
      (Predictions.boulFavoris, _model.favorisModel),
      (Predictions.soutni, _model.soutniModel),
      (Predictions.boloto, _model.bolotoModel),
      (Predictions.mariages, _model.mariagesModel),
      (Predictions.chif3, _model.chif3Model),
      (Predictions.chif4, _model.chif4Model),
      (Predictions.extra, _model.extraModel),
    ];
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: mobile ? const AdminMobileAppBar(title: 'Prédictions') : null,
        drawer: mobile
            ? const Drawer(width: 264, child: SidenavWidget(forceVisible: true))
            : null,
        bottomNavigationBar:
            mobile && MediaQuery.viewInsetsOf(context).bottom == 0
                ? AdminMobileBottomBar(
                    activeDestination: AdminMobileDestination.predictions,
                    onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mobile) const SidenavWidget(),
              Expanded(
                child: Column(
                  children: [
                    if (!mobile)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AdminSectionHeader(
                            title: 'Prédictions',
                            icon: Icons.auto_graph_rounded),
                      ),
                    TabBar(
                      controller: _model.tabBarController,
                      labelColor: theme.primaryText,
                      indicatorColor: theme.primary,
                      tabs: const [
                        Tab(text: 'Prédictions'),
                        Tab(text: 'Historique')
                      ],
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _model.tabBarCurrentIndex,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  key: const PageStorageKey('prediction-form'),
                                  controller: _formScrollController,
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 900),
                                      child: AbsorbPointer(
                                        absorbing: _saving,
                                        child: Form(
                                          key: _model.formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              DropdownButtonFormField<String>(
                                                initialValue:
                                                    _model.periodeValue,
                                                isExpanded: true,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: 'Période'),
                                                items: [
                                                  for (final value in [
                                                    'Matin',
                                                    'Midi',
                                                    'Soir'
                                                  ])
                                                    DropdownMenuItem(
                                                        value: value,
                                                        child: Text(value))
                                                ],
                                                onChanged: (value) => setState(
                                                    () => _model.periodeValue =
                                                        value),
                                                validator: (value) => value ==
                                                        null
                                                    ? 'Choisissez une période.'
                                                    : null,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                      child: Text('Pourcentage',
                                                          style:
                                                              theme.bodyLarge)),
                                                  IconButton(
                                                    tooltip:
                                                        'Diminuer le pourcentage',
                                                    onPressed: (_model
                                                                    .pourcentageValue ??
                                                                80) >
                                                            0
                                                        ? () => setState(() => _model
                                                                .pourcentageValue =
                                                            (_model.pourcentageValue ??
                                                                    80) -
                                                                5)
                                                        : null,
                                                    icon: const Icon(
                                                        Icons.remove_rounded),
                                                  ),
                                                  Text(
                                                      '${_model.pourcentageValue} %',
                                                      style: theme.titleMedium),
                                                  IconButton(
                                                    tooltip:
                                                        'Augmenter le pourcentage',
                                                    onPressed: (_model
                                                                    .pourcentageValue ??
                                                                80) <
                                                            100
                                                        ? () => setState(() => _model
                                                                .pourcentageValue =
                                                            (_model.pourcentageValue ??
                                                                    80) +
                                                                5)
                                                        : null,
                                                    icon: const Icon(
                                                        Icons.add_rounded),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              for (final category
                                                  in categories) ...[
                                                wrapWithModel(
                                                  model: category.$2,
                                                  updateCallback: () {},
                                                  child: PredictionCardWidget(
                                                    key: ValueKey(category.$1),
                                                    parameter1: category.$1,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AdminActionBar(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      backgroundColor: theme.primary,
                                      foregroundColor: theme.info,
                                    ),
                                    onPressed: _saving ? null : _publish,
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.publish_rounded),
                                    label: Text(_saving
                                        ? 'Publication…'
                                        : 'Publier les prédictions'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_historyVisited)
                            PredictionsHistoryWidget(
                                key: ValueKey(_historyVersion))
                          else
                            const SizedBox.shrink(),
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
