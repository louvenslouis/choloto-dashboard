import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'official_lottery_results_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'tirages_model.dart';

class TiragesWidget extends StatefulWidget {
  const TiragesWidget({super.key});

  static String routeName = 'tirages';
  static String routePath = '/tirages';

  @override
  State<TiragesWidget> createState() => _TiragesWidgetState();
}

class _TiragesWidgetState extends State<TiragesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final OfficialLotteryResultsService _officialService =
      OfficialLotteryResultsService();

  bool _loadingOfficialResults = true;
  DateTime? _lastOfficialCheck;
  List<OfficialLotteryProposal> _officialProposals = const [];
  List<String> _officialWarnings = const [];
  Set<String> _publishedOfficialIds = const {};
  Set<String> _publishingOfficialIds = const {};

  @override
  void initState() {
    super.initState();
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'tirages'});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOfficialResults();
    });
  }

  @override
  void dispose() {
    _officialService.dispose();
    super.dispose();
  }

  Future<void> _refreshOfficialResults() async {
    if (_loadingOfficialResults && _lastOfficialCheck != null) return;
    safeSetState(() => _loadingOfficialResults = true);
    logFirebaseEvent('TIRAGES_FETCH_OFFICIAL_RESULTS');

    try {
      final result = await _officialService.fetchLatest();
      final warnings = [...result.warnings];
      Set<String> publishedIds;
      try {
        publishedIds = await _findPublishedProposalIds(result.proposals);
      } catch (_) {
        publishedIds = <String>{};
        warnings.add(
          'Les résultats ont été reçus, mais la vérification de l’historique '
          'Firebase a échoué.',
        );
      }
      if (!mounted) return;
      safeSetState(() {
        _officialProposals = result.proposals;
        _officialWarnings = List.unmodifiable(warnings);
        _publishedOfficialIds = publishedIds;
        _lastOfficialCheck = DateTime.now();
        _loadingOfficialResults = false;
      });
    } catch (_) {
      if (!mounted) return;
      safeSetState(() {
        _officialWarnings = const [
          'Les sources officielles sont temporairement indisponibles.',
        ];
        _lastOfficialCheck = DateTime.now();
        _loadingOfficialResults = false;
      });
    }
  }

  Future<Set<String>> _findPublishedProposalIds(
    List<OfficialLotteryProposal> proposals,
  ) async {
    if (proposals.isEmpty) return <String>{};

    final documentSnapshots = await Future.wait(
      proposals.map(
        (proposal) => ResultatsRecord.collection.doc(proposal.documentId).get(),
      ),
    );
    final historyByLottery = await Future.wait([
      queryResultatsRecordOnce(
        queryBuilder: (query) => query.where('tirage', isEqualTo: 'ny'),
      ),
      queryResultatsRecordOnce(
        queryBuilder: (query) => query.where('tirage', isEqualTo: 'fl'),
      ),
    ]);

    final published = <String>{};
    for (var index = 0; index < proposals.length; index++) {
      final proposal = proposals[index];
      final history = proposal.lottery == OfficialLottery.newYork
          ? historyByLottery[0]
          : historyByLottery[1];
      if (documentSnapshots[index].exists ||
          history.any((record) => _matchesProposal(record, proposal))) {
        published.add(proposal.documentId);
      }
    }
    return published;
  }

  bool _matchesProposal(
    ResultatsRecord record,
    OfficialLotteryProposal proposal,
  ) {
    if (record.tirage != proposal.lotteryCode ||
        record.periode != proposal.periodLabel ||
        !listEquals(record.numeros, proposal.numbers)) {
      return false;
    }
    final recordedAt = record.date;
    if (recordedAt == null) return false;
    final difference = recordedAt.difference(proposal.drawDateTime).abs();
    return difference <= const Duration(hours: 18) ||
        (recordedAt.year == proposal.drawDate.year &&
            recordedAt.month == proposal.drawDate.month &&
            recordedAt.day == proposal.drawDate.day);
  }

  Future<bool> _publishOfficialProposal(
    OfficialLotteryProposal proposal,
    List<String> editedNumbers,
  ) async {
    final editedProposal = proposal.copyWithNumbers(editedNumbers);
    final validationError = editedProposal.validateNumbers(editedNumbers);
    if (validationError != null) {
      _showMessage(validationError, error: true);
      return false;
    }
    if (currentUserUid.isEmpty) {
      _showMessage('La session administrateur a expiré.', error: true);
      return false;
    }

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Publier ce tirage officiel ?',
      message: '${editedProposal.lotteryLabel} · '
          '${_formatDate(editedProposal.drawDate)} · '
          '${editedProposal.periodLabel}\n\n'
          '${editedProposal.numbers.join('  ·  ')}\n\n'
          'Ces valeurs seront immédiatement disponibles dans CHOLOTO.',
      confirmLabel: 'Valider et publier',
      icon: Icons.verified_rounded,
    );
    if (!confirmed || !mounted) return false;

    final id = editedProposal.documentId;
    safeSetState(() {
      _publishingOfficialIds = {..._publishingOfficialIds, id};
    });

    try {
      final existingHistory = await queryResultatsRecordOnce(
        queryBuilder: (query) => query.where(
          'tirage',
          isEqualTo: editedProposal.lotteryCode,
        ),
      );
      if (existingHistory
          .any((record) => _matchesProposal(record, editedProposal))) {
        if (mounted) {
          safeSetState(() {
            _publishedOfficialIds = {..._publishedOfficialIds, id};
          });
          _showMessage('Ce tirage est déjà publié dans Firebase.');
        }
        return false;
      }

      final reference = ResultatsRecord.collection.doc(id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        if (existing.exists) {
          throw const _AlreadyPublishedException();
        }
        transaction.set(reference, {
          ...createResultatsRecordData(
            date: editedProposal.drawDateTime,
            periode: editedProposal.periodLabel,
            tirage: editedProposal.lotteryCode,
            createdBy: currentUserUid,
          ),
          ...mapToFirestore({'numeros': editedProposal.numbers}),
        });
      });

      if (!mounted) return true;
      safeSetState(() {
        _publishedOfficialIds = {..._publishedOfficialIds, id};
      });
      _showMessage(
        'Tirage de ${editedProposal.lotteryLabel} publié avec succès.',
      );
      return true;
    } on _AlreadyPublishedException {
      if (mounted) {
        safeSetState(() {
          _publishedOfficialIds = {..._publishedOfficialIds, id};
        });
        _showMessage('Ce tirage est déjà publié dans Firebase.');
      }
      return false;
    } catch (_) {
      if (mounted) {
        _showMessage(
          'La publication a échoué. Vérifie ta connexion et tes droits admin.',
          error: true,
        );
      }
      return false;
    } finally {
      if (mounted) {
        safeSetState(() {
          _publishingOfficialIds = {..._publishingOfficialIds}..remove(id);
        });
      }
    }
  }

  Future<bool> _publishManualResult({
    required OfficialLottery lottery,
    required String period,
    required List<String> numbers,
  }) async {
    final template = OfficialLotteryProposal(
      lottery: lottery,
      period: period ==
              (lottery == OfficialLottery.newYork ? '02:30 PM' : '01:34 PM')
          ? OfficialDrawPeriod.midday
          : OfficialDrawPeriod.evening,
      drawDate: DateTime.now(),
      numbers: numbers,
      sourceName: 'Saisie manuelle',
      sourceUrl: '',
    );
    final error = template.validateNumbers(numbers);
    if (error != null) {
      _showMessage(error, error: true);
      return false;
    }
    if (currentUserUid.isEmpty) {
      _showMessage('La session administrateur a expiré.', error: true);
      return false;
    }

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Publier cette saisie manuelle ?',
      message: '${template.lotteryLabel} · $period\n\n'
          '${numbers.join('  ·  ')}\n\n'
          'Vérifie une dernière fois les numéros avant de continuer.',
      confirmLabel: 'Publier',
      icon: Icons.publish_rounded,
    );
    if (!confirmed || !mounted) return false;

    try {
      await ResultatsRecord.collection.doc().set({
        ...createResultatsRecordData(
          periode: period,
          tirage: template.lotteryCode,
          createdBy: currentUserUid,
        ),
        ...mapToFirestore({
          'date': FieldValue.serverTimestamp(),
          'numeros': numbers,
        }),
      });
      if (!mounted) return true;
      _showMessage(
        'Tirage de ${template.lotteryLabel} publié avec succès.',
      );
      return true;
    } catch (_) {
      if (mounted) {
        _showMessage(
          'La publication a échoué. Vérifie ta connexion et tes droits admin.',
          error: true,
        );
      }
      return false;
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? theme.error : theme.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 992;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: compact ? const AdminMobileAppBar(title: 'Tirages') : null,
      drawer: compact
          ? const Drawer(
              width: 264,
              child: SidenavWidget(forceVisible: true),
            )
          : null,
      bottomNavigationBar: compact
          ? AdminMobileBottomBar(
              activeDestination: AdminMobileDestination.tirages,
              onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      body: SafeArea(
        top: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SidenavWidget(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: RefreshIndicator(
                    onRefresh: _refreshOfficialResults,
                    color: FlutterFlowTheme.of(context).primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const AdminSectionHeader(
                          title: 'Gestion des tirages',
                          icon: Icons.confirmation_number_rounded,
                        ),
                        _OfficialResultsPanel(
                          loading: _loadingOfficialResults,
                          lastChecked: _lastOfficialCheck,
                          proposals: _officialProposals,
                          warnings: _officialWarnings,
                          publishedIds: _publishedOfficialIds,
                          publishingIds: _publishingOfficialIds,
                          onRefresh: _refreshOfficialResults,
                          onPublish: _publishOfficialProposal,
                        ),
                        const SizedBox(height: 22),
                        const _SectionHeading(
                          icon: Icons.edit_note_rounded,
                          title: 'Saisie manuelle',
                          subtitle:
                              'Disponible si une source officielle tarde à répondre.',
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 720;
                            final width = twoColumns
                                ? (constraints.maxWidth - 14) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: _ManualResultCard(
                                    lottery: OfficialLottery.newYork,
                                    onPublish: _publishManualResult,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ManualResultCard(
                                    lottery: OfficialLottery.florida,
                                    onPublish: _publishManualResult,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialResultsPanel extends StatelessWidget {
  const _OfficialResultsPanel({
    required this.loading,
    required this.lastChecked,
    required this.proposals,
    required this.warnings,
    required this.publishedIds,
    required this.publishingIds,
    required this.onRefresh,
    required this.onPublish,
  });

  final bool loading;
  final DateTime? lastChecked;
  final List<OfficialLotteryProposal> proposals;
  final List<String> warnings;
  final Set<String> publishedIds;
  final Set<String> publishingIds;
  final Future<void> Function() onRefresh;
  final Future<bool> Function(
    OfficialLotteryProposal proposal,
    List<String> numbers,
  ) onPublish;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminSurface(
      padding: const EdgeInsets.all(18),
      radius: 20,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final title = Row(
                children: [
                  AdminIconTile(
                    icon: Icons.cloud_download_rounded,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résultats officiels à vérifier',
                          style: theme.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Aucune publication n’est faite sans ta validation.',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final refreshButton = OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Récupérer en ligne'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 14),
                    refreshButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 14),
                  refreshButton,
                ],
              );
            },
          ),
          if (lastChecked != null) ...[
            const SizedBox(height: 12),
            Text(
              'Dernière vérification : '
              '${lastChecked!.hour.toString().padLeft(2, '0')}:'
              '${lastChecked!.minute.toString().padLeft(2, '0')}',
              style: theme.labelSmall.copyWith(color: theme.secondaryText),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Notice(
                  icon: Icons.warning_amber_rounded,
                  text: warning,
                  color: theme.warning,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (loading && proposals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            )
          else if (proposals.isEmpty)
            _Notice(
              icon: Icons.cloud_off_rounded,
              text: 'Aucun résultat officiel complet n’a été reçu.',
              color: theme.secondaryText,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 690;
                final width = twoColumns
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: proposals
                      .map(
                        (proposal) => SizedBox(
                          key: ValueKey(proposal.documentId),
                          width: width,
                          child: _OfficialProposalCard(
                            proposal: proposal,
                            published:
                                publishedIds.contains(proposal.documentId),
                            publishing:
                                publishingIds.contains(proposal.documentId),
                            onPublish: (numbers) =>
                                onPublish(proposal, numbers),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OfficialProposalCard extends StatefulWidget {
  const _OfficialProposalCard({
    required this.proposal,
    required this.published,
    required this.publishing,
    required this.onPublish,
  });

  final OfficialLotteryProposal proposal;
  final bool published;
  final bool publishing;
  final Future<bool> Function(List<String> numbers) onPublish;

  @override
  State<_OfficialProposalCard> createState() => _OfficialProposalCardState();
}

class _OfficialProposalCardState extends State<_OfficialProposalCard> {
  late List<TextEditingController> _controllers;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controllers = widget.proposal.numbers
        .map((number) => TextEditingController(text: number))
        .toList();
  }

  @override
  void didUpdateWidget(covariant _OfficialProposalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal.documentId != widget.proposal.documentId) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers = widget.proposal.numbers
          .map((number) => TextEditingController(text: number))
          .toList();
      _validationError = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final numbers = _controllers.map((controller) => controller.text).toList();
    final error = widget.proposal.validateNumbers(numbers);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() => _validationError = null);
    await widget.onPublish(numbers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final proposal = widget.proposal;
    final edited = !listEquals(
      _controllers.map((controller) => controller.text).toList(),
      proposal.numbers,
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: widget.published
              ? theme.success.withValues(alpha: .38)
              : theme.alternate,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminIconTile(
                icon: proposal.lottery == OfficialLottery.newYork
                    ? Icons.location_city_rounded
                    : Icons.wb_sunny_rounded,
                color: proposal.lottery == OfficialLottery.newYork
                    ? theme.secondary
                    : theme.primary,
                size: 40,
                iconSize: 20,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.lotteryLabel,
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_formatDate(proposal.drawDate)} · '
                      '${proposal.periodLabel}',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusPill(
                label: widget.published ? 'PUBLIÉ' : 'À VÉRIFIER',
                color: widget.published ? theme.success : theme.warning,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _controllers.length,
              (index) => SizedBox(
                width: 96,
                child: _NumberField(
                  controller: _controllers[index],
                  label: proposal.fieldLabels[index],
                  length: proposal.expectedLengths[index],
                  enabled: !widget.published && !widget.publishing,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ),
          if (edited && !widget.published) ...[
            const SizedBox(height: 8),
            Text(
              'Valeurs corrigées manuellement',
              style: theme.labelSmall.copyWith(color: theme.warning),
            ),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationError!,
              style: theme.bodySmall.copyWith(color: theme.error),
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => launchURL(proposal.sourceUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    proposal.sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    widget.published || widget.publishing ? null : _submit,
                icon: widget.publishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.published
                            ? Icons.check_circle_rounded
                            : Icons.verified_rounded,
                        size: 18,
                      ),
                label: Text(widget.published ? 'Publié' : 'Valider'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualResultCard extends StatefulWidget {
  const _ManualResultCard({
    required this.lottery,
    required this.onPublish,
  });

  final OfficialLottery lottery;
  final Future<bool> Function({
    required OfficialLottery lottery,
    required String period,
    required List<String> numbers,
  }) onPublish;

  @override
  State<_ManualResultCard> createState() => _ManualResultCardState();
}

class _ManualResultCardState extends State<_ManualResultCard> {
  late final OfficialLotteryProposal _template;
  late final List<TextEditingController> _controllers;
  late String _period;
  bool _publishing = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _template = OfficialLotteryProposal(
      lottery: widget.lottery,
      period: OfficialDrawPeriod.midday,
      drawDate: DateTime.now(),
      numbers: const [],
      sourceName: 'Saisie manuelle',
      sourceUrl: '',
    );
    _controllers =
        _template.expectedLengths.map((_) => TextEditingController()).toList();
    _period = _template.periodLabel;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final numbers =
        _controllers.map((controller) => controller.text.trim()).toList();
    final error = _template.validateNumbers(numbers);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() {
      _validationError = null;
      _publishing = true;
    });
    final published = await widget.onPublish(
      lottery: widget.lottery,
      period: _period,
      numbers: numbers,
    );
    if (!mounted) return;
    setState(() {
      _publishing = false;
      if (published) {
        for (final controller in _controllers) {
          controller.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final periods = widget.lottery == OfficialLottery.newYork
        ? const ['02:30 PM', '10:30 PM']
        : const ['01:34 PM', '09:49 PM'];

    return AdminSurface(
      padding: const EdgeInsets.all(17),
      radius: 19,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminIconTile(
                icon: widget.lottery == OfficialLottery.newYork
                    ? Icons.location_city_rounded
                    : Icons.wb_sunny_rounded,
                color: widget.lottery == OfficialLottery.newYork
                    ? theme.secondary
                    : theme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _template.lotteryLabel,
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Entrée manuelle',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _controllers.length,
              (index) => SizedBox(
                width: 96,
                child: _NumberField(
                  controller: _controllers[index],
                  label: _template.fieldLabels[index],
                  length: _template.expectedLengths[index],
                  enabled: !_publishing,
                ),
              ),
            ),
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationError!,
              style: theme.bodySmall.copyWith(color: theme.error),
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final periodSelector = SegmentedButton<String>(
                segments: periods
                    .map(
                      (period) => ButtonSegment<String>(
                        value: period,
                        label: Text(period),
                      ),
                    )
                    .toList(),
                selected: {_period},
                onSelectionChanged: _publishing
                    ? null
                    : (selection) {
                        setState(() => _period = selection.first);
                      },
                showSelectedIcon: false,
              );
              final publishButton = FilledButton.icon(
                onPressed: _publishing ? null : _submit,
                icon: _publishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_rounded, size: 18),
                label: const Text('Publier le tirage'),
              );
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    periodSelector,
                    const SizedBox(height: 10),
                    publishButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: periodSelector),
                  const SizedBox(width: 10),
                  publishButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.length,
    required this.enabled,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: List.filled(length, '0').join(),
        counterText: '',
        filled: true,
        fillColor: theme.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: theme.alternate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: theme.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        AdminIconTile(icon: icon, size: 40, iconSize: 20, radius: 12),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.bodySmall.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlreadyPublishedException implements Exception {
  const _AlreadyPublishedException();
}

String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
