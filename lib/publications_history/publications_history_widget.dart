import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';

class PublicationsHistoryWidget extends StatefulWidget {
  const PublicationsHistoryWidget({super.key});

  static const String routeName = 'publicationsHistory';
  static const String routePath = '/publications/history';

  @override
  State<PublicationsHistoryWidget> createState() =>
      _PublicationsHistoryWidgetState();
}

class _PublicationsHistoryWidgetState extends State<PublicationsHistoryWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 992.0;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar:
          compact ? const AdminMobileAppBar(title: 'Historique BINGO') : null,
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
            const SidenavWidget(),
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
                        title: 'Historique des publications',
                        icon: Icons.history_rounded,
                        eyebrow: 'PUBLICATIONS BINGO',
                        dense: true,
                      ),
                      Expanded(
                        child: StreamBuilder<List<BingoRecord>>(
                          stream: queryBingoRecord(
                            queryBuilder: (records) =>
                                records.orderBy('date', descending: true),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _HistoryMessage(
                                icon: Icons.cloud_off_rounded,
                                title: 'Historique indisponible',
                                message:
                                    'Impossible de charger les publications pour le moment.',
                                color: FlutterFlowTheme.of(context).error,
                              );
                            }

                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 34.0,
                                  height: 34.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              );
                            }

                            return _buildHistory(snapshot.data!);
                          },
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
    );
  }

  Widget _buildHistory(List<BingoRecord> publications) {
    final theme = FlutterFlowTheme.of(context);
    final publicationLabel =
        '${publications.length} publication${publications.length > 1 ? 's' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.goNamed('publications'),
                icon: const Icon(Icons.arrow_back_rounded, size: 19.0),
                label: const Text('Retour aux publications'),
              ),
              const Spacer(),
              AdminStatusPill(
                label: publicationLabel,
                color: theme.primary,
                compact: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: publications.isEmpty
              ? _HistoryMessage(
                  icon: Icons.inbox_outlined,
                  title: 'Aucune publication',
                  message: 'Les prochains résultats apparaîtront ici.',
                  color: theme.secondaryText,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columnCount = constraints.maxWidth >= 900.0
                        ? 3
                        : constraints.maxWidth >= 600.0
                            ? 2
                            : 1;
                    const spacing = 16.0;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (columnCount - 1)) /
                            columnCount;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: publications
                            .map(
                              (publication) => SizedBox(
                                width: cardWidth,
                                child: _PublicationHistoryCard(
                                  publication: publication,
                                  onDelete: () =>
                                      _deletePublication(publication),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _deletePublication(BingoRecord publication) async {
    logFirebaseEvent('PUBLICATIONS_HISTORY_delete_ICN_ON_TAP');
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Supprimer ce BINGO ?',
      message: 'Cette publication sera supprimée définitivement.',
      confirmLabel: 'Supprimer',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );

    if (confirmed) {
      await publication.reference.delete();
    }
  }
}

class _PublicationHistoryCard extends StatelessWidget {
  const _PublicationHistoryCard({
    required this.publication,
    required this.onDelete,
  });

  final BingoRecord publication;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final locale = FFLocalizations.of(context).languageCode;
    final expiration = publication.expiration;
    final isActive = expiration?.isAfter(DateTime.now()) ?? false;
    final statusLabel = expiration == null
        ? 'Publiée'
        : isActive
            ? 'Active'
            : 'Expirée';
    final statusColor = expiration == null
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
                  const AdminIconTile(
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
                    onPressed: onDelete,
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
                      _PublicationResult(result: publication.dataStack[index]),
                    ],
                  const SizedBox(height: 15.0),
                  Divider(height: 1.0, color: theme.alternate),
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

                            final count = snapshot.data!;
                            return Row(
                              children: [
                                Icon(
                                  count > 0
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16.0,
                                  color: count > 0
                                      ? theme.error
                                      : theme.secondaryText,
                                ),
                                const SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    '$count réaction${count > 1 ? 's' : ''}',
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
}

class _PublicationResult extends StatelessWidget {
  const _PublicationResult({required this.result});

  final DataStackStruct result;

  @override
  Widget build(BuildContext context) {
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
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Center(
      child: AdminSurface(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminIconTile(
              icon: icon,
              color: color,
              size: 48.0,
              iconSize: 24.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              title,
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
