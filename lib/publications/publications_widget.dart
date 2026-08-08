import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
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
import 'publications_model.dart';
export 'publications_model.dart';

class PublicationsWidget extends StatefulWidget {
  const PublicationsWidget({super.key});

  static String routeName = 'publications';
  static String routePath = '/publications';

  @override
  State<PublicationsWidget> createState() => _PublicationsWidgetState();
}

class _PublicationsWidgetState extends State<PublicationsWidget>
    with TickerProviderStateMixin {
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

  late PublicationsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PublicationsModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'publications'});
    _model.tabBarController = TabController(
      vsync: this,
      length: 1,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    _model.numero1TextController ??= TextEditingController();
    _model.numero1FocusNode ??= FocusNode();

    _model.numero2TextController ??= TextEditingController();
    _model.numero2FocusNode ??= FocusNode();

    _model.numero3TextController ??= TextEditingController();
    _model.numero3FocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _buildValeurSelector({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildOptionSelector(
      fieldLabel: 'Valeur',
      sheetTitle: 'Choisir une valeur',
      options: _valeurOptions,
      icon: Icons.apps_rounded,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildTirageSelector({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildOptionSelector(
      fieldLabel: 'Nom du tirage',
      sheetTitle: 'Choisir le nom du tirage',
      options: _tirageOptions,
      icon: Icons.location_on_rounded,
      value: value,
      onChanged: onChanged,
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
        onTap: () async {
          final selectedValue = await showModalBottomSheet<String>(
            context: context,
            useSafeArea: true,
            backgroundColor: theme.secondaryBackground,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            builder: (sheetContext) {
              final sheetTheme = FlutterFlowTheme.of(sheetContext);

              return Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheetTitle,
                                style: sheetTheme.titleMedium,
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Touchez une option pour la sélectionner.',
                                style: sheetTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: options.map((option) {
                        final isSelected = option == value;

                        return ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          showCheckmark: true,
                          checkmarkColor: sheetTheme.primaryText,
                          selectedColor: sheetTheme.primary,
                          backgroundColor: sheetTheme.secondaryBackground,
                          side: BorderSide(
                            color: isSelected
                                ? sheetTheme.primary
                                : sheetTheme.alternate,
                          ),
                          labelStyle: sheetTheme.bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            letterSpacing: 0.0,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (_) =>
                              Navigator.of(sheetContext).pop(option),
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
        child: Container(
          width: 200.0,
          height: 48.0,
          padding: const EdgeInsetsDirectional.fromSTEB(14.0, 0.0, 12.0, 0.0),
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
                    Text(
                      fieldLabel,
                      style: theme.labelSmall,
                    ),
                    Text(
                      value ?? 'Choisir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight:
                              value == null ? FontWeight.w500 : FontWeight.w700,
                        ),
                        color: value == null
                            ? theme.secondaryText
                            : theme.primaryText,
                        letterSpacing: 0.0,
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
        ),
      ),
    );
  }

  Widget _buildPublicationsSection(List<BingoRecord> publications) {
    final theme = FlutterFlowTheme.of(context);
    final publicationLabel =
        '${publications.length} publication${publications.length > 1 ? 's' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publications récentes',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Les derniers résultats BINGO publiés.',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            AdminStatusPill(
              label: publicationLabel,
              color: theme.primary,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 14.0),
        if (publications.isEmpty)
          AdminSurface(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 28.0,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminIconTile(
                    icon: Icons.inbox_outlined,
                    color: theme.secondaryText,
                    size: 48.0,
                    iconSize: 24.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Aucune publication',
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Les prochains résultats apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 1000.0;
              final columnCount = availableWidth >= 900.0
                  ? 3
                  : availableWidth >= 600.0
                      ? 2
                      : 1;
              const spacing = 16.0;
              final cardWidth =
                  (availableWidth - (spacing * (columnCount - 1))) /
                      columnCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: publications
                    .map(
                      (publication) => SizedBox(
                        width: cardWidth,
                        child: _buildPublicationCard(publication),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPublicationCard(BingoRecord publication) {
    final theme = FlutterFlowTheme.of(context);
    final locale = FFLocalizations.of(context).languageCode;
    final expiration = publication.expiration;
    final isActive = expiration?.isAfter(DateTime.now()) ?? false;
    final hasExpiration = expiration != null;
    final statusLabel = !hasExpiration
        ? 'Publiée'
        : isActive
            ? 'Active'
            : 'Expirée';
    final statusColor = !hasExpiration
        ? theme.primary
        : isActive
            ? theme.success
            : theme.secondaryText;
    final resultCount = publication.dataStack.length;

    return AdminSurface(
      padding: EdgeInsets.zero,
      radius: 20.0,
      showShadow: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 15.0, 12.0, 15.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.12),
                    theme.secondaryBackground,
                  ],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
              ),
              child: Row(
                children: [
                  AdminIconTile(
                    icon: Icons.campaign_rounded,
                    size: 42.0,
                    iconSize: 21.0,
                    radius: 13.0,
                  ),
                  const SizedBox(width: 11.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publication BINGO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13.0,
                              color: theme.secondaryText,
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                publication.date == null
                                    ? 'Date non disponible'
                                    : dateTimeFormat(
                                        'd MMM y • HH:mm',
                                        publication.date,
                                        locale: locale,
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.labelSmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Supprimer la publication',
                    onPressed: () => _deletePublication(publication),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20.0),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.error,
                      backgroundColor: theme.error.withValues(alpha: 0.08),
                      minimumSize: const Size(40.0, 40.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      AdminStatusPill(
                        label: statusLabel,
                        color: statusColor,
                        compact: true,
                        leading: Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      AdminStatusPill(
                        label:
                            '$resultCount résultat${resultCount > 1 ? 's' : ''}',
                        color: theme.secondaryText,
                        compact: true,
                        leading: Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 12.0,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  if (publication.dataStack.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Text(
                        'Aucun résultat enregistré.',
                        textAlign: TextAlign.center,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    )
                  else
                    for (var index = 0;
                        index < publication.dataStack.length;
                        index++) ...[
                      if (index > 0) const SizedBox(height: 9.0),
                      _buildPublicationResult(publication.dataStack[index]),
                    ],
                  const SizedBox(height: 15.0),
                  Divider(
                    height: 1.0,
                    thickness: 1.0,
                    color: theme.alternate,
                  ),
                  const SizedBox(height: 13.0),
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<int>(
                          future: queryBingostatsRecordCount(
                            parent: publication.reference,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14.0,
                                    height: 14.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: theme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 7.0),
                                  Text(
                                    'Réactions',
                                    style: theme.labelSmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final reactionCount = snapshot.data!;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  reactionCount > 0
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16.0,
                                  color: reactionCount > 0
                                      ? theme.error
                                      : theme.secondaryText,
                                ),
                                const SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    '$reactionCount réaction${reactionCount > 1 ? 's' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.labelMedium.copyWith(
                                      color: theme.secondaryText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (expiration != null) ...[
                        const SizedBox(width: 8.0),
                        Flexible(
                          child: Text(
                            '${isActive ? 'Expire' : 'Expirée'} le ${dateTimeFormat('d/M • HH:mm', expiration, locale: locale)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.labelSmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicationResult(DataStackStruct result) {
    final theme = FlutterFlowTheme.of(context);
    final number = result.boul.isEmpty ? '—' : result.boul;
    final drawName =
        result.tirage.isEmpty ? 'Tirage non indiqué' : result.tirage;
    final value = result.valeur.isEmpty ? 'Valeur non indiquée' : result.valeur;

    return Container(
      padding: const EdgeInsets.all(11.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: theme.alternate.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'N°',
                  style: theme.labelSmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    number,
                    style: theme.titleSmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drawName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (result.periode.isNotEmpty) ...[
            const SizedBox(width: 8.0),
            AdminStatusPill(
              label: result.periode,
              color: theme.primary,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deletePublication(BingoRecord publication) async {
    logFirebaseEvent('PUBLICATIONS_PAGE_delete_ICN_ON_TAP');
    logFirebaseEvent('IconButton_alert_dialog');
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Supprimer ce BINGO ?',
      message: 'Cette publication sera supprimée définitivement.',
      confirmLabel: 'Supprimer',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );

    if (confirmed) {
      logFirebaseEvent('IconButton_backend_call');
      await publication.reference.delete();
    }
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
            ? const AdminMobileAppBar(title: 'Publications BINGO')
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
                child: SidenavWidget(),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 1120.0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(),
                    child: Column(
                      children: [
                        const AdminSectionHeader(
                          title: 'Publications BINGO',
                          icon: Icons.newspaper_rounded,
                          dense: true,
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _model.tabBarController,
                            children: [
                              KeepAliveWidgetWrapper(
                                builder: (context) => Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 10.0, 0.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Card(
                                        clipBehavior:
                                            Clip.antiAliasWithSaveLayer,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        elevation: 0.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          side: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                          ),
                                        ),
                                        child: Form(
                                          key: _model.formKey,
                                          autovalidateMode:
                                              AutovalidateMode.disabled,
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'BINGO',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Text(
                                                          '1',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  2.0),
                                                          child: Container(
                                                            width: 200.0,
                                                            child:
                                                                TextFormField(
                                                              controller: _model
                                                                  .numero1TextController,
                                                              focusNode: _model
                                                                  .numero1FocusNode,
                                                              autofocus: false,
                                                              obscureText:
                                                                  false,
                                                              decoration:
                                                                  InputDecoration(
                                                                isDense: true,
                                                                labelText:
                                                                    'Le Numero du Bingo',
                                                                hintText: '#',
                                                                hintStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Color(
                                                                        0xFFF3BF00),
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                errorBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                focusedErrorBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                filled: true,
                                                                fillColor: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              minLines: 1,
                                                              maxLength: 15,
                                                              buildCounter: (context,
                                                                      {required currentLength,
                                                                      required isFocused,
                                                                      maxLength}) =>
                                                                  null,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              cursorColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                              enableInteractiveSelection:
                                                                  false,
                                                              validator: _model
                                                                  .numero1TextControllerValidator
                                                                  .asValidator(
                                                                      context),
                                                            ),
                                                          ),
                                                        ),
                                                        _buildValeurSelector(
                                                          value: _model
                                                              .valeur1Value,
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.valeur1Value =
                                                                      val),
                                                        ),
                                                        _buildTirageSelector(
                                                          value: _model
                                                              .nomtirage1Value,
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.nomtirage1Value =
                                                                      val),
                                                        ),
                                                        FlutterFlowChoiceChips(
                                                          options: [
                                                            ChipData('Midi'),
                                                            ChipData('Soir')
                                                          ],
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.choice1Value =
                                                                      val?.firstOrNull),
                                                          selectedChipStyle:
                                                              ChipStyle(
                                                            backgroundColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .info,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                            iconColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .info,
                                                            iconSize: 16.0,
                                                            elevation: 0.0,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                          ),
                                                          unselectedChipStyle:
                                                              ChipStyle(
                                                            backgroundColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                            iconColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                            iconSize: 16.0,
                                                            elevation: 0.0,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                          ),
                                                          chipSpacing: 8.0,
                                                          rowSpacing: 8.0,
                                                          multiselect: false,
                                                          alignment:
                                                              WrapAlignment
                                                                  .center,
                                                          controller: _model
                                                                  .choice1ValueController ??=
                                                              FormFieldController<
                                                                  List<String>>(
                                                            [],
                                                          ),
                                                          wrapped: true,
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 8.0)),
                                                    ),
                                                    SizedBox(
                                                      height: 128.0,
                                                      child: VerticalDivider(
                                                        thickness: 2.0,
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                      ),
                                                    ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Text(
                                                          '2',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  2.0),
                                                          child: Container(
                                                            width: 200.0,
                                                            child:
                                                                TextFormField(
                                                              controller: _model
                                                                  .numero2TextController,
                                                              focusNode: _model
                                                                  .numero2FocusNode,
                                                              autofocus: false,
                                                              obscureText:
                                                                  false,
                                                              decoration:
                                                                  InputDecoration(
                                                                isDense: true,
                                                                labelText:
                                                                    'Le Numero du Bingo',
                                                                hintText: '#',
                                                                hintStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Color(
                                                                        0xFFF3BF00),
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                errorBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                focusedErrorBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                filled: true,
                                                                fillColor: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              minLines: 1,
                                                              maxLength: 15,
                                                              buildCounter: (context,
                                                                      {required currentLength,
                                                                      required isFocused,
                                                                      maxLength}) =>
                                                                  null,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              cursorColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                              enableInteractiveSelection:
                                                                  false,
                                                              validator: _model
                                                                  .numero2TextControllerValidator
                                                                  .asValidator(
                                                                      context),
                                                            ),
                                                          ),
                                                        ),
                                                        _buildValeurSelector(
                                                          value: _model
                                                              .valeur2Value,
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.valeur2Value =
                                                                      val),
                                                        ),
                                                        _buildTirageSelector(
                                                          value:
                                                              _model.nom2Value,
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.nom2Value =
                                                                      val),
                                                        ),
                                                        Container(
                                                          width: 200.0,
                                                          decoration:
                                                              BoxDecoration(),
                                                          child:
                                                              FlutterFlowChoiceChips(
                                                            options: [
                                                              ChipData('Midi'),
                                                              ChipData('Soir')
                                                            ],
                                                            onChanged: (val) =>
                                                                safeSetState(() =>
                                                                    _model.choice2Value =
                                                                        val?.firstOrNull),
                                                            selectedChipStyle:
                                                                ChipStyle(
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .info,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                              iconColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .info,
                                                              iconSize: 16.0,
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            unselectedChipStyle:
                                                                ChipStyle(
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                              iconColor: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              iconSize: 16.0,
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            chipSpacing: 8.0,
                                                            rowSpacing: 8.0,
                                                            multiselect: false,
                                                            alignment:
                                                                WrapAlignment
                                                                    .center,
                                                            controller: _model
                                                                    .choice2ValueController ??=
                                                                FormFieldController<
                                                                    List<
                                                                        String>>(
                                                              [],
                                                            ),
                                                            wrapped: true,
                                                          ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 8.0)),
                                                    ),
                                                    SizedBox(
                                                      height: 128.0,
                                                      child: VerticalDivider(
                                                        thickness: 2.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Text(
                                                          '3',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  2.0),
                                                          child: Container(
                                                            width: 200.0,
                                                            child:
                                                                TextFormField(
                                                              controller: _model
                                                                  .numero3TextController,
                                                              focusNode: _model
                                                                  .numero3FocusNode,
                                                              autofocus: false,
                                                              obscureText:
                                                                  false,
                                                              decoration:
                                                                  InputDecoration(
                                                                isDense: true,
                                                                labelText:
                                                                    'Le Numero du Bingo',
                                                                hintText: '#',
                                                                hintStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Color(
                                                                        0xFFF3BF00),
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                errorBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                focusedErrorBorder:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24.0),
                                                                ),
                                                                filled: true,
                                                                fillColor: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              minLines: 1,
                                                              maxLength: 15,
                                                              buildCounter: (context,
                                                                      {required currentLength,
                                                                      required isFocused,
                                                                      maxLength}) =>
                                                                  null,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              cursorColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                              enableInteractiveSelection:
                                                                  false,
                                                              validator: _model
                                                                  .numero3TextControllerValidator
                                                                  .asValidator(
                                                                      context),
                                                            ),
                                                          ),
                                                        ),
                                                        _buildValeurSelector(
                                                          value: _model
                                                              .valeur3Value,
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.valeur3Value =
                                                                      val),
                                                        ),
                                                        _buildTirageSelector(
                                                          value:
                                                              _model.nom3Value,
                                                          onChanged: (val) =>
                                                              safeSetState(() =>
                                                                  _model.nom3Value =
                                                                      val),
                                                        ),
                                                        Container(
                                                          width: 200.0,
                                                          decoration:
                                                              BoxDecoration(),
                                                          child:
                                                              FlutterFlowChoiceChips(
                                                            options: [
                                                              ChipData('Midi'),
                                                              ChipData('Soir')
                                                            ],
                                                            onChanged: (val) =>
                                                                safeSetState(() =>
                                                                    _model.choice3Value =
                                                                        val?.firstOrNull),
                                                            selectedChipStyle:
                                                                ChipStyle(
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .info,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                              iconColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .info,
                                                              iconSize: 16.0,
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            unselectedChipStyle:
                                                                ChipStyle(
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                              iconColor: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              iconSize: 16.0,
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            chipSpacing: 8.0,
                                                            rowSpacing: 8.0,
                                                            multiselect: false,
                                                            alignment:
                                                                WrapAlignment
                                                                    .center,
                                                            controller: _model
                                                                    .choice3ValueController ??=
                                                                FormFieldController<
                                                                    List<
                                                                        String>>(
                                                              [],
                                                            ),
                                                            wrapped: true,
                                                          ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 8.0)),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    FFButtonWidget(
                                                      onPressed: () async {
                                                        logFirebaseEvent(
                                                            'PUBLICATIONS_PAGE_UPDATE_BTN_ON_TAP');
                                                        logFirebaseEvent(
                                                            'Button_update_page_state');
                                                        _model.dataStack = [];
                                                        safeSetState(() {});
                                                        await Future.wait([
                                                          Future(() async {
                                                            logFirebaseEvent(
                                                                'Button_update_page_state');
                                                            _model.insertAtIndexInDataStack(
                                                                0,
                                                                DataStackStruct(
                                                                  valeur: _model
                                                                      .valeur1Value,
                                                                  tirage: _model
                                                                      .nomtirage1Value,
                                                                  boul: _model
                                                                      .numero1TextController
                                                                      .text,
                                                                  periode: _model
                                                                      .choice1Value,
                                                                ));
                                                            safeSetState(() {});
                                                          }),
                                                          Future(() async {
                                                            if (_model
                                                                    .valeur2Value !=
                                                                null) {
                                                              logFirebaseEvent(
                                                                  'Button_update_page_state');
                                                              _model.insertAtIndexInDataStack(
                                                                  1,
                                                                  DataStackStruct(
                                                                    valeur: _model
                                                                        .valeur2Value,
                                                                    tirage: _model
                                                                        .nom2Value,
                                                                    boul: _model
                                                                        .numero2TextController
                                                                        .text,
                                                                    periode: _model
                                                                        .choice2Value,
                                                                  ));
                                                              safeSetState(
                                                                  () {});
                                                            }
                                                          }),
                                                          Future(() async {
                                                            if (_model
                                                                    .valeur3Value !=
                                                                null) {
                                                              logFirebaseEvent(
                                                                  'Button_update_page_state');
                                                              _model.insertAtIndexInDataStack(
                                                                  2,
                                                                  DataStackStruct(
                                                                    valeur: _model
                                                                        .valeur3Value,
                                                                    tirage: _model
                                                                        .nom3Value,
                                                                    boul: _model
                                                                        .numero3TextController
                                                                        .text,
                                                                    periode: _model
                                                                        .choice3Value,
                                                                  ));
                                                              safeSetState(
                                                                  () {});
                                                            }
                                                          }),
                                                        ]);
                                                        logFirebaseEvent(
                                                            'Button_update_page_state');
                                                        _model.secondes =
                                                            getCurrentTimestamp
                                                                .secondsSinceEpoch;
                                                        logFirebaseEvent(
                                                            'Button_update_page_state');
                                                        _model.secondes =
                                                            _model.secondes! +
                                                                86400;
                                                        logFirebaseEvent(
                                                            'Button_update_page_state');
                                                        _model.expiration =
                                                            dateTimeFromSecondsSinceEpoch(
                                                                valueOrDefault<
                                                                    int>(
                                                          _model.secondes,
                                                          0,
                                                        ));
                                                        safeSetState(() {});
                                                        logFirebaseEvent(
                                                            'Button_backend_call');

                                                        await BingoRecord
                                                            .collection
                                                            .doc()
                                                            .set({
                                                          ...createBingoRecordData(
                                                            date:
                                                                getCurrentTimestamp,
                                                            expiration: _model
                                                                .expiration,
                                                          ),
                                                          ...mapToFirestore(
                                                            {
                                                              'dataStack':
                                                                  getDataStackListFirestoreData(
                                                                _model
                                                                    .dataStack,
                                                              ),
                                                            },
                                                          ),
                                                        });
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                              context)
                                                            ..hideCurrentSnackBar()
                                                            ..showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'BINGO '
                                                                  'publié avec '
                                                                  'succès.',
                                                                ),
                                                              ),
                                                            );
                                                        }
                                                      },
                                                      text: 'Publier le BINGO',
                                                      options: FFButtonOptions(
                                                        height: 40.0,
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    16.0,
                                                                    0.0,
                                                                    16.0,
                                                                    0.0),
                                                        iconPadding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .interTight(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: Colors
                                                                      .white,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                                ),
                                                        elevation: 0.0,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 20.0)),
                                                ),
                                              ].divide(SizedBox(height: 6.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SafeArea(
                                        child: Container(
                                          width: 1000.0,
                                          decoration: BoxDecoration(),
                                          child:
                                              StreamBuilder<List<BingoRecord>>(
                                            stream: queryBingoRecord(
                                              queryBuilder: (bingoRecord) =>
                                                  bingoRecord.orderBy('date',
                                                      descending: true),
                                              limit: 3,
                                            ),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<BingoRecord>
                                                  wrapBingoRecordList =
                                                  snapshot.data!;

                                              return _buildPublicationsSection(
                                                wrapBingoRecordList,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
}
