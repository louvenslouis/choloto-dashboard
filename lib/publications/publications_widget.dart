import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import '/publications_history/publications_history_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'publications_model.dart';

export 'publications_model.dart';

class PublicationsWidget extends StatefulWidget {
  const PublicationsWidget({super.key});

  static String routeName = 'publications';
  static String routePath = '/publications';

  @override
  State<PublicationsWidget> createState() => _PublicationsWidgetState();
}

class _PublicationsWidgetState extends State<PublicationsWidget> {
  static const int _maximumResults = 6;

  static const List<String> _valeurOptions = [
    '1er lot',
    '2e lot',
    '3e lot',
    '2 lots',
    'LOTO 3',
    'LOTO 4',
    '2 Kabès',
    'MARIAGE',
    'BOLOTO',
  ];

  static const List<String> _tirageOptions = [
    'NEW YORK',
    'GEORGIA',
    'FLORIDA',
    'NEW JERSEY',
    'TEXAS',
    'TENNESSEE',
    'MARYLAND',
    'PENNSYLVANIA',
  ];

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final List<_BingoResultDraft> _results = [_BingoResultDraft()];

  late PublicationsModel _model;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PublicationsModel());
    logFirebaseEvent(
      'screen_view',
      parameters: {'screen_name': 'publications'},
    );
  }

  @override
  void dispose() {
    for (final result in _results) {
      result.dispose();
    }
    _model.dispose();
    super.dispose();
  }

  void _addResult() {
    if (_results.length >= _maximumResults) return;
    setState(() => _results.add(_BingoResultDraft()));
  }

  void _removeResult(int index) {
    if (_results.length == 1) return;
    final removed = _results.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _publish() async {
    if (_publishing || !_formKey.currentState!.validate()) return;

    setState(() => _publishing = true);
    final now = getCurrentTimestamp;
    final dataStack = _results.map((result) => result.toStruct()).toList();

    try {
      await BingoRecord.collection.doc().set({
        ...createBingoRecordData(
          date: now,
          expiration: now.add(const Duration(days: 1)),
        ),
        ...mapToFirestore({
          'dataStack': getDataStackListFirestoreData(dataStack),
        }),
      });

      if (!mounted) return;
      for (final result in _results) {
        result.dispose();
      }
      _results
        ..clear()
        ..add(_BingoResultDraft());
      _formKey.currentState?.reset();
      setState(() => _publishing = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('BINGO publié avec succès.'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Publication impossible pour le moment. Veuillez réessayer.',
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 992.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: compact
            ? const AdminMobileAppBar(title: 'Publications BINGO')
            : null,
        drawer: compact
            ? const Drawer(
                width: 264.0,
                child: SidenavWidget(forceVisible: true),
              )
            : null,
        bottomNavigationBar: compact
            ? AdminMobileBottomBar(
                activeDestination: AdminMobileDestination.more,
                onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        body: SafeArea(
          top: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.sidenavModel,
                updateCallback: () => safeSetState(() {}),
                child: const SidenavWidget(),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 1120.0),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const AdminSectionHeader(
                          title: 'Publications BINGO',
                          icon: Icons.newspaper_rounded,
                          dense: true,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 24.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPublicationForm(),
                                const SizedBox(height: 16.0),
                                _buildHistoryShortcut(),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildPublicationForm() {
    final theme = FlutterFlowTheme.of(context);
    final canAdd = _results.length < _maximumResults;

    return AdminSurface(
      padding: const EdgeInsets.all(20.0),
      radius: 20.0,
      showShadow: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final heading = Row(
                  children: [
                    const AdminIconTile(
                      icon: Icons.campaign_rounded,
                      size: 46.0,
                      iconSize: 23.0,
                    ),
                    const SizedBox(width: 13.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouveau BINGO',
                            style: theme.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'Commencez avec un endroit et ajoutez-en jusqu’à six.',
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final counter = AdminStatusPill(
                  key: const ValueKey('bingo-result-counter'),
                  label: '${_results.length} / $_maximumResults',
                  color: theme.primary,
                  leading: const Icon(Icons.place_rounded, size: 14.0),
                );

                if (constraints.maxWidth < 520.0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 12.0),
                      counter,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 16.0),
                    counter,
                  ],
                );
              },
            ),
            const SizedBox(height: 20.0),
            for (var index = 0; index < _results.length; index++) ...[
              _buildResultEditor(index),
              if (index < _results.length - 1) const SizedBox(height: 12.0),
            ],
            const SizedBox(height: 14.0),
            OutlinedButton.icon(
              key: const ValueKey('add-bingo-result'),
              onPressed: _publishing || !canAdd ? null : _addResult,
              icon: Icon(
                canAdd ? Icons.add_rounded : Icons.check_circle_rounded,
                size: 19.0,
              ),
              label: Text(
                canAdd
                    ? 'Ajouter un autre endroit'
                    : 'Limite de six endroits atteinte',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            FilledButton.icon(
              key: const ValueKey('publish-bingo'),
              onPressed: _publishing ? null : _publish,
              icon: _publishing
                  ? const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.publish_rounded, size: 20.0),
              label: Text(
                _publishing ? 'Publication en cours…' : 'Publier le BINGO',
              ),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primary,
                minimumSize: const Size.fromHeight(48.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultEditor(int index) {
    final theme = FlutterFlowTheme.of(context);
    final result = _results[index];

    return AdminSurface(
      key: ValueKey('bingo-result-$index'),
      padding: const EdgeInsets.all(16.0),
      color: theme.primaryBackground,
      radius: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30.0,
                height: 30.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: theme.labelMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'Endroit ${index + 1}',
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_results.length > 1)
                IconButton(
                  key: ValueKey('remove-bingo-result-$index'),
                  tooltip: 'Retirer cet endroit',
                  onPressed: _publishing ? null : () => _removeResult(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: theme.error,
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 600.0;
              final width = twoColumns
                  ? (constraints.maxWidth - 12.0) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  SizedBox(
                    width: width,
                    child: TextFormField(
                      controller: result.numberController,
                      focusNode: result.numberFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Numéro du BINGO',
                        hint: '#',
                        icon: Icons.numbers_rounded,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Le numéro du BINGO est obligatoire.'
                              : null,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildOptionSelector(
                      fieldLabel: 'Valeur',
                      sheetTitle: 'Choisir une valeur',
                      options: _valeurOptions,
                      icon: Icons.apps_rounded,
                      value: result.valeur,
                      onChanged: (value) =>
                          setState(() => result.valeur = value),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildOptionSelector(
                      fieldLabel: 'Nom du tirage',
                      sheetTitle: 'Choisir le nom du tirage',
                      options: _tirageOptions,
                      icon: Icons.location_on_rounded,
                      value: result.tirage,
                      onChanged: (value) =>
                          setState(() => result.tirage = value),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildPeriodSelector(result),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSelector({
    required String fieldLabel,
    required String sheetTitle,
    required List<String> options,
    required IconData icon,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Semantics(
      button: true,
      label: 'Sélectionner $fieldLabel',
      value: value ?? 'Aucune sélection',
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: _publishing
            ? null
            : () async {
                final selectedValue = await showModalBottomSheet<String>(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  backgroundColor: theme.secondaryBackground,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.0),
                    ),
                  ),
                  builder: (sheetContext) {
                    final sheetTheme = FlutterFlowTheme.of(sheetContext);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        16.0,
                        20.0,
                        24.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sheetTitle,
                                  style: sheetTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fermer',
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: options.map((option) {
                              final selected = option == value;
                              return ChoiceChip(
                                label: Text(option),
                                selected: selected,
                                selectedColor: sheetTheme.primary,
                                side: BorderSide(
                                  color: selected
                                      ? sheetTheme.primary
                                      : sheetTheme.alternate,
                                ),
                                labelStyle: GoogleFonts.inter(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                onSelected: (_) =>
                                    Navigator.pop(sheetContext, option),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (selectedValue != null && mounted) {
                  onChanged(selectedValue);
                }
              },
        child: _selectionField(
          label: fieldLabel,
          value: value,
          icon: icon,
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(_BingoResultDraft result) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 56.0),
      padding: const EdgeInsets.fromLTRB(12.0, 7.0, 8.0, 7.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: result.periode == null ? theme.alternate : theme.primary,
          width: result.periode == null ? 1.0 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Période', style: theme.labelSmall),
                Wrap(
                  spacing: 6.0,
                  children: ['Midi', 'Soir'].map((period) {
                    return ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(period),
                      selected: result.periode == period,
                      onSelected: _publishing
                          ? null
                          : (_) => setState(() => result.periode = period),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Icon(
            Icons.schedule_rounded,
            color: result.periode == null ? theme.secondaryText : theme.primary,
            size: 22.0,
          ),
        ],
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: value == null ? theme.alternate : theme.primary,
          width: value == null ? 1.0 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.labelSmall),
                Text(
                  value ?? 'Choisir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(
                    color:
                        value == null ? theme.secondaryText : theme.primaryText,
                    fontWeight:
                        value == null ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: value == null ? theme.secondaryText : theme.primary,
            size: 22.0,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 21.0),
      filled: true,
      fillColor: theme.secondaryBackground,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.alternate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.error, width: 1.5),
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
                      'Consultez et modifiez les anciens BINGO.',
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
            onPressed: () => context.pushNamed(
              PublicationsHistoryWidget.routeName,
            ),
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

class _BingoResultDraft {
  final TextEditingController numberController = TextEditingController();
  final FocusNode numberFocusNode = FocusNode();

  String? valeur;
  String? tirage;
  String? periode;

  DataStackStruct toStruct() => DataStackStruct(
        valeur: valeur,
        tirage: tirage,
        boul: numberController.text.trim(),
        periode: periode,
      );

  void dispose() {
    numberController.dispose();
    numberFocusNode.dispose();
  }
}
