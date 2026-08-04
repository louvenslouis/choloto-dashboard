import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
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
  late Future<List<int>> _countsFuture;
  late Future<List<ResultatsRecord>> _recentResultsFuture;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
    _loadData();
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'Dashboard'});
  }

  void _loadData() {
    _countsFuture = Future.wait([
      queryUserRecordCount(),
      queryResultatsRecordCount(),
      queryPredictionRecordCount(),
      queryBingoRecordCount(),
    ]);
    _recentResultsFuture = queryResultatsRecordOnce(
      queryBuilder: (query) => query.orderBy('date', descending: true),
      limit: 5,
    );
  }

  void _refresh() {
    setState(_loadData);
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
                          _WelcomeBanner(
                            onPrimaryAction: () =>
                                context.goNamed(TiragesWidget.routeName),
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<List<int>>(
                            future: _countsFuture,
                            builder: (context, snapshot) {
                              final values = snapshot.data;
                              final loading = snapshot.connectionState ==
                                  ConnectionState.waiting;
                              return _StatsGrid(
                                loading: loading,
                                stats: [
                                  _StatData(
                                    'Utilisateurs',
                                    values?[0],
                                    Icons.people_alt_rounded,
                                    const Color(0xFF3A7CA5),
                                    UsersWidget.routeName,
                                  ),
                                  _StatData(
                                    'Tirages publiés',
                                    values?[1],
                                    Icons.confirmation_number_rounded,
                                    theme.secondary,
                                    TiragesWidget.routeName,
                                  ),
                                  _StatData(
                                    'Prédictions',
                                    values?[2],
                                    Icons.auto_graph_rounded,
                                    const Color(0xFF6D5BD0),
                                    PredictionsWidget.routeName,
                                  ),
                                  _StatData(
                                    'Publications BINGO',
                                    values?[3],
                                    Icons.newspaper_rounded,
                                    const Color(0xFFE34D59),
                                    PublicationsWidget.routeName,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stack = constraints.maxWidth < 780;
                              final activity = _ActivityPanel(
                                resultsFuture: _recentResultsFuture,
                              );
                              final actions = const _QuickActions();
                              if (stack) {
                                return Column(
                                  children: [
                                    activity,
                                    const SizedBox(height: 18),
                                    actions,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: activity),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 3, child: actions),
                                ],
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
          if (!isDesktop) ...[
            IconButton(
              tooltip: 'Ouvrir le menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 4),
          ],
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

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.onPrimaryAction});
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17334F), Color(0xFF10243A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10243A).withValues(alpha: .13),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C744).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFF6C744).withValues(alpha: .28),
                  ),
                ),
                child: const Text(
                  'CENTRE DE CONTRÔLE',
                  style: TextStyle(
                    color: Color(0xFFF6C744),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Gérez l’essentiel,\nen toute simplicité.',
                style: theme.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -.65,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC928),
                  foregroundColor: const Color(0xFF10243A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nouveau tirage'),
              ),
            ],
          );

          if (compact) return copy;
          return Row(
            children: [
              Expanded(flex: 3, child: copy),
              const SizedBox(width: 24),
              const Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HeroSummary(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .11)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeroSummaryRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Tirages',
          ),
          SizedBox(height: 12),
          _HeroSummaryRow(
            icon: Icons.people_alt_outlined,
            label: 'Communauté',
          ),
          SizedBox(height: 12),
          _HeroSummaryRow(
            icon: Icons.article_outlined,
            label: 'Publications',
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryRow extends StatelessWidget {
  const _HeroSummaryRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF6C744).withValues(alpha: .14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFFF6C744), size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(
          Icons.check_circle_rounded,
          color: Colors.white.withValues(alpha: .45),
          size: 16,
        ),
      ],
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
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        final gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats
              .map((stat) => SizedBox(
                    width: width,
                    child: _StatCard(stat: stat, loading: loading),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color, this.route);
  final String label;
  final int? value;
  final IconData icon;
  final Color color;
  final String route;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.loading});
  final _StatData stat;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.goNamed(stat.route),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.alternate.withValues(alpha: .75)),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(stat.icon, color: stat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: loading
                          ? Container(
                              key: const ValueKey('loading'),
                              width: 48,
                              height: 22,
                              decoration: BoxDecoration(
                                color: theme.alternate,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          : Text(
                              '${stat.value ?? 0}',
                              key: ValueKey(stat.value),
                              style: theme.headlineMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.bodySmall.copyWith(color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.secondaryText, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.resultsFuture});
  final Future<List<ResultatsRecord>> resultsFuture;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _Panel(
      title: 'Derniers tirages',
      trailing: TextButton(
        onPressed: () => context.goNamed(TiragesWidget.routeName),
        child: const Text('Tout voir'),
      ),
      child: FutureBuilder<List<ResultatsRecord>>(
        future: resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final results = snapshot.data ?? const <ResultatsRecord>[];
          if (results.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        color: theme.secondaryText, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun tirage récent',
                      style:
                          theme.bodyMedium.copyWith(color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: results.asMap().entries.map((entry) {
              final result = entry.value;
              final numbers = result.numeros.isNotEmpty
                  ? result.numeros.take(4).join(' · ')
                  : 'Résultat enregistré';
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.accent1,
                      foregroundColor: theme.primary,
                      child: const Icon(Icons.tag_rounded, size: 19),
                    ),
                    title: Text(
                      result.tirage.isEmpty ? 'Tirage CHOLOTO' : result.tirage,
                      style: theme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      numbers,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.bodySmall.copyWith(color: theme.secondaryText),
                    ),
                    trailing: Text(
                      result.date == null
                          ? '—'
                          : DateFormat('dd/MM').format(result.date!),
                      style: theme.labelMedium
                          .copyWith(color: theme.secondaryText),
                    ),
                  ),
                  if (entry.key != results.length - 1)
                    Divider(height: 1, color: theme.alternate),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Accès rapides',
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
          _ActionTile(
            icon: Icons.play_circle_fill_rounded,
            color: const Color(0xFFE34D59),
            title: 'Mettre à jour YouTube',
            onTap: () => context.goNamed(YoutubeWidget.routeName),
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
    return Container(
      padding: const EdgeInsets.all(20),
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
