import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/components/publication_edit_dialogs.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CroixHistoryWidget extends StatefulWidget {
  const CroixHistoryWidget({super.key});

  static const String routeName = 'croixHistory';
  static const String routePath = '/croix/history';

  @override
  State<CroixHistoryWidget> createState() => _CroixHistoryWidgetState();
}

class _CroixHistoryWidgetState extends State<CroixHistoryWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 992.0;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: compact
          ? const AdminMobileAppBar(title: 'Historique des Croix')
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
                        eyebrow: 'CROIX DE LA CHANCE',
                        dense: true,
                      ),
                      Expanded(
                        child: StreamBuilder<List<CroixRecord>>(
                          stream: queryCroixRecord(
                            queryBuilder: (records) =>
                                records.orderBy('date', descending: true),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _HistoryMessage(
                                icon: Icons.cloud_off_rounded,
                                title: 'Historique indisponible',
                                message:
                                    'Impossible de charger les Croix pour le moment.',
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

  Widget _buildHistory(List<CroixRecord> publications) {
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
                onPressed: () => context.goNamed('croix'),
                icon: const Icon(Icons.arrow_back_rounded, size: 19.0),
                label: const Text('Retour à la publication'),
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
                  message: 'Les prochaines Croix apparaîtront ici.',
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
                        return _CroixHistoryCard(
                          publication: publication,
                          onEdit: () => _editPublication(publication),
                          onDelete: () => _deletePublication(publication),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _editPublication(CroixRecord publication) async {
    logFirebaseEvent('CROIX_HISTORY_EDIT_ON_TAP');
    final saved = await showCroixEditDialog(
      context: context,
      publication: publication,
    );
    if (!saved || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Croix de la Chance modifiée avec succès.',
          ),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
  }

  Future<void> _deletePublication(CroixRecord publication) async {
    logFirebaseEvent('CROIX_HISTORY_DELETE_ON_TAP');
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Supprimer cette Croix ?',
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

class _CroixHistoryCard extends StatelessWidget {
  const _CroixHistoryCard({
    required this.publication,
    required this.onEdit,
    required this.onDelete,
  });

  final CroixRecord publication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final locale = FFLocalizations.of(context).languageCode;
    final filledNumberCount = List.generate(9, (index) => index)
        .where((index) => index != 4)
        .where(
          (index) =>
              index < publication.numeros.length &&
              publication.numeros[index].trim().isNotEmpty,
        )
        .length;

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
                    icon: Icons.brightness_7_rounded,
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
                          'Croix de la chance',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Modifier la publication',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 20.0),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.primary,
                          backgroundColor:
                              theme.primary.withValues(alpha: 0.08),
                          minimumSize: const Size(40.0, 40.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      IconButton(
                        tooltip: 'Supprimer la publication',
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20.0,
                        ),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AdminStatusPill(
                      label: '$filledNumberCount / 8 numéros',
                      color: filledNumberCount == 8
                          ? theme.success
                          : theme.secondaryText,
                      compact: true,
                      leading: Icon(
                        filledNumberCount == 8
                            ? Icons.check_circle_rounded
                            : Icons.grid_view_rounded,
                        size: 12.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  _CroixNumbersGrid(numeros: publication.numeros),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CroixNumbersGrid extends StatelessWidget {
  const _CroixNumbersGrid({required this.numeros});

  static const _positionLabels = [
    '11',
    '12',
    '13',
    '21',
    'Centre',
    '22',
    '31',
    '32',
    '33',
  ];

  final List<String> numeros;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.28,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final isCenter = index == 4;
        final value = index < numeros.length && numeros[index].trim().isNotEmpty
            ? numeros[index].trim()
            : isCenter
                ? '0'
                : '—';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: isCenter
                ? theme.primary.withValues(alpha: 0.15)
                : theme.primaryBackground,
            borderRadius: BorderRadius.circular(13.0),
            border: Border.all(
              color: isCenter
                  ? theme.primary.withValues(alpha: 0.32)
                  : theme.alternate,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _positionLabels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.copyWith(
                  color: theme.secondaryText,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2.0),
              if (isCenter)
                Icon(
                  Icons.brightness_7_rounded,
                  color: theme.primary,
                  size: 24.0,
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.titleMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
