import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/components/publication_edit_dialogs.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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

                    return MasonryGridView.count(
                      crossAxisCount: columnCount,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      padding: const EdgeInsets.only(bottom: 24.0),
                      itemCount: publications.length,
                      itemBuilder: (context, index) {
                        final publication = publications[index];
                        return _PublicationHistoryCard(
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

  Future<void> _editPublication(BingoRecord publication) async {
    logFirebaseEvent('PUBLICATIONS_HISTORY_EDIT_ON_TAP');
    final saved = await showBingoEditDialog(
      context: context,
      publication: publication,
    );
    if (!saved || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'BINGO modifié et republié : le pop-up sera réaffiché.',
          ),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
  }
}

class _PublicationHistoryCard extends StatelessWidget {
  const _PublicationHistoryCard({
    required this.publication,
    required this.onEdit,
    required this.onDelete,
  });

  final BingoRecord publication;
  final VoidCallback onEdit;
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
                            final reactionLabel =
                                '$count réaction${count > 1 ? 's' : ''}';
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Tooltip(
                                message: count > 0
                                    ? 'Voir les utilisateurs ayant réagi'
                                    : 'Aucune réaction',
                                child: Semantics(
                                  button: count > 0,
                                  label: reactionLabel,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10.0),
                                    onTap: count == 0
                                        ? null
                                        : () => _showBingoReactionsDialog(
                                              context,
                                              publication,
                                            ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                        vertical: 5.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                              reactionLabel,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.labelMedium.copyWith(
                                                color: count > 0
                                                    ? theme.primaryText
                                                    : theme.secondaryText,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (count > 0) ...[
                                            const SizedBox(width: 3.0),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 17.0,
                                              color: theme.primary,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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

Future<void> _showBingoReactionsDialog(
  BuildContext context,
  BingoRecord publication,
) async {
  logFirebaseEvent('PUBLICATIONS_HISTORY_REACTIONS_ON_TAP');
  await showDialog<void>(
    context: context,
    builder: (_) => _BingoReactionsDialog(publication: publication),
  );
}

class _BingoReactionsDialog extends StatefulWidget {
  const _BingoReactionsDialog({required this.publication});

  final BingoRecord publication;

  @override
  State<_BingoReactionsDialog> createState() => _BingoReactionsDialogState();
}

class _BingoReactionsDialogState extends State<_BingoReactionsDialog> {
  late Future<List<_BingoReactionEntry>> _reactionsFuture;

  @override
  void initState() {
    super.initState();
    _reactionsFuture = _loadReactions();
  }

  Future<List<_BingoReactionEntry>> _loadReactions() async {
    final reactionRecords = await queryBingostatsRecordOnce(
      parent: widget.publication.reference,
    );

    final reactionsByUser = <String, BingostatsRecord>{};
    for (final reaction in reactionRecords) {
      final userId = reaction.user.trim();
      final key = userId.isEmpty ? '@${reaction.reference.id}' : userId;
      reactionsByUser[key] = reaction;
    }

    final userIds = reactionsByUser.values
        .map((reaction) => reaction.user.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet();
    final userSnapshots = await Future.wait(
      userIds.map((userId) => UserRecord.collection.doc(userId).get()),
    );
    final usersById = <String, UserRecord>{};
    for (final snapshot in userSnapshots) {
      if (snapshot.exists && snapshot.data() != null) {
        usersById[snapshot.id] = UserRecord.fromSnapshot(snapshot);
      }
    }

    final entries = reactionsByUser.values
        .map(
          (reaction) => _BingoReactionEntry(
            reaction: reaction,
            user: usersById[reaction.user.trim()],
          ),
        )
        .toList();
    entries.sort((first, second) {
      if (first.reaction.gain != second.reaction.gain) {
        return first.reaction.gain ? -1 : 1;
      }
      return first.displayName.toLowerCase().compareTo(
            second.displayName.toLowerCase(),
          );
    });
    return entries;
  }

  void _retry() {
    setState(() => _reactionsFuture = _loadReactions());
  }

  @override
  Widget build(BuildContext context) {
    return AdminDialogFrame(
      maxWidth: 620.0,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminDialogHeader(
              title: 'Réactions au BINGO',
              subtitle: 'Utilisateurs ayant réagi à cette publication',
              icon: Icons.favorite_rounded,
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18.0),
            FutureBuilder<List<_BingoReactionEntry>>(
              future: _reactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180.0,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _ReactionDialogMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Réactions indisponibles',
                    message:
                        'Impossible de charger les utilisateurs pour le moment.',
                    actionLabel: 'Réessayer',
                    onAction: _retry,
                  );
                }

                final reactions = snapshot.data ?? const [];
                if (reactions.isEmpty) {
                  return const _ReactionDialogMessage(
                    icon: Icons.favorite_border_rounded,
                    title: 'Aucune réaction',
                    message: 'Aucun utilisateur n’a encore réagi à ce BINGO.',
                  );
                }

                final gains =
                    reactions.where((entry) => entry.reaction.gain).length;
                final misses = reactions.length - gains;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReactionSummary(
                      total: reactions.length,
                      gains: gains,
                      misses: misses,
                    ),
                    const SizedBox(height: 14.0),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9.0),
                      itemBuilder: (context, index) =>
                          _ReactionUserTile(entry: reactions[index]),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BingoReactionEntry {
  const _BingoReactionEntry({
    required this.reaction,
    required this.user,
  });

  final BingostatsRecord reaction;
  final UserRecord? user;

  String get displayName {
    final name = user?.displayName.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Utilisateur indisponible';
  }

  String get subtitle {
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) return email;
    final userId = reaction.user.trim();
    return userId.isEmpty ? 'Profil non disponible' : 'Identifiant : $userId';
  }
}

class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary({
    required this.total,
    required this.gains,
    required this.misses,
  });

  final int total;
  final int gains;
  final int misses;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminSurface(
      padding: const EdgeInsets.all(13.0),
      color: theme.primaryBackground,
      radius: 15.0,
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          AdminStatusPill(
            label: '$total réaction${total > 1 ? 's' : ''}',
            color: theme.primary,
            compact: true,
          ),
          AdminStatusPill(
            label: '$gains gagnant${gains > 1 ? 's' : ''}',
            color: theme.success,
            compact: true,
            leading: const Icon(Icons.emoji_events_rounded, size: 12.0),
          ),
          AdminStatusPill(
            label: '$misses non-gagnant${misses > 1 ? 's' : ''}',
            color: theme.secondaryText,
            compact: true,
            leading: const Icon(Icons.close_rounded, size: 12.0),
          ),
        ],
      ),
    );
  }
}

class _ReactionUserTile extends StatelessWidget {
  const _ReactionUserTile({required this.entry});

  final _BingoReactionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final won = entry.reaction.gain;
    final reactionColor = won ? theme.success : theme.secondaryText;
    final initial = entry.displayName.characters.first.toUpperCase();
    final photoUrl = entry.user?.photoUrl.trim() ?? '';

    return AdminSurface(
      padding: const EdgeInsets.all(12.0),
      radius: 15.0,
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: photoUrl.isEmpty
                ? Text(
                    initial,
                    style: theme.titleSmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Image.network(
                    photoUrl,
                    width: 44.0,
                    height: 44.0,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initial,
                        style: theme.titleSmall.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          AdminStatusPill(
            label: won ? 'A gagné' : 'N’a pas gagné',
            color: reactionColor,
            compact: true,
            leading: Icon(
              won ? Icons.emoji_events_rounded : Icons.close_rounded,
              size: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionDialogMessage extends StatelessWidget {
  const _ReactionDialogMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminSurface(
      padding: const EdgeInsets.all(20.0),
      color: theme.primaryBackground,
      child: Column(
        children: [
          Icon(icon, size: 34.0, color: theme.secondaryText),
          const SizedBox(height: 10.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14.0),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18.0),
              label: Text(actionLabel!),
            ),
          ],
        ],
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
