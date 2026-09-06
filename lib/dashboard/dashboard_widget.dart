import '/payments/payment_reviews_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'analytics_overview_service.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'Dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  late DashboardModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<_DashboardData> _dashboardFuture;
  late Future<AnalyticsOverview> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
    _loadData();
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'Dashboard'});
  }

  void _loadData({bool forceAnalytics = false}) {
    _dashboardFuture = _queryDashboardData();
    _analyticsFuture = AnalyticsOverviewService.load(
      forceRefresh: forceAnalytics,
    );
  }

  Future<_DashboardData> _queryDashboardData() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final endOfRenewalWindow = now.add(const Duration(days: 7));
    final startOfLast30Days = startOfToday.subtract(const Duration(days: 29));
    final startOfMonth = DateTime(now.year, now.month);
    final startOfNextMonth = DateTime(now.year, now.month + 1);

    final values = await Future.wait<dynamic>([
      queryUserRecordCount(
        queryBuilder: (query) =>
            query.where('end_sub', isGreaterThanOrEqualTo: now),
      ),
      queryUserRecordCount(
        queryBuilder: (query) => query
            .where('end_sub', isGreaterThanOrEqualTo: now)
            .where('end_sub', isLessThanOrEqualTo: endOfRenewalWindow),
      ),
      queryUserRecordCount(
        queryBuilder: (query) => query.where(
          'created_time',
          isGreaterThanOrEqualTo: startOfLast30Days,
        ),
      ),
      queryPaymentTransactionRecordOnce(
        queryBuilder: (query) => query
            .where('created_at', isGreaterThanOrEqualTo: startOfMonth)
            .where('created_at', isLessThan: startOfNextMonth),
      ),
      queryResultatsRecordOnce(
        queryBuilder: (query) => query
            .where('date', isGreaterThanOrEqualTo: startOfToday)
            .where('date', isLessThan: startOfTomorrow),
      ),
      queryPredictionRecordOnce(
        queryBuilder: (query) => query
            .where('date', isGreaterThanOrEqualTo: startOfToday)
            .where('date', isLessThan: startOfTomorrow),
      ),
      queryBingoRecordOnce(
        queryBuilder: (query) =>
            query.where('expiration', isGreaterThanOrEqualTo: now),
      ),
      queryCroixRecordOnce(
        queryBuilder: (query) => query
            .where('date', isGreaterThanOrEqualTo: startOfToday)
            .where('date', isLessThan: startOfTomorrow),
      ),
    ]);

    return _DashboardData(
      activeVipCount: values[0] as int,
      expiringVipCount: values[1] as int,
      newUsersCount: values[2] as int,
      monthlyPayments: values[3] as List<PaymentTransactionRecord>,
      todayResults: values[4] as List<ResultatsRecord>,
      todayPredictions: values[5] as List<PredictionRecord>,
      activeBingos: values[6] as List<BingoRecord>,
      todayCrosses: values[7] as List<CroixRecord>,
    );
  }

  void _refresh() {
    setState(() => _loadData(forceAnalytics: true));
  }

  void _refreshAnalytics() {
    setState(() {
      _analyticsFuture = AnalyticsOverviewService.load(forceRefresh: true);
    });
  }

  void _authorizeAnalytics() {
    setState(() {
      _analyticsFuture = AnalyticsOverviewService.authorizeAndLoad();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 992;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      drawer: isDesktop
          ? null
          : const Drawer(
              width: 264,
              child: SidenavWidget(forceVisible: true),
            ),
      bottomNavigationBar: isDesktop
          ? null
          : AdminMobileBottomBar(
              activeDestination: AdminMobileDestination.dashboard,
              onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wrapWithModel(
              model: _model.sidenavModel,
              updateCallback: () => safeSetState(() {}),
              child: const SidenavWidget(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(),
                color: theme.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _Header(onRefresh: _refresh)),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 36 : 16,
                        8,
                        isDesktop ? 36 : 16,
                        36,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const PendingPaymentRequestsTile(),
                          FutureBuilder<_DashboardData>(
                            future: _dashboardFuture,
                            builder: (context, snapshot) {
                              final data = snapshot.data;
                              final loading = snapshot.connectionState ==
                                  ConnectionState.waiting;
                              if (snapshot.hasError && !loading) {
                                return _DashboardLoadError(onRetry: _refresh);
                              }
                              return Column(
                                children: [
                                  _StatsGrid(
                                    loading: loading,
                                    stats: [
                                      _StatData(
                                        'VIP actifs',
                                        data?.activeVipCount.toString(),
                                        Icons.workspace_premium_rounded,
                                        theme.success,
                                        UsersWidget.routeName,
                                        detail: data == null
                                            ? 'abonnements en cours'
                                            : '${data.expiringVipCount} à renouveler sous 7 jours',
                                      ),
                                      _StatData(
                                        'Nouveaux membres',
                                        data?.newUsersCount.toString(),
                                        Icons.person_add_alt_1_rounded,
                                        const Color(0xFF3A7CA5),
                                        UsersWidget.routeName,
                                        detail: 'sur les 30 derniers jours',
                                      ),
                                      _StatData(
                                        'Paiements ce mois',
                                        data?.monthlyPaymentCount.toString(),
                                        Icons.payments_rounded,
                                        const Color(0xFF6D5BD0),
                                        UsersWidget.routeName,
                                        detail: data?.paymentAmountLabel ??
                                            'montants enregistrés',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  if (data == null)
                                    const _OperationalPanelsLoading()
                                  else
                                    _OperationalPanels(data: data),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<AnalyticsOverview>(
                            future: _analyticsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const _AnalyticsPanelLoading();
                              }
                              if (snapshot.hasError || snapshot.data == null) {
                                return _AnalyticsPanelError(
                                  error: snapshot.error,
                                  onRetry: _refreshAnalytics,
                                  onAuthorize: _authorizeAnalytics,
                                );
                              }
                              return _AnalyticsAudiencePanel(
                                overview: snapshot.data!,
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 992;
    final email =
        currentUserEmail.isEmpty ? 'Administrateur' : currentUserEmail;

    return Padding(
      padding:
          EdgeInsets.fromLTRB(isDesktop ? 36 : 12, 20, isDesktop ? 36 : 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vue d’ensemble',
                  style: theme.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr').format(DateTime.now()),
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Actualiser les données',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(backgroundColor: theme.accent1),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 19,
            backgroundColor: theme.secondary,
            child: Text(
              email.characters.first.toUpperCase(),
              style: theme.titleMedium.copyWith(
                color: const Color(0xFF102A43),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.loading});
  final List<_StatData> stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : constraints.maxWidth >= 330
                    ? 2
                    : 1;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final compactCards = width < 230;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats
              .map((stat) => SizedBox(
                    width: width,
                    height: compactCards ? 128 : null,
                    child: _StatCard(stat: stat, loading: loading),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StatData {
  const _StatData(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.route, {
    this.detail,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  final String route;
  final String? detail;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.loading});
  final _StatData stat;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 230;
        return Material(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.goNamed(stat.route),
            child: Container(
              padding: EdgeInsets.all(compact ? 14 : 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: theme.alternate.withValues(alpha: .75)),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryText.withValues(alpha: .035),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 40 : 46,
                    height: compact ? 40 : 46,
                    decoration: BoxDecoration(
                      color: stat.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(stat.icon, color: stat.color, size: 22),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: loading
                              ? Container(
                                  key: const ValueKey('loading'),
                                  width: 42,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: theme.alternate,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                )
                              : Text(
                                  stat.value ?? '0',
                                  key: ValueKey(stat.value),
                                  style: (compact
                                          ? theme.titleLarge
                                          : theme.headlineMedium)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stat.label,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                            height: 1.15,
                          ),
                        ),
                        if (stat.detail?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 3),
                          Text(
                            stat.detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelSmall.copyWith(
                              color: stat.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!compact)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.secondaryText,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.activeVipCount,
    required this.expiringVipCount,
    required this.newUsersCount,
    required this.monthlyPayments,
    required this.todayResults,
    required this.todayPredictions,
    required this.activeBingos,
    required this.todayCrosses,
  });

  final int activeVipCount;
  final int expiringVipCount;
  final int newUsersCount;
  final List<PaymentTransactionRecord> monthlyPayments;
  final List<ResultatsRecord> todayResults;
  final List<PredictionRecord> todayPredictions;
  final List<BingoRecord> activeBingos;
  final List<CroixRecord> todayCrosses;

  List<PaymentTransactionRecord> get recordedMonthlyPayments {
    final cancelledPaymentPaths = monthlyPayments
        .where(
          (transaction) =>
              transaction.isCancellation &&
              transaction.paymentCancelled &&
              transaction.relatedTransactionRef != null,
        )
        .map((transaction) => transaction.relatedTransactionRef!.path)
        .toSet();
    return monthlyPayments
        .where(
          (transaction) =>
              !transaction.isCancellation &&
              !cancelledPaymentPaths.contains(transaction.reference.path),
        )
        .toList();
  }

  int get monthlyPaymentCount => recordedMonthlyPayments.length;

  static const expectedPredictionPeriods = ['Matin', 'Midi', 'Soir'];

  List<String> get missingPredictionPeriods {
    final published = todayPredictions
        .map((prediction) => prediction.periode.trim().toLowerCase())
        .where((period) => period.isNotEmpty)
        .toSet();
    return expectedPredictionPeriods
        .where((period) => !published.contains(period.toLowerCase()))
        .toList();
  }

  ResultatsRecord? get latestTodayResult {
    if (todayResults.isEmpty) return null;
    return todayResults.reduce((current, candidate) {
      final currentDate =
          current.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final candidateDate =
          candidate.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return candidateDate.isAfter(currentDate) ? candidate : current;
    });
  }

  CroixRecord? get latestTodayCross {
    if (todayCrosses.isEmpty) return null;
    return todayCrosses.reduce((current, candidate) {
      final currentDate =
          current.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final candidateDate =
          candidate.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return candidateDate.isAfter(currentDate) ? candidate : current;
    });
  }

  BingoRecord? get nextExpiringBingo {
    if (activeBingos.isEmpty) return null;
    return activeBingos.reduce((current, candidate) {
      final currentDate = current.expiration ?? DateTime(9999);
      final candidateDate = candidate.expiration ?? DateTime(9999);
      return candidateDate.isBefore(currentDate) ? candidate : current;
    });
  }

  String get paymentAmountLabel {
    final payments = recordedMonthlyPayments;
    if (payments.isEmpty) return 'aucun paiement enregistré';

    final totals = <String, double>{};
    for (final payment in payments) {
      final currency = payment.currency.trim().toUpperCase();
      if (currency.isEmpty || payment.amount == 0) continue;
      totals.update(
        currency,
        (current) => current + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }
    if (totals.isEmpty) return 'montants non renseignés';

    final currencies = totals.keys.toList()
      ..sort((first, second) {
        if (first == 'GDS') return -1;
        if (second == 'GDS') return 1;
        return first.compareTo(second);
      });
    return currencies
        .map((currency) =>
            '${_formatDashboardAmount(totals[currency]!)} $currency')
        .join(' • ');
  }
}

String _formatDashboardAmount(double amount) {
  final format = amount == amount.roundToDouble() ? '#,##0' : '#,##0.00';
  return NumberFormat(format, 'fr').format(amount);
}

class _OperationalPanels extends StatelessWidget {
  const _OperationalPanels({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 860;
        final situation = _TodayPublicationsPanel(data: data);
        const actions = _QuickActions();
        if (stack) {
          return Column(
            children: [
              situation,
              const SizedBox(height: 18),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: situation),
            const SizedBox(width: 18),
            const Expanded(flex: 3, child: actions),
          ],
        );
      },
    );
  }
}

class _TodayPublicationsPanel extends StatelessWidget {
  const _TodayPublicationsPanel({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final result = data.latestTodayResult;
    final missingPeriods = data.missingPredictionPeriods;
    final predictionCount =
        _DashboardData.expectedPredictionPeriods.length - missingPeriods.length;
    final bingo = data.nextExpiringBingo;
    final cross = data.latestTodayCross;

    final rows = [
      _PublicationStatusData(
        title: 'Tirages',
        subtitle: result == null
            ? 'Aucun résultat publié aujourd’hui'
            : _resultSummary(result),
        status: data.todayResults.isEmpty
            ? 'À publier'
            : '${data.todayResults.length} publié${data.todayResults.length > 1 ? 's' : ''}',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFFE6B800),
        statusColor: data.todayResults.isEmpty ? theme.warning : theme.success,
        route: TiragesWidget.routeName,
      ),
      _PublicationStatusData(
        title: 'Prédictions',
        subtitle: missingPeriods.isEmpty
            ? 'Matin, Midi et Soir sont disponibles'
            : 'Manquantes : ${missingPeriods.join(', ')}',
        status: missingPeriods.isEmpty ? 'Complet' : '$predictionCount/3',
        icon: Icons.auto_graph_rounded,
        color: const Color(0xFF6D5BD0),
        statusColor: missingPeriods.isEmpty ? theme.success : theme.warning,
        route: PredictionsWidget.routeName,
      ),
      _PublicationStatusData(
        title: 'BINGO',
        subtitle: bingo?.expiration == null
            ? 'Aucune publication active'
            : 'Expire le ${DateFormat('dd/MM à HH:mm', 'fr').format(bingo!.expiration!)}',
        status: bingo == null ? 'À publier' : 'Actif',
        icon: Icons.newspaper_rounded,
        color: const Color(0xFFE34D59),
        statusColor: bingo == null ? theme.warning : theme.success,
        route: PublicationsWidget.routeName,
      ),
      _PublicationStatusData(
        title: 'Croix de la chance',
        subtitle: cross?.date == null
            ? 'Aucune Croix publiée aujourd’hui'
            : 'Dernière publication à ${DateFormat('HH:mm', 'fr').format(cross!.date!)}',
        status: cross == null ? 'À publier' : 'Publié',
        icon: Icons.brightness_7_rounded,
        color: const Color(0xFF3A7CA5),
        statusColor: cross == null ? theme.warning : theme.success,
        route: CroixWidget.routeName,
      ),
    ];

    return _Panel(
      title: 'Aujourd’hui',
      trailing: AdminStatusPill(
        label:
            '${rows.where((row) => row.statusColor == theme.success).length}/4 prêtes',
        color: rows.every((row) => row.statusColor == theme.success)
            ? theme.success
            : theme.warning,
        compact: true,
      ),
      child: Column(
        children: [
          ...rows.asMap().entries.map((entry) {
            return Column(
              children: [
                _PublicationStatusRow(data: entry.value),
                if (entry.key != rows.length - 1)
                  Divider(height: 1, color: theme.alternate),
              ],
            );
          }),
          Divider(height: 18, color: theme.alternate),
          _AlertsPanel(data: data),
        ],
      ),
    );
  }

  String _resultSummary(ResultatsRecord result) {
    final title =
        result.tirage.trim().isEmpty ? 'Tirage CHOLOTO' : result.tirage;
    final period = result.periode.trim();
    final time = result.date == null
        ? ''
        : DateFormat('HH:mm', 'fr').format(result.date!);
    return [title, period, time].where((value) => value.isNotEmpty).join(' • ');
  }
}

class _PublicationStatusData {
  const _PublicationStatusData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.color,
    required this.statusColor,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;
  final Color statusColor;
  final String route;
}

class _PublicationStatusRow extends StatelessWidget {
  const _PublicationStatusRow({required this.data});

  final _PublicationStatusData data;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.goNamed(data.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              AdminIconTile(
                icon: data.icon,
                color: data.color,
                size: 40,
                iconSize: 20,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminStatusPill(
                label: data.status,
                color: data.statusColor,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final alerts = <_DashboardAlertData>[];
    if (data.expiringVipCount > 0) {
      alerts.add(
        _DashboardAlertData(
          title:
              '${data.expiringVipCount} abonnement${data.expiringVipCount > 1 ? 's' : ''} à renouveler',
          subtitle: 'Échéance dans les 7 prochains jours',
          icon: Icons.event_busy_rounded,
          color: theme.warning,
          route: UsersWidget.routeName,
        ),
      );
    }
    if (data.todayResults.isEmpty) {
      alerts.add(
        _DashboardAlertData(
          title: 'Aucun tirage publié aujourd’hui',
          subtitle: 'Vérifier ou saisir les résultats officiels',
          icon: Icons.confirmation_number_outlined,
          color: theme.error,
          route: TiragesWidget.routeName,
        ),
      );
    }
    final missingPeriods = data.missingPredictionPeriods;
    if (missingPeriods.isNotEmpty) {
      alerts.add(
        _DashboardAlertData(
          title: missingPeriods.length == 3
              ? 'Aucune prédiction publiée'
              : 'Prédictions incomplètes',
          subtitle: 'Manquantes : ${missingPeriods.join(', ')}',
          icon: Icons.auto_graph_rounded,
          color: theme.warning,
          route: PredictionsWidget.routeName,
        ),
      );
    }
    if (data.activeBingos.isEmpty) {
      alerts.add(
        _DashboardAlertData(
          title: 'Aucun BINGO actif',
          subtitle: 'Créer une publication destinée aux abonnés',
          icon: Icons.newspaper_outlined,
          color: theme.warning,
          route: PublicationsWidget.routeName,
        ),
      );
    }
    if (data.todayCrosses.isEmpty) {
      alerts.add(
        _DashboardAlertData(
          title: 'Croix de la chance absente',
          subtitle: 'Aucune publication enregistrée aujourd’hui',
          icon: Icons.brightness_7_outlined,
          color: theme.warning,
          route: CroixWidget.routeName,
        ),
      );
    }

    final allClear = alerts.isEmpty;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const PageStorageKey('dashboard-actions'),
        initiallyExpanded: false,
        enabled: !allClear,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        leading: Icon(
          allClear ? Icons.task_alt_rounded : Icons.notification_important,
          color: allClear ? theme.success : theme.warning,
        ),
        title: Text(
          allClear ? 'Aucune action urgente' : 'Actions à traiter',
          style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          allClear
              ? 'Les publications et abonnements sont à jour.'
              : 'Ouvrir pour voir les éléments incomplets.',
          style: theme.bodySmall.copyWith(color: theme.secondaryText),
        ),
        trailing: AdminStatusPill(
          label: allClear ? 'À jour' : '${alerts.length}',
          color: allClear ? theme.success : theme.warning,
          compact: true,
        ),
        children: alerts.asMap().entries.map((entry) {
          return Column(
            children: [
              _AlertRow(data: entry.value),
              if (entry.key != alerts.length - 1)
                Divider(height: 1, color: theme.alternate),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DashboardAlertData {
  const _DashboardAlertData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.data});

  final _DashboardAlertData data;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.goNamed(data.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationalPanelsLoading extends StatelessWidget {
  const _OperationalPanelsLoading();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'Aujourd’hui',
      child: SizedBox(
        height: 170,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _Panel(
      title: 'Données indisponibles',
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: theme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Impossible de charger les indicateurs du dashboard.',
              style: theme.bodyMedium,
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsAudiencePanel extends StatelessWidget {
  const _AnalyticsAudiencePanel({required this.overview});

  final AnalyticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final summaryMetrics = [
      _AnalyticsMetricData(
        label: 'Actifs maintenant',
        value: '${overview.realtimeActiveUsers}',
        helper: '30 dernières minutes',
        icon: Icons.sensors_rounded,
        color: theme.success,
      ),
      _AnalyticsMetricData(
        label: 'Actifs aujourd’hui',
        value: '${overview.todayActiveUsers}',
        helper: 'utilisateurs uniques',
        icon: Icons.today_rounded,
        color: const Color(0xFF3A7CA5),
      ),
      _AnalyticsMetricData(
        label: 'Actifs sur 30 jours',
        value: '${overview.activeUsers30Days}',
        helper: 'audience mensuelle',
        icon: Icons.groups_rounded,
        color: const Color(0xFFE34D59),
      ),
    ];
    final detailMetrics = [
      _AnalyticsMetricData(
        label: 'Nouveaux aujourd’hui',
        value: '${overview.todayNewUsers}',
        helper: 'premiers utilisateurs',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF6D5BD0),
      ),
      _AnalyticsMetricData(
        label: 'Actifs sur 7 jours',
        value: '${overview.activeUsers7Days}',
        helper: 'audience hebdomadaire',
        icon: Icons.date_range_rounded,
        color: const Color(0xFFE6B800),
      ),
      _AnalyticsMetricData(
        label: 'Durée moyenne',
        value: _formatAnalyticsDuration(
          overview.averageSessionDurationSeconds,
        ),
        helper: 'durée par session',
        icon: Icons.timer_outlined,
        color: const Color(0xFF2F8F83),
      ),
    ];

    return _Panel(
      title: 'Audience',
      trailing: AdminStatusPill(
        label: 'Google Analytics',
        color: theme.success,
        compact: true,
        leading: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: theme.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnalyticsMetricsGrid(metrics: summaryMetrics),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const PageStorageKey('dashboard-analytics-details'),
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              leading: Icon(Icons.insights_rounded, color: theme.primary),
              title: Text(
                'Détails Analytics',
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Nouveaux utilisateurs, durée, tendance et écrans',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
              children: [
                _AnalyticsMetricsGrid(metrics: detailMetrics),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stack = constraints.maxWidth < 760;
                    final trend = _AnalyticsTrendCard(
                      points: overview.dailyActiveUsers,
                    );
                    final screens =
                        _TopScreensCard(screens: overview.topScreens);
                    if (stack) {
                      return Column(
                        children: [
                          trend,
                          const SizedBox(height: 16),
                          screens,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: trend),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: screens),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAnalyticsDuration(double seconds) {
  if (!seconds.isFinite || seconds <= 0) return '0 s';
  final roundedSeconds = seconds.round();
  final minutes = roundedSeconds ~/ 60;
  final remainingSeconds = roundedSeconds % 60;
  if (minutes == 0) return '$remainingSeconds s';
  return '$minutes min ${remainingSeconds.toString().padLeft(2, '0')} s';
}

class _AnalyticsMetricData {
  const _AnalyticsMetricData({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
}

class _AnalyticsMetricsGrid extends StatelessWidget {
  const _AnalyticsMetricsGrid({required this.metrics});

  final List<_AnalyticsMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 3
            : constraints.maxWidth >= 480
                ? 2
                : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _AnalyticsMetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({required this.metric});

  final _AnalyticsMetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: metric.color.withValues(alpha: .13)),
      ),
      child: Row(
        children: [
          AdminIconTile(
            icon: metric.icon,
            color: metric.color,
            size: 42,
            iconSize: 20,
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(
                  metric.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTrendCard extends StatelessWidget {
  const _AnalyticsTrendCard({required this.points});

  final List<AnalyticsDailyActiveUsers> points;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final maxUsers = points.fold<int>(
      0,
      (maximum, point) => max(maximum, point.activeUsers),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activité sur 30 jours',
                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'Pic : $maxUsers',
                style: theme.labelSmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (points.isEmpty)
            SizedBox(
              height: 142,
              child: Center(
                child: Text(
                  'Pas encore de données quotidiennes',
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 116,
              width: double.infinity,
              child: CustomPaint(
                painter: _AnalyticsTrendPainter(
                  points: points,
                  lineColor: const Color(0xFF3A7CA5),
                  gridColor: theme.alternate,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  DateFormat('dd MMM', 'fr').format(points.first.date),
                  style: theme.labelSmall.copyWith(color: theme.secondaryText),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM', 'fr').format(points.last.date),
                  style: theme.labelSmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsTrendPainter extends CustomPainter {
  const _AnalyticsTrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
  });

  final List<AnalyticsDailyActiveUsers> points;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .75)
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maximum = points.fold<int>(
      1,
      (value, point) => max(value, point.activeUsers),
    );
    final firstDate = DateUtils.dateOnly(points.first.date);
    final lastDate = DateUtils.dateOnly(points.last.date);
    final dateSpan = max(1, lastDate.difference(firstDate).inDays);
    final coordinates = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width *
              DateUtils.dateOnly(points[index].date)
                  .difference(firstDate)
                  .inDays /
              dateSpan;
      final ratio = points[index].activeUsers / maximum;
      coordinates.add(Offset(x, size.height - ratio * (size.height - 8)));
    }

    final linePath = Path()..moveTo(coordinates.first.dx, coordinates.first.dy);
    for (final point in coordinates.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    final areaPath = Path.from(linePath)
      ..lineTo(coordinates.last.dx, size.height)
      ..lineTo(coordinates.first.dx, size.height)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            lineColor.withValues(alpha: .25),
            lineColor.withValues(alpha: .015),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      coordinates.last,
      4,
      Paint()..color = lineColor,
    );
    canvas.drawCircle(
      coordinates.last,
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalyticsTrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}

class _TopScreensCard extends StatelessWidget {
  const _TopScreensCard({required this.screens});

  final List<AnalyticsTopScreen> screens;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Écrans les plus consultés',
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (screens.isEmpty)
            SizedBox(
              height: 142,
              child: Center(
                child: Text(
                  'Aucune consultation enregistrée',
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ),
            )
          else
            ...screens.asMap().entries.map((entry) {
              final screen = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: theme.labelSmall.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        screen.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${screen.views} vue${screen.views > 1 ? 's' : ''}',
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AnalyticsPanelLoading extends StatelessWidget {
  const _AnalyticsPanelLoading();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'Audience',
      child: SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _AnalyticsPanelError extends StatelessWidget {
  const _AnalyticsPanelError({
    required this.error,
    required this.onRetry,
    required this.onAuthorize,
  });

  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onAuthorize;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final analyticsError = error is AnalyticsOverviewException
        ? error! as AnalyticsOverviewException
        : null;
    final needsConfiguration = analyticsError?.requiresConfiguration ?? false;
    final needsAuthorization = analyticsError?.requiresAuthorization ?? false;
    return _Panel(
      title: 'Audience',
      trailing: AdminStatusPill(
        label: needsAuthorization
            ? 'Autorisation requise'
            : needsConfiguration
                ? 'Configuration requise'
                : 'Indisponible',
        color: theme.warning,
        compact: true,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.warning.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.warning.withValues(alpha: .16)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.analytics_outlined, color: theme.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        needsAuthorization
                            ? 'Autoriser la lecture de Google Analytics'
                            : needsConfiguration
                                ? 'Vérifier la propriété GA4'
                                : 'Google Analytics est temporairement indisponible',
                        style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        needsAuthorization
                            ? 'Le dashboard demandera uniquement l’accès en lecture à la propriété Analytics CHOLOTO. Aucune clé privée ne sera stockée.'
                            : analyticsError?.message ??
                                'Réessayez dans quelques instants.',
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final retry = TextButton.icon(
              onPressed: needsAuthorization ? onAuthorize : onRetry,
              icon: Icon(
                needsAuthorization
                    ? Icons.admin_panel_settings_outlined
                    : Icons.refresh_rounded,
              ),
              label: Text(
                needsAuthorization ? 'Autoriser Analytics' : 'Réessayer',
              ),
            );
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: retry),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 12),
                retry,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Actions rapides',
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.confirmation_number_rounded,
            color: const Color(0xFFE6B800),
            title: 'Saisir un tirage',
            onTap: () => context.goNamed(TiragesWidget.routeName),
          ),
          _ActionTile(
            icon: Icons.auto_graph_rounded,
            color: const Color(0xFF6D5BD0),
            title: 'Créer une prédiction',
            onTap: () => context.goNamed(PredictionsWidget.routeName),
          ),
          _ActionTile(
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF3A7CA5),
            title: 'Gérer les membres',
            onTap: () => context.goNamed(UsersWidget.routeName),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.secondaryText),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.alternate.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(
            color: theme.primaryText.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                      theme.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
