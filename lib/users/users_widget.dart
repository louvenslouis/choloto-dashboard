import 'dart:async';

import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/components/paiement_widget.dart';
import '/components/user_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import '/payments/payment_reviews_widget.dart';
import '/payments/payment_transactions_widget.dart';
import '/payments/payment_request.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_excel_exporter.dart';
import 'user_document_creator.dart';
import 'users_model.dart';

export 'users_model.dart';

enum _UsersViewMode { cards, list }

enum UserSortMode {
  alphabetical,
  lastModified,
  nearestExpiration,
  newestUsers,
}

const newUserBadgeDuration = Duration(days: 6);

bool isNewUser(DateTime? createdAt, DateTime referenceDate) {
  if (createdAt == null) return false;
  final age = referenceDate.difference(createdAt);
  return !age.isNegative && age < newUserBadgeDuration;
}

int compareUserCreationDates(DateTime? first, DateTime? second) {
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return second.compareTo(first);
}

int compareUserExpirationDates(
  DateTime? first,
  DateTime? second,
  DateTime referenceDate,
) {
  int expirationGroup(DateTime? date) {
    if (date == null) return 1;
    return date.isBefore(referenceDate) ? 2 : 0;
  }

  final groupComparison =
      expirationGroup(first).compareTo(expirationGroup(second));
  if (groupComparison != 0) return groupComparison;
  if (first == null || second == null) return 0;

  if (!first.isBefore(referenceDate)) {
    return first.compareTo(second);
  }

  return second.compareTo(first);
}

class UsersWidget extends StatefulWidget {
  const UsersWidget({super.key, this.initialTabIndex = 0});

  static String routeName = 'users';
  static String routePath = '/users';

  /// 0 = Utilisateurs, 1 = Preuves de paiement, 2 = Paiements clients
  final int initialTabIndex;

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState extends State<UsersWidget>
    with TickerProviderStateMixin {
  static const _usersCacheDuration = Duration(days: 7);
  static const _usersCacheTimestampKey =
      'users_full_collection_cache_timestamp_v1';
  static Future<List<UserRecord>>? _cachedUsersFuture;
  static DateTime? _usersCachedAt;

  late UsersModel _model;
  Future<List<UserRecord>>? _usersFuture;
  late TabController _tabController;
  late final Stream<List<PaymentRequest>> _pendingRequestsStream;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isHeaderCollapsed = false;
  _UsersViewMode _viewMode = _UsersViewMode.cards;
  UserSortMode _sortMode = UserSortMode.alphabetical;
  bool _isExporting = false;
  bool _isRefreshingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 0 && _usersFuture == null) {
        _reloadUsers();
        return;
      }
      setState(() {});
    });
    _pendingRequestsStream =
        PaymentRequestRepository().watch(status: 'pending');
    _model = createModel(context, () => UsersModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    if (_tabController.index == 0) {
      _reloadUsers(notifyListeners: false);
    }

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'users'});
  }

  @override
  void didUpdateWidget(UsersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 2));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    final filteredUsers = users.where((user) {
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

    filteredUsers.sort((first, second) => _compareUsers(first, second, now));
    return filteredUsers;
  }

  int _compareUsers(
    UserRecord first,
    UserRecord second,
    DateTime referenceDate,
  ) {
    final alphabeticalComparison = _compareUsersAlphabetically(first, second);
    if (_sortMode == UserSortMode.alphabetical) {
      return alphabeticalComparison;
    }

    if (_sortMode == UserSortMode.nearestExpiration) {
      final expirationComparison = compareUserExpirationDates(
        first.endSub,
        second.endSub,
        referenceDate,
      );
      return expirationComparison == 0
          ? alphabeticalComparison
          : expirationComparison;
    }

    if (_sortMode == UserSortMode.newestUsers) {
      final creationComparison = compareUserCreationDates(
        first.createdTime,
        second.createdTime,
      );
      return creationComparison == 0
          ? alphabeticalComparison
          : creationComparison;
    }

    final firstModified = first.updatedTime ?? first.createdTime;
    final secondModified = second.updatedTime ?? second.createdTime;
    if (firstModified == null && secondModified == null) {
      return alphabeticalComparison;
    }
    if (firstModified == null) return 1;
    if (secondModified == null) return -1;

    final recentFirst = secondModified.compareTo(firstModified);
    return recentFirst == 0 ? alphabeticalComparison : recentFirst;
  }

  int _compareUsersAlphabetically(UserRecord first, UserRecord second) {
    final firstName = first.displayName.trim().isEmpty
        ? first.email.trim()
        : first.displayName.trim();
    final secondName = second.displayName.trim().isEmpty
        ? second.email.trim()
        : second.displayName.trim();
    final nameComparison =
        _alphabeticalKey(firstName).compareTo(_alphabeticalKey(secondName));
    if (nameComparison != 0) return nameComparison;

    return _alphabeticalKey(first.email)
        .compareTo(_alphabeticalKey(second.email));
  }

  String _alphabeticalKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('[ç]'), 'c')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[ñ]'), 'n')
        .replaceAll(RegExp('[òóôõö]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll(RegExp('[ýÿ]'), 'y');
  }

  Future<List<UserRecord>> _loadUsers({bool forceRefresh = false}) {
    final cachedAt = _usersCachedAt;
    final cacheIsFresh = cachedAt != null &&
        DateTime.now().difference(cachedAt) < _usersCacheDuration;
    if (!forceRefresh && cacheIsFresh && _cachedUsersFuture != null) {
      return _cachedUsersFuture!;
    }

    final future = _loadAllUsers(forceRefresh: forceRefresh);
    _cachedUsersFuture = future;
    unawaited(
      future.then<void>(
        (_) {
          if (identical(future, _cachedUsersFuture)) {
            _usersCachedAt = DateTime.now();
          }
        },
        onError: (_) {
          if (identical(future, _cachedUsersFuture)) {
            _cachedUsersFuture = null;
            _usersCachedAt = null;
          }
        },
      ),
    );
    return future;
  }

  Future<List<UserRecord>> _loadAllUsers({required bool forceRefresh}) async {
    final preferences = await SharedPreferences.getInstance();
    final cachedTimestamp = preferences.getInt(_usersCacheTimestampKey);
    final persistentCacheIsFresh = !forceRefresh &&
        cachedTimestamp != null &&
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(cachedTimestamp),
            ) <
            _usersCacheDuration;

    if (persistentCacheIsFresh) {
      try {
        final cachedUsers = await _fetchAllUsers(Source.cache);
        if (cachedUsers.isNotEmpty) return cachedUsers;
      } catch (_) {
        // The local Firestore cache may have been cleared by the browser.
      }
    }

    try {
      final users = await _fetchAllUsers(Source.server);
      await preferences.setInt(
        _usersCacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return users;
    } catch (_) {
      try {
        final cachedUsers = await _fetchAllUsers(Source.cache);
        if (cachedUsers.isNotEmpty) return cachedUsers;
      } catch (_) {
        // Preserve the server error if no cached result is available.
      }
      rethrow;
    }
  }

  Future<List<UserRecord>> _fetchAllUsers(Source source) async {
    final snapshot =
        await UserRecord.collection.get(GetOptions(source: source));
    return snapshot.docs
        .map(
          (document) => safeGet(
            () => UserRecord.fromSnapshot(document),
            (error) => debugPrint(
              'Error serializing user ${document.reference.path}: $error',
            ),
          ),
        )
        .whereType<UserRecord>()
        .toList();
  }

  void _reloadUsers({
    bool notifyListeners = true,
    bool forceRefresh = false,
  }) {
    final usersFuture = _loadUsers(forceRefresh: forceRefresh);

    void updateState() {
      _usersFuture = usersFuture;
    }

    if (notifyListeners) {
      setState(updateState);
    } else {
      updateState();
    }
  }

  Future<void> _refreshUsers() async {
    if (_isRefreshingUsers) return;
    setState(() => _isRefreshingUsers = true);
    _reloadUsers(forceRefresh: true);
    final usersFuture = _usersFuture!;

    try {
      final users = await usersFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${users.length} utilisateurs actualisés.')),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Impossible d’actualiser les utilisateurs.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isRefreshingUsers = false);
    }
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

  Future<void> _showAddUserDialog() async {
    logFirebaseEvent('USERS_ADD_MANUAL_ON_TAP');
    final result = await showDialog<UserDocumentCreationResult>(
      barrierDismissible: false,
      context: context,
      builder: (_) => AdminDialogFrame(
        maxWidth: 480,
        scrollable: false,
        child: _AddUserDialog(
          onSubmit: (email) => UserDocumentCreator.ensureByEmail(email),
        ),
      ),
    );

    if (result == null || !mounted) return;

    _reloadUsers(forceRefresh: true);
    logFirebaseEvent('USERS_ADD_MANUAL_SUCCESS');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.created
                ? 'Utilisateur ajouté à la liste.'
                : 'Document utilisateur déjà présent et synchronisé.',
          ),
        ),
      );
  }

  Future<void> _showPayment(UserRecord user) async {
    logFirebaseEvent('USERS_CARD_PAYMENT_ON_TAP');
    final saved = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) => AdminDialogFrame(
        maxWidth: 760,
        scrollable: false,
        child: PaiementWidget(
          refUser: user.reference,
          currentEndSub: user.endSub,
          currentPaymentMethod: user.method,
          currentMemberTime: user.memberTime,
        ),
      ),
    );

    if (saved == true && mounted) {
      _reloadUsers(forceRefresh: true);
    }
  }

  Future<void> _exportUsers(List<UserRecord> users) async {
    if (_isExporting || users.isEmpty) return;
    setState(() => _isExporting = true);
    logFirebaseEvent('USERS_EXPORT_EXCEL_ON_TAP');

    try {
      await UserExcelExporter.export(
        users,
        filterLabel: _model.filtres,
        searchQuery: _model.textController?.text ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${users.length} ${users.length > 1 ? 'utilisateurs exportés' : 'utilisateur exporté'} vers Excel.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'L’export Excel a échoué. Veuillez réessayer.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Helpers pour la vue Utilisateurs ──────────────────────────────────────

  Widget _buildUsersTab(BuildContext context) {
    final compactNavigation = MediaQuery.sizeOf(context).width < 992;
    final usersFuture = _usersFuture;

    if (usersFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<UserRecord>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _UsersErrorState(
            onRetry: () => _reloadUsers(forceRefresh: true),
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
                  user.endSub != null && !user.endSub!.isBefore(DateTime.now()),
            )
            .length;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compactNavigation ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              _UsersToolbar(
                controller: _model.textController!,
                focusNode: _model.textFieldFocusNode!,
                selectedFilter: _model.filtres,
                totalCount: allUsers.length,
                vipCount: vipCount,
                viewMode: _viewMode,
                sortMode: _sortMode,
                isExporting: _isExporting,
                isRefreshing: _isRefreshingUsers,
                onQueryChanged: (_) => setState(() {}),
                onClearQuery: () {
                  _model.textController!.clear();
                  setState(() {});
                },
                onFilterChanged: (filter) {
                  setState(() => _model.filtres = filter);
                },
                onViewModeChanged: (mode) {
                  setState(() => _viewMode = mode);
                },
                onSortModeChanged: (mode) {
                  if (mode == _sortMode) return;
                  logFirebaseEvent(
                    'USERS_SORT_CHANGED',
                    parameters: {'sort': mode.name},
                  );
                  setState(() => _sortMode = mode);
                },
                onRefresh: _refreshUsers,
                onExport: users.isEmpty ? null : () => _exportUsers(users),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: users.isEmpty
                    ? _UsersEmptyState(
                        hasSearch:
                            _model.textController!.text.trim().isNotEmpty,
                        onReset: () {
                          _model.textController!.clear();
                          setState(() => _model.filtres = 'Tout');
                        },
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: _handleUserListScroll,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _viewMode == _UsersViewMode.cards
                              ? LayoutBuilder(
                                  key: const ValueKey('users-card-view'),
                                  builder: (context, constraints) {
                                    final cardWidth = constraints.maxWidth < 720
                                        ? constraints.maxWidth
                                        : constraints.maxWidth < 1160
                                            ? 360.0
                                            : 380.0;

                                    return GridView.builder(
                                      padding:
                                          const EdgeInsets.only(bottom: 28),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      gridDelegate:
                                          SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: cardWidth,
                                        mainAxisExtent: 280,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: users.length,
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        return _UserCard(
                                          user: user,
                                          onViewProfile: () => _showUser(user),
                                          onAddPayment: () =>
                                              _showPayment(user),
                                        );
                                      },
                                    );
                                  },
                                )
                              : _UsersList(
                                  key: const ValueKey('users-list-view'),
                                  users: users,
                                  onViewProfile: _showUser,
                                  onAddPayment: _showPayment,
                                ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final compactNavigation = MediaQuery.sizeOf(context).width < 992;
    final theme = FlutterFlowTheme.of(context);

    // Labels des onglets (avec badge « pending » pour les preuves)
    final tabTitles = [
      'Utilisateurs',
      'Preuves de paiement',
      'Paiements clients'
    ];
    final currentTabTitle = tabTitles[_tabController.index.clamp(0, 2)];

    final tabs = <Widget>[
      const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_rounded, size: 18),
            SizedBox(width: 8),
            Text('Utilisateurs'),
          ],
        ),
      ),
      Tab(
        child: StreamBuilder<List<PaymentRequest>>(
          stream: _pendingRequestsStream,
          builder: (context, snapshot) {
            final pendingCount = snapshot.data?.length ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('Preuves de paiement'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, size: 18),
            SizedBox(width: 8),
            Text('Paiements clients'),
          ],
        ),
      ),
    ];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: compactNavigation
            ? AdminMobileAppBar(title: currentTabTitle)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── En-tête de page compact (2 lignes MAX) ────────────
                    Container(
                      color: theme.secondaryBackground,
                      padding: EdgeInsets.fromLTRB(
                        compactNavigation ? 16 : 24,
                        compactNavigation ? 8 : 12,
                        compactNavigation ? 16 : 24,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ligne 1 : Titre + Action contextuelle (desktop)
                          if (!compactNavigation)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.manage_accounts_rounded,
                                    size: 20,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Membres & Paiements',
                                    style: theme.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: -.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_tabController.index == 0)
                                    ElevatedButton.icon(
                                      onPressed: _showAddUserDialog,
                                      icon: const Icon(Icons.add_rounded,
                                          size: 16),
                                      label:
                                          const Text('Ajouter un utilisateur'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primary,
                                        foregroundColor: theme.info,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                        textStyle: theme.labelMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          // Ligne 2 : TabBar (3 onglets)
                          TabBar(
                            controller: _tabController,
                            tabs: tabs,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelStyle: theme.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                            unselectedLabelStyle: theme.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                            labelColor: theme.primaryText,
                            unselectedLabelColor: theme.secondaryText,
                            indicatorColor: theme.primary,
                            indicatorWeight: 2.5,
                            indicatorSize: TabBarIndicatorSize.tab,
                            splashBorderRadius: BorderRadius.circular(12),
                            dividerColor:
                                theme.alternate.withValues(alpha: .72),
                          ),
                        ],
                      ),
                    ),
                    // ── Contenu des onglets ──────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Onglet 0 — Utilisateurs
                          _KeepAliveWrapper(child: _buildUsersTab(context)),
                          // Onglet 1 — Preuves de paiement
                          const PaymentReviewsView(),
                          // Onglet 2 — Paiements clients
                          const PaymentTransactionsView(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({required this.onSubmit});

  final Future<UserDocumentCreationResult> Function(String email) onSubmit;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onSubmit(_emailController.text.trim());
      if (mounted) Navigator.pop(context, result);
    } on UserDocumentCreationException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Impossible de créer le document utilisateur. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Saisissez l’adresse e-mail du client.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Saisissez une adresse e-mail valide.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminDialogHeader(
              title: 'Ajouter un utilisateur',
              subtitle: 'Créer le document Firebase manquant',
              icon: Icons.person_add_alt_1_rounded,
              onClose: _saving ? () {} : () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            Text(
              'L’adresse doit déjà être associée à un compte Firebase Auth. Son UID sera utilisé pour créer le document user.',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              autofocus: true,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              validator: _validateEmail,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'E-mail du client',
                hintText: 'client@exemple.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
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
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.error.withValues(alpha: .2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.error,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.bodySmall.copyWith(color: theme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 330;
                final cancel = OutlinedButton.icon(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Annuler'),
                );
                final add = FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded, size: 19),
                  label: Text(_saving ? 'Ajout…' : 'Ajouter'),
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      add,
                      const SizedBox(height: 10),
                      cancel,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: 12),
                    Expanded(child: add),
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

class _UsersToolbar extends StatelessWidget {
  const _UsersToolbar({
    required this.controller,
    required this.focusNode,
    required this.selectedFilter,
    required this.totalCount,
    required this.vipCount,
    required this.viewMode,
    required this.sortMode,
    required this.isExporting,
    required this.isRefreshing,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
    required this.onViewModeChanged,
    required this.onSortModeChanged,
    required this.onRefresh,
    required this.onExport,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String selectedFilter;
  final int totalCount;
  final int vipCount;
  final _UsersViewMode viewMode;
  final UserSortMode sortMode;
  final bool isExporting;
  final bool isRefreshing;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<_UsersViewMode> onViewModeChanged;
  final ValueChanged<UserSortMode> onSortModeChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              labelText: 'Rechercher',
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
          final refreshButton = IconButton(
            tooltip: 'Actualiser les utilisateurs',
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: theme.primary,
              backgroundColor: theme.accent1,
              side: BorderSide(
                color: theme.secondary.withValues(alpha: .35),
              ),
            ),
          );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 220, child: search),
                  const SizedBox(width: 12),
                  filters,
                  const SizedBox(width: 12),
                  refreshButton,
                  const SizedBox(width: 8),
                  _UsersViewActions(
                    viewMode: viewMode,
                    sortMode: sortMode,
                    isExporting: isExporting,
                    onViewModeChanged: onViewModeChanged,
                    onSortModeChanged: onSortModeChanged,
                    onExport: onExport,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UsersViewActions extends StatelessWidget {
  const _UsersViewActions({
    required this.viewMode,
    required this.sortMode,
    required this.isExporting,
    required this.onViewModeChanged,
    required this.onSortModeChanged,
    required this.onExport,
  });

  final _UsersViewMode viewMode;
  final UserSortMode sortMode;
  final bool isExporting;
  final ValueChanged<_UsersViewMode> onViewModeChanged;
  final ValueChanged<UserSortMode> onSortModeChanged;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: 'Exporter vers Excel',
          onPressed: isExporting ? null : onExport,
          icon: isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download_outlined, size: 20),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: theme.primary,
            backgroundColor: theme.accent1,
            side: BorderSide(color: theme.secondary.withValues(alpha: .35)),
          ),
        ),
        const SizedBox(width: 10),
        UserSortControl(
          value: sortMode,
          onChanged: onSortModeChanged,
        ),
        const SizedBox(width: 10),
        _ViewModeToggle(
          viewMode: viewMode,
          onChanged: onViewModeChanged,
        ),
      ],
    );
  }
}

class UserSortControl extends StatelessWidget {
  const UserSortControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UserSortMode value;
  final ValueChanged<UserSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = switch (value) {
      UserSortMode.alphabetical => 'Alphabétique',
      UserSortMode.lastModified => 'Modifiés récemment',
      UserSortMode.nearestExpiration => 'Expiration proche',
      UserSortMode.newestUsers => 'Nouveaux utilisateurs',
    };
    final icon = switch (value) {
      UserSortMode.alphabetical => Icons.sort_by_alpha_rounded,
      UserSortMode.lastModified => Icons.history_rounded,
      UserSortMode.nearestExpiration => Icons.schedule_rounded,
      UserSortMode.newestUsers => Icons.person_add_alt_1_rounded,
    };

    return Semantics(
      button: true,
      label: 'Trier les utilisateurs : $label',
      child: Tooltip(
        message: 'Trier : $label',
        child: PopupMenuButton<UserSortMode>(
          initialValue: value,
          tooltip: '',
          position: PopupMenuPosition.under,
          onSelected: onChanged,
          itemBuilder: (context) => [
            _sortMenuItem(
              context,
              mode: UserSortMode.alphabetical,
              icon: Icons.sort_by_alpha_rounded,
              label: 'Ordre alphabétique',
            ),
            _sortMenuItem(
              context,
              mode: UserSortMode.lastModified,
              icon: Icons.history_rounded,
              label: 'Dernière modification',
            ),
            _sortMenuItem(
              context,
              mode: UserSortMode.nearestExpiration,
              icon: Icons.schedule_rounded,
              label: 'Expiration proche',
            ),
            _sortMenuItem(
              context,
              mode: UserSortMode.newestUsers,
              icon: Icons.person_add_alt_1_rounded,
              label: 'Nouveaux utilisateurs',
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Icon(icon, size: 20, color: theme.primary),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<UserSortMode> _sortMenuItem(
    BuildContext context, {
    required UserSortMode mode,
    required IconData icon,
    required String label,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final selected = value == mode;

    return PopupMenuItem<UserSortMode>(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? theme.primary : theme.secondaryText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.bodyMedium.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 12),
            Icon(Icons.check_rounded, size: 19, color: theme.primary),
          ],
        ],
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  final _UsersViewMode viewMode;
  final ValueChanged<_UsersViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            key: const ValueKey('users-view-cards-button'),
            icon: Icons.grid_view_rounded,
            tooltip: 'Vue cartes',
            selected: viewMode == _UsersViewMode.cards,
            onPressed: () => onChanged(_UsersViewMode.cards),
          ),
          const SizedBox(width: 3),
          _ViewModeButton(
            key: const ValueKey('users-view-list-button'),
            icon: Icons.view_list_rounded,
            tooltip: 'Vue liste',
            selected: viewMode == _UsersViewMode.list,
            onPressed: () => onChanged(_UsersViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          minimumSize: const Size(38, 38),
          maximumSize: const Size(38, 38),
          padding: EdgeInsets.zero,
          foregroundColor: selected ? theme.info : theme.secondaryText,
          backgroundColor: selected ? theme.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
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

class _UsersList extends StatelessWidget {
  const _UsersList({
    super.key,
    required this.users,
    required this.onViewProfile,
    required this.onAddPayment,
  });

  final List<UserRecord> users;
  final Future<void> Function(UserRecord) onViewProfile;
  final Future<void> Function(UserRecord) onAddPayment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;

        return Column(
          children: [
            if (wide) ...[
              const _UserListHeader(),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 28),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListItem(
                    user: user,
                    wide: wide,
                    onViewProfile: () => onViewProfile(user),
                    onAddPayment: () => onAddPayment(user),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserListHeader extends StatelessWidget {
  const _UserListHeader();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final labelStyle = theme.labelSmall.copyWith(
      color: theme.secondaryText,
      fontWeight: FontWeight.w800,
      letterSpacing: .7,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          const SizedBox(width: 66),
          Expanded(flex: 3, child: Text('UTILISATEUR', style: labelStyle)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: Text('CONTACT', style: labelStyle)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: Text('ABONNEMENT', style: labelStyle)),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.right,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatefulWidget {
  const _UserListItem({
    required this.user,
    required this.wide,
    required this.onViewProfile,
    required this.onAddPayment,
  });

  final UserRecord user;
  final bool wide;
  final VoidCallback onViewProfile;
  final VoidCallback onAddPayment;

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
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
    final phone = user.phoneNumber.trim().isEmpty
        ? 'Téléphone non renseigné'
        : user.phoneNumber.trim();
    final now = DateTime.now();
    final active = user.endSub != null && !user.endSub!.isBefore(now);
    final isNew = isNewUser(user.createdTime, now);
    final initial = name.characters.first.toUpperCase();
    final deadline = user.endSub == null
        ? 'Non définie'
        : dateTimeFormat(
            'd MMM y',
            user.endSub,
            locale: FFLocalizations.of(context).languageCode,
          );

    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          user.phoneNumber.trim().isEmpty
              ? 'Téléphone non renseigné'
              : user.phoneNumber.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? theme.primary.withValues(alpha: .28)
                : theme.alternate,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: theme.primaryText.withValues(alpha: .07),
                    blurRadius: 20,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onViewProfile,
            child: Padding(
              padding: EdgeInsets.all(widget.wide ? 14 : 16),
              child: widget.wide
                  ? _buildWideRow(
                      context,
                      identity: identity,
                      initial: initial,
                      email: email,
                      phone: phone,
                      deadline: deadline,
                      isNew: isNew,
                      isVip: active,
                    )
                  : _buildCompactRow(
                      context,
                      identity: identity,
                      initial: initial,
                      email: email,
                      phone: phone,
                      deadline: deadline,
                      isNew: isNew,
                      isVip: active,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideRow(
    BuildContext context, {
    required Widget identity,
    required String initial,
    required String email,
    required String phone,
    required String deadline,
    required bool isNew,
    required bool isVip,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        _UserAvatar(
          user: widget.user,
          initial: initial,
          size: 52,
          isNew: isNew,
          isVip: isVip,
        ),
        const SizedBox(width: 14),
        Expanded(flex: 3, child: identity),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContactRow(
                icon: Icons.mail_outline_rounded,
                value: email,
                action: widget.user.email.trim().isEmpty
                    ? null
                    : _CopyEmailButton(email: widget.user.email),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deadline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.user.memberTime} mois actifs',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Voir le profil',
                onPressed: widget.onViewProfile,
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: theme.primaryText,
                  backgroundColor: theme.primaryBackground,
                  side: BorderSide(color: theme.alternate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onAddPayment,
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('Paiement'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: theme.primary,
                    foregroundColor: theme.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactRow(
    BuildContext context, {
    required Widget identity,
    required String initial,
    required String email,
    required String phone,
    required String deadline,
    required bool isNew,
    required bool isVip,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _UserAvatar(
              user: widget.user,
              initial: initial,
              size: 50,
              isNew: isNew,
              isVip: isVip,
            ),
            const SizedBox(width: 12),
            Expanded(child: identity),
            IconButton(
              tooltip: 'Voir le profil',
              onPressed: widget.onViewProfile,
              icon: const Icon(Icons.chevron_right_rounded),
              style: IconButton.styleFrom(
                foregroundColor: theme.primary,
                backgroundColor: theme.accent1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _ContactRow(
          icon: Icons.mail_outline_rounded,
          value: email,
          action: widget.user.email.trim().isEmpty
              ? null
              : _CopyEmailButton(email: widget.user.email),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CompactListMetric(
                  label: 'Échéance',
                  value: deadline,
                ),
              ),
              Container(width: 1, height: 34, color: theme.alternate),
              Expanded(
                child: _CompactListMetric(
                  label: 'Mois actifs',
                  value: '${widget.user.memberTime}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onViewProfile,
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: const Text('Profil'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: BorderSide(color: theme.alternate),
                  foregroundColor: theme.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onAddPayment,
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: const Text('Paiement'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: theme.primary,
                  foregroundColor: theme.info,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactListMetric extends StatelessWidget {
  const _CompactListMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          style: theme.bodySmall.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class UserAuthProviderBadges extends StatelessWidget {
  const UserAuthProviderBadges({
    super.key,
    required this.providerIds,
    this.unavailable = false,
    this.compact = false,
  });

  final List<String>? providerIds;
  final bool unavailable;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (unavailable) {
      return _AuthProviderBadge(
        icon: Icons.cloud_off_outlined,
        label: 'Connexion indisponible',
        color: theme.secondaryText,
        compact: compact,
      );
    }
    if (providerIds == null) {
      return _AuthProviderBadge(
        icon: Icons.sync_rounded,
        label: 'Chargement…',
        color: theme.secondaryText,
        compact: compact,
      );
    }

    final normalizedProviders = providerIds!
        .map((provider) => provider.trim())
        .where((provider) => provider.isNotEmpty)
        .toSet()
        .toList()
      ..sort((first, second) =>
          _providerPriority(first).compareTo(_providerPriority(second)));
    if (normalizedProviders.isEmpty) {
      return _AuthProviderBadge(
        icon: Icons.help_outline_rounded,
        label: 'Connexion inconnue',
        color: theme.secondaryText,
        compact: compact,
      );
    }

    final labels = normalizedProviders.map(_providerLabel).join(', ');
    return Semantics(
      label: 'Méthodes de connexion : $labels',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0;
                index < normalizedProviders.length;
                index++) ...[
              if (index > 0) const SizedBox(width: 6),
              _AuthProviderBadge(
                icon: _providerIcon(normalizedProviders[index]),
                label: _providerLabel(normalizedProviders[index]),
                color: _providerColor(normalizedProviders[index], theme),
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _providerPriority(String provider) => switch (provider) {
        'google.com' => 0,
        'password' => 1,
        'apple.com' => 2,
        'phone' => 3,
        _ => 4,
      };

  String _providerLabel(String provider) => switch (provider) {
        'google.com' => 'Google',
        'password' => 'E-mail',
        'apple.com' => 'Apple',
        'phone' => 'Téléphone',
        'facebook.com' => 'Facebook',
        'microsoft.com' => 'Microsoft',
        'github.com' => 'GitHub',
        'twitter.com' => 'X / Twitter',
        'yahoo.com' => 'Yahoo',
        _ => provider,
      };

  IconData _providerIcon(String provider) => switch (provider) {
        'google.com' => Icons.public_rounded,
        'password' => Icons.mail_outline_rounded,
        'apple.com' => Icons.phone_iphone_rounded,
        'phone' => Icons.phone_android_rounded,
        _ => Icons.account_circle_outlined,
      };

  Color _providerColor(String provider, FlutterFlowTheme theme) =>
      switch (provider) {
        'google.com' => theme.primary,
        'password' => theme.tertiary,
        'apple.com' => theme.primaryText,
        'phone' => theme.success,
        _ => theme.secondaryText,
      };
}

class _AuthProviderBadge extends StatelessWidget {
  const _AuthProviderBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewUserBadge extends StatelessWidget {
  const _NewUserBadge();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.alternate),
      ),
      child: Text(
        'Nouveau',
        style: theme.labelSmall.copyWith(
          color: theme.secondaryText,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: .1,
        ),
      ),
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
    final now = DateTime.now();
    final active = user.endSub != null && !user.endSub!.isBefore(now);
    final isNew = isNewUser(user.createdTime, now);
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
          borderRadius: BorderRadius.circular(18),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserAvatar(
                        user: user,
                        initial: initial,
                        size: 52,
                        isNew: isNew,
                        isVip: active,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              user.phoneNumber.trim().isEmpty
                                  ? 'Téléphone non renseigné'
                                  : user.phoneNumber.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                                fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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
                            height: 30,
                            color: theme.alternate,
                          ),
                          Expanded(
                            child: _UserMetric(
                              label: 'Mois actifs',
                              value: '${user.memberTime}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
  const _UserAvatar({
    required this.user,
    required this.initial,
    this.size = 60,
    this.isNew = false,
    this.isVip = false,
  });

  final UserRecord user;
  final String initial;
  final double size;
  final bool isNew;
  final bool isVip;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fallback = Center(
      child: Text(
        initial,
        style: (size < 56 ? theme.titleMedium : theme.titleLarge).copyWith(
          color: theme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.accent1,
              shape: BoxShape.circle,
              border: Border.all(
                color: isVip ? const Color(0xFF7C3AED) : theme.secondary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryText.withValues(alpha: .10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox.expand(
                child: user.photoUrl.trim().isEmpty
                    ? fallback
                    : CachedNetworkImage(
                        imageUrl: user.photoUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => fallback,
                        errorWidget: (_, __, ___) => fallback,
                      ),
              ),
            ),
          ),
          if (isVip)
            Positioned(
              top: -3,
              right: -3,
              child: Tooltip(
                message: 'Membre VIP',
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.secondaryBackground, width: 2),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 15,
                    color: Color(0xFFFFD447),
                    semanticLabel: 'Membre VIP',
                  ),
                ),
              ),
            ),
          if (isNew)
            const Positioned(
              bottom: -7,
              child: _NewUserBadge(),
            ),
        ],
      ),
    );
  }
}

class _CopyEmailButton extends StatelessWidget {
  const _CopyEmailButton({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copier l’e-mail',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: email));
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
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});
  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
