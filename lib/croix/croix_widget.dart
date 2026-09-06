import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/croix_history/croix_history_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'croix_model.dart';
export 'croix_model.dart';

class CroixWidget extends StatefulWidget {
  const CroixWidget({super.key});

  static String routeName = 'croix';
  static String routePath = '/croix';

  @override
  State<CroixWidget> createState() => _CroixWidgetState();
}

class _CroixWidgetState extends State<CroixWidget> {
  late CroixModel _model;
  bool _publishing = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CroixModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'croix'});
    _model.zeroTextController ??= TextEditingController();
    _model.zeroFocusNode ??= FocusNode();

    _model.unTextController ??= TextEditingController();
    _model.unFocusNode ??= FocusNode();

    _model.deuxTextController ??= TextEditingController();
    _model.deuxFocusNode ??= FocusNode();

    _model.troisTextController ??= TextEditingController();
    _model.troisFocusNode ??= FocusNode();

    _model.quatrevideTextController ??= TextEditingController();
    _model.quatrevideFocusNode ??= FocusNode();

    _model.cinqTextController ??= TextEditingController();
    _model.cinqFocusNode ??= FocusNode();

    _model.sixTextController ??= TextEditingController();
    _model.sixFocusNode ??= FocusNode();

    _model.septTextController ??= TextEditingController();
    _model.septFocusNode ??= FocusNode();

    _model.huitTextController ??= TextEditingController();
    _model.huitFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {
          _model.quatrevideTextController?.text = '0';
        }));
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: MediaQuery.sizeOf(context).width < 992
            ? const AdminMobileAppBar(title: 'Croix de la chance')
            : null,
        drawer: MediaQuery.sizeOf(context).width < 992
            ? const Drawer(
                width: 264,
                child: SidenavWidget(forceVisible: true),
              )
            : null,
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 992
            ? AdminMobileBottomBar(
                activeDestination: AdminMobileDestination.more,
                onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.sidenavModel,
                updateCallback: () => safeSetState(() {}),
                child: const SidenavWidget(),
              ),
              Expanded(
                child: Align(
                  alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 1120.0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const AdminSectionHeader(
                          title: 'Croix de la chance',
                          icon: Icons.brightness_7_rounded,
                        ),
                        _buildUpdatePanel(),
                        const SizedBox(height: 16.0),
                        _buildHistoryShortcut(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdatePanel() {
    final theme = FlutterFlowTheme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720.0),
        child: AdminSurface(
          padding: const EdgeInsets.all(16.0),
          radius: 20.0,
          showShadow: true,
          child: Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AdminIconTile(
                      icon: Icons.grid_view_rounded,
                      size: 42.0,
                      iconSize: 21.0,
                      radius: 13.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouvelle mise à jour',
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'La grille reprend exactement la Croix affichée aux utilisateurs.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                _buildCroixRow(
                  first: _buildCroixField(
                    controller: _model.zeroTextController,
                    focusNode: _model.zeroFocusNode,
                    label: '11',
                    validator: _model.zeroTextControllerValidator,
                  ),
                  second: _buildCroixField(
                    controller: _model.unTextController,
                    focusNode: _model.unFocusNode,
                    label: '12',
                    validator: _model.unTextControllerValidator,
                  ),
                  third: _buildCroixField(
                    controller: _model.deuxTextController,
                    focusNode: _model.deuxFocusNode,
                    label: '13',
                    validator: _model.deuxTextControllerValidator,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildCroixRow(
                  first: _buildCroixField(
                    controller: _model.troisTextController,
                    focusNode: _model.troisFocusNode,
                    label: '21',
                    validator: _model.troisTextControllerValidator,
                  ),
                  second: _buildCroixCenterCell(),
                  third: _buildCroixField(
                    controller: _model.cinqTextController,
                    focusNode: _model.cinqFocusNode,
                    label: '22',
                    validator: _model.cinqTextControllerValidator,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildCroixRow(
                  first: _buildCroixField(
                    controller: _model.sixTextController,
                    focusNode: _model.sixFocusNode,
                    label: '31',
                    validator: _model.sixTextControllerValidator,
                  ),
                  second: _buildCroixField(
                    controller: _model.septTextController,
                    focusNode: _model.septFocusNode,
                    label: '32',
                    validator: _model.septTextControllerValidator,
                  ),
                  third: _buildCroixField(
                    controller: _model.huitTextController,
                    focusNode: _model.huitFocusNode,
                    label: '33',
                    validator: _model.huitTextControllerValidator,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(height: 16.0),
                FilledButton.icon(
                  key: const ValueKey('publish-croix'),
                  onPressed: _publishing ? null : _publishCroix,
                  icon: _publishing
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.publish_rounded, size: 20.0),
                  label: Text(
                    _publishing
                        ? 'Publication en cours…'
                        : 'Publier la mise à jour',
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: theme.primary,
                    minimumSize: const Size.fromHeight(48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCroixRow({
    required Widget first,
    required Widget second,
    required Widget third,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 8.0),
        Expanded(child: second),
        const SizedBox(width: 8.0),
        Expanded(child: third),
      ],
    );
  }

  Widget _buildCroixField({
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String label,
    required String? Function(BuildContext, String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: false,
      textAlign: TextAlign.center,
      textInputAction: textInputAction,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      cursorColor: theme.primaryText,
      style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: '#',
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 12.0,
        ),
        filled: true,
        fillColor: theme.primaryBackground,
        labelStyle: theme.labelSmall.copyWith(
          color: theme.secondaryText,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: theme.bodyMedium.copyWith(color: theme.secondaryText),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.alternate),
          borderRadius: BorderRadius.circular(14.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primary, width: 1.7),
          borderRadius: BorderRadius.circular(14.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.error),
          borderRadius: BorderRadius.circular(14.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.error, width: 1.7),
          borderRadius: BorderRadius.circular(14.0),
        ),
        errorStyle: const TextStyle(fontSize: 9.0, height: 0.9),
      ),
      validator:
          validator == null ? null : (value) => validator(context, value),
    );
  }

  Widget _buildCroixCenterCell() {
    final theme = FlutterFlowTheme.of(context);

    return Semantics(
      label: 'Centre fixe de la Croix',
      value: '0',
      child: Container(
        height: 48.0,
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CENTRE',
              style: theme.labelSmall.copyWith(
                color: theme.secondaryText,
                fontSize: 9.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '0',
              style: theme.titleSmall.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishCroix() async {
    if (_publishing) return;

    final controllers = [
      _model.zeroTextController,
      _model.unTextController,
      _model.deuxTextController,
      _model.troisTextController,
      _model.cinqTextController,
      _model.sixTextController,
      _model.septTextController,
      _model.huitTextController,
    ];
    final focusNodes = [
      _model.zeroFocusNode,
      _model.unFocusNode,
      _model.deuxFocusNode,
      _model.troisFocusNode,
      _model.cinqFocusNode,
      _model.sixFocusNode,
      _model.septFocusNode,
      _model.huitFocusNode,
    ];
    final emptyIndex = controllers.indexWhere(
      (controller) => controller == null || controller.text.trim().isEmpty,
    );

    if (emptyIndex >= 0) {
      focusNodes[emptyIndex]?.requestFocus();
      _showCroixMessage(
        'Veuillez renseigner les huit numéros.',
        FlutterFlowTheme.of(context).error,
      );
      return;
    }

    final numbers = [
      controllers[0]!.text.trim(),
      controllers[1]!.text.trim(),
      controllers[2]!.text.trim(),
      controllers[3]!.text.trim(),
      '0',
      controllers[4]!.text.trim(),
      controllers[5]!.text.trim(),
      controllers[6]!.text.trim(),
      controllers[7]!.text.trim(),
    ];
    _model.list = numbers;

    logFirebaseEvent('CROIX_PAGE_UPDATE_BTN_ON_TAP');
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Vérifier la publication',
      message: '${numbers[0]} · ${numbers[1]} · ${numbers[2]}\n'
          '${numbers[3]} · 0 · ${numbers[5]}\n'
          '${numbers[6]} · ${numbers[7]} · ${numbers[8]}',
      confirmLabel: 'Publier',
      icon: Icons.fact_check_outlined,
    );
    if (!mounted) return;

    if (!confirmed) {
      _showCroixMessage(
        'Publication annulée.',
        FlutterFlowTheme.of(context).error,
      );
      return;
    }

    setState(() => _publishing = true);
    try {
      await CroixRecord.collection.doc().set({
        ...createCroixRecordData(createdBy: currentUserUid),
        ...mapToFirestore({
          'date': FieldValue.serverTimestamp(),
          'numeros': numbers,
        }),
      });
      if (!mounted) return;
      setState(() => _publishing = false);
      _showCroixMessage(
        'Mise à jour publiée avec succès.',
        FlutterFlowTheme.of(context).success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      _showCroixMessage(
        'Publication impossible pour le moment. Veuillez réessayer.',
        FlutterFlowTheme.of(context).error,
      );
    }
  }

  void _showCroixMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  Widget _buildHistoryShortcut() {
    final theme = FlutterFlowTheme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(16.0),
      radius: 18.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
            children: [
              const AdminIconTile(
                icon: Icons.history_rounded,
                size: 44.0,
                iconSize: 22.0,
                radius: 14.0,
              ),
              const SizedBox(width: 13.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des publications',
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'Consultez et modifiez les anciennes Croix.',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final openButton = FilledButton.icon(
            onPressed: () => context.pushNamed(CroixHistoryWidget.routeName),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18.0),
            label: const Text('Ouvrir l’historique'),
            style: FilledButton.styleFrom(
              foregroundColor: theme.primaryText,
              backgroundColor: theme.primary,
              minimumSize: const Size(0.0, 44.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          );

          if (constraints.maxWidth < 560.0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 13.0),
                openButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16.0),
              openButton,
            ],
          );
        },
      ),
    );
  }
}
