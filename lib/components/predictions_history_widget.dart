import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PredictionsHistoryWidget extends StatelessWidget {
  const PredictionsHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1120.0),
        padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 0.0),
        child: StreamBuilder<List<PredictionRecord>>(
          stream: queryPredictionRecord(
            queryBuilder: (records) =>
                records.orderBy('date', descending: true),
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _PredictionHistoryMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Historique indisponible',
                message:
                    'Impossible de charger les prédictions pour le moment.',
                color: theme.error,
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: SizedBox(
                  width: 34.0,
                  height: 34.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    color: theme.primary,
                  ),
                ),
              );
            }

            final publications = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HistoryHeading(publicationCount: publications.length),
                const SizedBox(height: 14.0),
                Expanded(
                  child: publications.isEmpty
                      ? _PredictionHistoryMessage(
                          icon: Icons.auto_graph_rounded,
                          title: 'Aucune prédiction publiée',
                          message:
                              'Les prochaines publications apparaîtront ici.',
                          color: theme.secondaryText,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columnCount = constraints.maxWidth >= 900.0
                                ? 3
                                : constraints.maxWidth >= 600.0
                                    ? 2
                                    : 1;

                            return MasonryGridView.count(
                              crossAxisCount: columnCount,
                              mainAxisSpacing: 16.0,
                              crossAxisSpacing: 16.0,
                              padding: const EdgeInsets.only(bottom: 24.0),
                              itemCount: publications.length,
                              itemBuilder: (context, index) {
                                final publication = publications[index];
                                return _PredictionHistoryCard(
                                  publication: publication,
                                  onDelete: () =>
                                      _deletePublication(context, publication),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deletePublication(
    BuildContext context,
    PredictionRecord publication,
  ) async {
    logFirebaseEvent('PREDICTIONS_HISTORY_DELETE_ON_TAP');
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Supprimer cette prédiction ?',
      message: 'Cette publication sera supprimée définitivement.',
      confirmLabel: 'Supprimer',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await publication.reference.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prédiction supprimée.'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Suppression impossible pour le moment. Veuillez réessayer.',
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }
}

class _HistoryHeading extends StatelessWidget {
  const _HistoryHeading({required this.publicationCount});

  final int publicationCount;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          const AdminIconTile(
            icon: Icons.history_rounded,
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
                  'Dernières publications',
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Les prédictions publiées, de la plus récente à la plus ancienne.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          AdminStatusPill(
            label:
                '$publicationCount publication${publicationCount > 1 ? 's' : ''}',
            color: theme.primary,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _PredictionHistoryCard extends StatelessWidget {
  const _PredictionHistoryCard({
    required this.publication,
    required this.onDelete,
  });

  final PredictionRecord publication;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final locale = FFLocalizations.of(context).languageCode;
    final categories = _categoriesFor(publication);
    final selectionCount = categories.fold<int>(
      0,
      (total, category) => total + category.values.length,
    );

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
                    icon: Icons.insights_rounded,
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
                          'Prédiction publiée',
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
                      if (publication.periode.isNotEmpty)
                        AdminStatusPill(
                          label: publication.periode,
                          color: theme.primary,
                          compact: true,
                          leading: Icon(
                            Icons.wb_twilight_rounded,
                            size: 12.0,
                            color: theme.primary,
                          ),
                        ),
                      if (publication.hasPourcentage())
                        AdminStatusPill(
                          label: '${publication.pourcentage} %',
                          color: theme.success,
                          compact: true,
                          leading: Icon(
                            Icons.percent_rounded,
                            size: 12.0,
                            color: theme.success,
                          ),
                        ),
                      AdminStatusPill(
                        label:
                            '$selectionCount sélection${selectionCount > 1 ? 's' : ''}',
                        color: theme.secondaryText,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  if (categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Text(
                        'Aucune sélection enregistrée.',
                        textAlign: TextAlign.center,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    )
                  else
                    for (var index = 0; index < categories.length; index++) ...[
                      if (index > 0) const SizedBox(height: 9.0),
                      _PredictionCategoryRow(category: categories[index]),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PredictionCategory> _categoriesFor(PredictionRecord record) {
    final categories = <_PredictionCategory>[
      _PredictionCategory(
        label: record.favori.name.isEmpty ? 'FAVORI' : record.favori.name,
        icon: Icons.star_rounded,
        values: record.favori.boul,
      ),
      _PredictionCategory(
        label: record.soutni.name.isEmpty ? 'SOUTNI' : record.soutni.name,
        icon: Icons.bolt_rounded,
        values: record.soutni.boul,
      ),
      _PredictionCategory(
        label: record.boloto.name.isEmpty ? 'BOLOTO' : record.boloto.name,
        icon: Icons.casino_rounded,
        values: record.boloto.boul,
      ),
      _PredictionCategory(
        label: record.mariage.name.isEmpty ? 'MARIAGE' : record.mariage.name,
        icon: Icons.favorite_rounded,
        values: record.mariage.boul,
      ),
      _PredictionCategory(
        label: record.chif3.name.isEmpty ? '3 CHIFFRES' : record.chif3.name,
        icon: Icons.looks_3_rounded,
        values: record.chif3.boul,
      ),
      _PredictionCategory(
        label: record.chif4.name.isEmpty ? '4 CHIFFRES' : record.chif4.name,
        icon: Icons.looks_4_rounded,
        values: record.chif4.boul,
      ),
      _PredictionCategory(
        label: record.extra.name.isEmpty ? 'EXTRA' : record.extra.name,
        icon: Icons.add_circle_rounded,
        values: record.extra.boul,
      ),
    ];

    return categories
        .map(
          (category) => category.copyWith(
            values: category.values
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(),
          ),
        )
        .where((category) => category.values.isNotEmpty)
        .toList();
  }
}

class _PredictionCategoryRow extends StatelessWidget {
  const _PredictionCategoryRow({required this.category});

  final _PredictionCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 15.0, color: theme.primary),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
              ),
              Text(
                '${category.values.length}',
                style: theme.labelSmall.copyWith(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9.0),
          Wrap(
            spacing: 7.0,
            runSpacing: 7.0,
            children: category.values
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(9.0),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      value,
                      style: theme.labelMedium.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PredictionCategory {
  const _PredictionCategory({
    required this.label,
    required this.icon,
    required this.values,
  });

  final String label;
  final IconData icon;
  final List<String> values;

  _PredictionCategory copyWith({List<String>? values}) {
    return _PredictionCategory(
      label: label,
      icon: icon,
      values: values ?? this.values,
    );
  }
}

class _PredictionHistoryMessage extends StatelessWidget {
  const _PredictionHistoryMessage({
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
