import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/components/paiement_widget.dart';
import '/components/user_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'users_model.dart';

export 'users_model.dart';

class UsersWidget extends StatefulWidget {
  const UsersWidget({super.key});

  static String routeName = 'users';
  static String routePath = '/users';

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState extends State<UsersWidget> {
  late UsersModel _model;
  late Future<List<UserRecord>> _usersFuture;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UsersModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _usersFuture = queryUserRecordOnce();

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'users'});
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool _handleUserListScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final shouldCollapse = notification.metrics.pixels > 20;
    if (shouldCollapse != _isHeaderCollapsed && mounted) {
      setState(() => _isHeaderCollapsed = shouldCollapse);
    }
    return false;
  }

  List<UserRecord> _filteredUsers(List<UserRecord> users) {
    final query = _model.textController?.text.trim().toLowerCase() ?? '';
    final now = DateTime.now();

    return users.where((user) {
      final isVip = user.endSub != null && !user.endSub!.isBefore(now);
      final matchesFilter = switch (_model.filtres) {
        'VIP' => isVip,
        'Gratuit' => !isVip,
        _ => true,
      };
      if (!matchesFilter || query.isEmpty) return matchesFilter;

      return [
        user.displayName,
        user.email,
        user.phoneNumber,
        user.codePersonnel,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _showUser(UserRecord user) async {
    logFirebaseEvent('USERS_CARD_PROFILE_ON_TAP');
    await showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (_) => AdminDialogFrame(
        maxWidth: 560,
        child: UserWidget(infos: user),
      ),
    );
  }

  Future<void> _showPayment(UserRecord user) async {
    logFirebaseEvent('USERS_CARD_PAYMENT_ON_TAP');
    final saved = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) => AdminDialogFrame(
        maxWidth: 560,
        child: PaiementWidget(refUser: user.reference),
      ),
    );

    if (saved == true && mounted) {
      setState(() => _usersFuture = queryUserRecordOnce());
    }
  }

  @override
  Widget build(BuildContext context) {
    final compactNavigation = MediaQuery.sizeOf(context).width < 992;
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: compactNavigation
            ? const AdminMobileAppBar(title: 'Utilisateurs')
            : null,
        drawer: compactNavigation
            ? const Drawer(
                width: 264,
                child: SidenavWidget(forceVisible: true),
              )
            : null,
        bottomNavigationBar: compactNavigation
            ? AdminMobileBottomBar(
                activeDestination: AdminMobileDestination.users,
                onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compactNavigation)
                SizedBox(
                  height: double.infinity,
                  child: wrapWithModel(
                    model: _model.sidenavModel,
                    updateCallback: () => safeSetState(() {}),
                    child: const SidenavWidget(),
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<UserRecord>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _UsersErrorState(
                        onRetry: () => setState(
                          () => _usersFuture = queryUserRecordOnce(),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allUsers = snapshot.data!;
                    final users = _filteredUsers(allUsers);
                    final vipCount = allUsers
                        .where(
                          (user) =>
                              user.endSub != null &&
                              !user.endSub!.isBefore(DateTime.now()),
                        )
                        .length;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compactNavigation ? 16 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedCrossFade(
                            firstChild: const AdminSectionHeader(
                              title: 'Utilisateurs',
                              icon: Icons.people_alt_rounded,
                            ),
                            secondChild: const SizedBox(width: double.infinity),
                            crossFadeState: _isHeaderCollapsed
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 220),
                            sizeCurve: Curves.easeOutCubic,
                          ),
                          _UsersToolbar(
                            controller: _model.textController!,
                            focusNode: _model.textFieldFocusNode!,
                            selectedFilter: _model.filtres,
                            totalCount: allUsers.length,
                            vipCount: vipCount,
                            resultCount: users.length,
                            onQueryChanged: (_) => setState(() {}),
                            onClearQuery: () {
                              _model.textController!.clear();
                              setState(() {});
                            },
                            onFilterChanged: (filter) {
                              setState(() => _model.filtres = filter);
                            },
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: users.isEmpty
                                ? _UsersEmptyState(
                                    hasSearch: _model.textController!.text
                                        .trim()
                                        .isNotEmpty,
                                    onReset: () {
                                      _model.textController!.clear();
                                      setState(() => _model.filtres = 'Tout');
                                    },
                                  )
                                : NotificationListener<ScrollNotification>(
                                    onNotification: _handleUserListScroll,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final cardWidth =
                                            constraints.maxWidth < 720
                                                ? constraints.maxWidth
                                                : constraints.maxWidth < 1160
                                                    ? 360.0
                                                    : 380.0;

                                        return GridView.builder(
                                          padding: const EdgeInsets.only(
                                            bottom: 28,
                                          ),
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          gridDelegate:
                                              SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: cardWidth,
                                            mainAxisExtent: 356,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                          ),
                                          itemCount: users.length,
                                          itemBuilder: (context, index) {
                                            final user = users[index];
                                            return _UserCard(
                                              user: user,
                                              onViewProfile: () =>
                                                  _showUser(user),
                                              onAddPayment: () =>
                                                  _showPayment(user),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  const _UsersToolbar({
    required this.controller,
    required this.focusNode,
    required this.selectedFilter,
    required this.totalCount,
    required this.vipCount,
    required this.resultCount,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String selectedFilter;
  final int totalCount;
  final int vipCount;
  final int resultCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;
          final search = TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Rechercher un utilisateur',
              hintText: 'Nom, e-mail, téléphone ou code',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: onClearQuery,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: theme.primaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.alternate),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.alternate),
              ),
            ),
          );

          final filters = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous',
                  count: totalCount,
                  selected: selectedFilter == 'Tout',
                  onSelected: () => onFilterChanged('Tout'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'VIP',
                  count: vipCount,
                  selected: selectedFilter == 'VIP',
                  onSelected: () => onFilterChanged('VIP'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Gratuit',
                  count: totalCount - vipCount,
                  selected: selectedFilter == 'Gratuit',
                  onSelected: () => onFilterChanged('Gratuit'),
                ),
              ],
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 14),
                filters,
                const SizedBox(height: 12),
                _ResultLabel(count: resultCount),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 16),
                  Flexible(flex: 2, child: filters),
                ],
              ),
              const SizedBox(height: 12),
              _ResultLabel(count: resultCount),
            ],
          );
        },
      ),
    );
  }
}

class _ResultLabel extends StatelessWidget {
  const _ResultLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Icon(Icons.grid_view_rounded, size: 16, color: theme.secondaryText),
        const SizedBox(width: 7),
        Text(
          '$count ${count > 1 ? 'utilisateurs affichés' : 'utilisateur affiché'}',
          style: theme.labelMedium.copyWith(
            color: theme.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      avatar: Container(
        width: 21,
        height: 21,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.secondary.withValues(alpha: .24)
              : theme.primaryBackground,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$count',
          style: theme.labelSmall.copyWith(
            color: selected ? theme.secondary : theme.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      label: Text(label),
      labelStyle: theme.labelMedium.copyWith(
        color: selected ? theme.info : theme.secondaryText,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: theme.primary,
      backgroundColor: theme.primaryBackground,
      side: BorderSide(
        color: selected ? theme.primary : theme.alternate,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

class _UserCard extends StatefulWidget {
  const _UserCard({
    required this.user,
    required this.onViewProfile,
    required this.onAddPayment,
  });

  final UserRecord user;
  final VoidCallback onViewProfile;
  final VoidCallback onAddPayment;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final user = widget.user;
    final name = user.displayName.trim().isEmpty
        ? 'Membre CHOLOTO'
        : user.displayName.trim();
    final email =
        user.email.trim().isEmpty ? 'E-mail non renseigné' : user.email.trim();
    final active =
        user.endSub != null && !user.endSub!.isBefore(DateTime.now());
    final statusColor = active ? theme.success : theme.error;
    final initial = name.characters.first.toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? theme.primary.withValues(alpha: .28)
                : theme.alternate,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryText.withValues(alpha: _hovered ? .10 : .055),
              blurRadius: _hovered ? 28 : 18,
              offset: Offset(0, _hovered ? 12 : 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onViewProfile,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserAvatar(user: user, initial: initial),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            AdminStatusPill(
                              label: active ? 'VIP ACTIF' : 'ACCÈS GRATUIT',
                              color: statusColor,
                              compact: true,
                              leading: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Voir le profil',
                        onPressed: widget.onViewProfile,
                        icon: const Icon(Icons.arrow_outward_rounded, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.primary,
                          backgroundColor: theme.accent1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    value: email,
                    action: user.email.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Copier l’e-mail',
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: user.email),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('E-mail copié.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                  ),
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    value: user.phoneNumber.trim().isEmpty
                        ? 'Téléphone non renseigné'
                        : user.phoneNumber.trim(),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.alternate),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _UserMetric(
                              icon: Icons.event_available_rounded,
                              label: 'Échéance',
                              value: user.endSub == null
                                  ? 'Non définie'
                                  : dateTimeFormat(
                                      'd MMM y',
                                      user.endSub,
                                      locale: FFLocalizations.of(context)
                                          .languageCode,
                                    ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: theme.alternate,
                          ),
                          Expanded(
                            child: _UserMetric(
                              icon: Icons.workspace_premium_outlined,
                              label: 'Mois actifs',
                              value: '${user.memberTime}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onViewProfile,
                          icon: const Icon(Icons.person_outline_rounded,
                              size: 19),
                          label: const Text('Profil'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: BorderSide(color: theme.alternate),
                            foregroundColor: theme.primaryText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onAddPayment,
                          icon: const Icon(Icons.add_card_rounded, size: 19),
                          label: const Text('Paiement'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: theme.primary,
                            foregroundColor: theme.info,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.initial});

  final UserRecord user;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fallback = Center(
      child: Text(
        initial,
        style: theme.titleLarge.copyWith(
          color: theme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: 60,
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.accent1,
        shape: BoxShape.circle,
        border: Border.all(color: theme.secondary, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.primaryText.withValues(alpha: .10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: user.photoUrl.trim().isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: user.photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.value,
    this.action,
  });

  final IconData icon;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: theme.secondaryText),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _UserMetric extends StatelessWidget {
  const _UserMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: theme.primary),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.bodySmall.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState({required this.hasSearch, required this.onReset});

  final bool hasSearch;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AdminSurface(
          padding: const EdgeInsets.all(28),
          radius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminIconTile(
                icon: hasSearch
                    ? Icons.person_search_rounded
                    : Icons.group_off_rounded,
                size: 54,
                iconSize: 27,
                radius: 17,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun utilisateur trouvé',
                style: theme.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                'Modifiez la recherche ou les filtres pour afficher d’autres membres.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersErrorState extends StatelessWidget {
  const _UsersErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 42, color: theme.error),
          const SizedBox(height: 12),
          Text(
            'Impossible de charger les utilisateurs.',
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
