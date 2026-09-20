import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'support_conversation.dart';
import 'support_audio.dart';
import 'support_audio_player.dart';
import 'support_image_picker.dart';
import 'support_text.dart';
import 'support_voice_recorder.dart';

class SupportInboxWidget extends StatefulWidget {
  const SupportInboxWidget({super.key, this.repository});

  static const routeName = 'SupportInbox';
  static const routePath = '/support-inbox';

  final SupportConversationRepository? repository;

  @override
  State<SupportInboxWidget> createState() => _SupportInboxWidgetState();
}

class _SupportInboxWidgetState extends State<SupportInboxWidget> {
  final _scaffold = GlobalKey<ScaffoldState>();
  late final SupportConversationRepository _repository =
      widget.repository ?? SupportConversationRepository();
  String? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      key: _scaffold,
      backgroundColor: theme.primaryBackground,
      drawer: isDesktop
          ? null
          : const Drawer(child: SidenavWidget(forceVisible: true)),
      appBar:
          isDesktop ? null : const AdminMobileAppBar(title: 'Service client'),
      bottomNavigationBar: isDesktop
          ? null
          : AdminMobileBottomBar(
              activeDestination: AdminMobileDestination.more,
              onOpenMenu: () => _scaffold.currentState?.openDrawer(),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SidenavWidget(),
            Expanded(
              child: StreamBuilder<List<SupportConversation>>(
                stream: _repository.watchAll(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.lg),
                        child: const AdminSurface(
                          child: _InboxState(
                            icon: Icons.cloud_off_rounded,
                            message:
                                'Impossible de charger les conversations. Vérifiez la connexion et les droits administrateur.',
                          ),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }

                  final conversations = snapshot.data!;

                  if (!isDesktop) {
                    // Mobile & compact viewport layout
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: ListView(
                          padding: EdgeInsets.all(spacing.md),
                          children: [
                            Text('Service client', style: theme.headlineMedium),
                            SizedBox(height: spacing.xs),
                            Text(
                              'Questions d’abonnement reçues depuis l’application.',
                              style: theme.bodyLarge
                                  .override(color: theme.secondaryText),
                            ),
                            SizedBox(height: spacing.lg),
                            SupportConversationList(
                              conversations: conversations,
                              onOpen: (conversation) =>
                                  Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SupportConversationPage(
                                    conversation: conversation,
                                    repository: _repository,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Desktop Dual-Pane (Split-view) layout
                  SupportConversation? selectedConversation;
                  for (final c in conversations) {
                    if (c.id == _selectedConversationId) {
                      selectedConversation = c;
                      break;
                    }
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left column: Inbox list with live filtering & search
                      SizedBox(
                        width: 400,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: theme.alternate),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(spacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Service client',
                                            style: theme.headlineSmall),
                                        const Spacer(),
                                        AdminStatusPill(
                                          compact: true,
                                          label:
                                              '${conversations.length} conversation${conversations.length > 1 ? 's' : ''}',
                                          color: theme.primary,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing.xs),
                                    Text(
                                      'Assistance client en direct',
                                      style: theme.bodySmall.override(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: theme.alternate),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(spacing.md),
                                  child: SupportConversationList(
                                    conversations: conversations,
                                    selectedConversationId:
                                        _selectedConversationId,
                                    isEmbedded: true,
                                    onOpen: (conversation) {
                                      setState(() {
                                        _selectedConversationId =
                                            conversation.id;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right column: Active conversation or elegant placeholder
                      Expanded(
                        child: selectedConversation != null
                            ? SupportConversationPage(
                                key: ValueKey(
                                    'chat-pane-${selectedConversation.id}'),
                                conversation: selectedConversation,
                                repository: _repository,
                                embedded: true,
                                onClose: () => setState(
                                    () => _selectedConversationId = null),
                              )
                            : _DesktopEmptyChatPane(
                                conversations: conversations),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SupportFilter { all, pending, treated }

class SupportConversationList extends StatefulWidget {
  const SupportConversationList({
    super.key,
    required this.conversations,
    required this.onOpen,
    this.selectedConversationId,
    this.isEmbedded = false,
  });

  final List<SupportConversation> conversations;
  final ValueChanged<SupportConversation> onOpen;
  final String? selectedConversationId;
  final bool isEmbedded;

  @override
  State<SupportConversationList> createState() =>
      _SupportConversationListState();
}

class _SupportConversationListState extends State<SupportConversationList> {
  final _searchController = TextEditingController();
  _SupportFilter _currentFilter = _SupportFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required FlutterFlowTheme theme,
    Color? accentColor,
  }) {
    final color = accentColor ?? theme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme.designToken.radius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .14)
              : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          border: Border.all(
            color: selected ? color : theme.alternate,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.labelSmall.copyWith(
            color: selected ? color : theme.secondaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;

    if (widget.conversations.isEmpty) {
      return const AdminSurface(
        child: _InboxState(
          icon: Icons.forum_outlined,
          message: 'Aucune conversation pour le moment.',
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final pendingTotal =
        widget.conversations.where((c) => c.waitingForAdmin).length;
    final treatedTotal = widget.conversations.where((c) => c.isTreated).length;

    final filtered = widget.conversations.where((conversation) {
      if (_currentFilter == _SupportFilter.pending &&
          !conversation.waitingForAdmin) {
        return false;
      }
      if (_currentFilter == _SupportFilter.treated && !conversation.isTreated) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName =
            conversation.memberLabel.toLowerCase().contains(query);
        final matchesEmail =
            conversation.userEmail.toLowerCase().contains(query);
        final matchesReference =
            conversation.memberReference.toLowerCase().contains(query) ||
                conversation.userUid.toLowerCase().contains(query);
        final matchesMessage =
            conversation.lastMessage.toLowerCase().contains(query);
        if (!matchesName &&
            !matchesEmail &&
            !matchesReference &&
            !matchesMessage) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live search bar
        Padding(
          padding: EdgeInsets.only(bottom: spacing.sm),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: theme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Rechercher un membre, email ou message…',
              hintStyle: theme.labelMedium.override(color: theme.secondaryText),
              prefixIcon: Icon(Icons.search_rounded,
                  color: theme.secondaryText, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.secondaryBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.md),
                borderSide: BorderSide(color: theme.alternate),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.md),
                borderSide: BorderSide(color: theme.alternate),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.md),
                borderSide: BorderSide(color: theme.primary),
              ),
            ),
          ),
        ),

        // Filter chips bar
        Padding(
          padding: EdgeInsets.only(bottom: spacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tous (${widget.conversations.length})',
                  selected: _currentFilter == _SupportFilter.all,
                  onTap: () =>
                      setState(() => _currentFilter = _SupportFilter.all),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'À répondre ($pendingTotal)',
                  selected: _currentFilter == _SupportFilter.pending,
                  onTap: () =>
                      setState(() => _currentFilter = _SupportFilter.pending),
                  theme: theme,
                  accentColor: theme.warning,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Traités ($treatedTotal)',
                  selected: _currentFilter == _SupportFilter.treated,
                  onTap: () =>
                      setState(() => _currentFilter = _SupportFilter.treated),
                  theme: theme,
                  accentColor: theme.success,
                ),
              ],
            ),
          ),
        ),

        // Filtered list items or search empty state
        if (filtered.isEmpty)
          AdminSurface(
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 40, color: theme.secondaryText),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Aucune conversation ne correspond à vos filtres.',
                    style:
                        theme.bodyMedium.override(color: theme.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  if (query.isNotEmpty ||
                      _currentFilter != _SupportFilter.all) ...[
                    SizedBox(height: spacing.xs),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _currentFilter = _SupportFilter.all);
                      },
                      child: const Text('Réinitialiser les filtres'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          for (final conversation in filtered)
            _buildConversationCard(conversation, theme, spacing),
      ],
    );
  }

  Widget _buildConversationCard(
    SupportConversation conversation,
    FlutterFlowTheme theme,
    dynamic spacing,
  ) {
    final isSelected = widget.selectedConversationId == conversation.id;
    final isWaiting = conversation.waitingForAdmin;
    final isDeleting = conversation.isDeleting;
    final isTreated = conversation.isTreated;

    Color? borderColor;
    if (isSelected) {
      borderColor = theme.primary;
    } else if (isDeleting) {
      borderColor = theme.error.withValues(alpha: .55);
    } else if (isWaiting) {
      borderColor = theme.warning.withValues(alpha: .55);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: AdminSurface(
        borderColor: borderColor,
        color: isSelected ? theme.primary.withValues(alpha: .05) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              key: ValueKey('support-conversation-${conversation.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  _MemberAvatar(
                    label: conversation.memberLabel,
                    size: 44,
                  ),
                  if (isWaiting)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.secondaryBackground,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                conversation.memberLabel,
                style: theme.titleSmall.copyWith(
                  fontWeight: isWaiting ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conversation.userEmail.isNotEmpty &&
                      conversation.userEmail != conversation.memberLabel)
                    Text(
                      conversation.userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.labelSmall.override(color: theme.secondaryText),
                    ),
                  if (conversation.memberReference.isNotEmpty)
                    Text(
                      conversation.memberReference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.labelSmall.override(color: theme.secondaryText),
                    ),
                  SizedBox(height: spacing.xs),
                  Row(
                    children: [
                      if (conversation.lastMessage.contains('Note vocale') ||
                          conversation.lastMessage == 'Note vocale') ...[
                        Icon(Icons.mic_rounded,
                            size: 15,
                            color: isWaiting
                                ? theme.primaryText
                                : theme.secondaryText),
                        const SizedBox(width: 4),
                      ] else if (conversation.lastMessage.contains('Photo') ||
                          conversation.lastMessage == 'Photo') ...[
                        Icon(Icons.photo_camera_rounded,
                            size: 15,
                            color: isWaiting
                                ? theme.primaryText
                                : theme.secondaryText),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.copyWith(
                            fontWeight:
                                isWaiting ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AdminStatusPill(
                    compact: true,
                    label: isDeleting
                        ? 'Suppression…'
                        : isTreated
                            ? 'Traité'
                            : isWaiting
                                ? 'À répondre'
                                : 'Répondu',
                    color: isDeleting
                        ? theme.error
                        : isWaiting
                            ? theme.warning
                            : theme.success,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    _formatSupportDate(conversation.updatedAt),
                    style:
                        theme.labelSmall.override(color: theme.secondaryText),
                  ),
                ],
              ),
              onTap: () => widget.onOpen(conversation),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopEmptyChatPane extends StatelessWidget {
  const _DesktopEmptyChatPane({required this.conversations});

  final List<SupportConversation> conversations;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    final pendingCount = conversations.where((c) => c.waitingForAdmin).length;
    final treatedCount = conversations.where((c) => c.isTreated).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.forum_rounded,
                  size: 40,
                  color: theme.primary,
                ),
              ),
              SizedBox(height: spacing.md),
              Text(
                'Sélectionnez une conversation',
                style: theme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.xs),
              Text(
                'Cliquez sur un message dans la colonne de gauche pour consulter l’historique complet et répondre au client.',
                style: theme.bodyMedium.override(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuickStatCard(
                    title: 'À répondre',
                    count: pendingCount,
                    color: theme.warning,
                    icon: Icons.mark_unread_chat_alt_rounded,
                  ),
                  SizedBox(width: spacing.md),
                  _QuickStatCard(
                    title: 'Traitées',
                    count: treatedCount,
                    color: theme.success,
                    icon: Icons.mark_chat_read_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(theme.designToken.radius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: theme.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: theme.labelSmall.override(color: theme.secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PendingSupportConversationsTile extends StatefulWidget {
  const PendingSupportConversationsTile({
    super.key,
    this.repository,
    this.compact = false,
    this.showBottomSpacing = true,
  });

  final SupportConversationRepository? repository;
  final bool compact;
  final bool showBottomSpacing;

  @override
  State<PendingSupportConversationsTile> createState() =>
      _PendingSupportConversationsTileState();
}

class _PendingSupportConversationsTileState
    extends State<PendingSupportConversationsTile> {
  late final SupportConversationRepository _repository =
      widget.repository ?? SupportConversationRepository();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.showBottomSpacing ? theme.designToken.spacing.md : 0,
      ),
      child: AdminSurface(
        padding: EdgeInsets.all(widget.compact ? 14 : 16),
        child: StreamBuilder<List<SupportConversation>>(
          stream: _repository.watchAll(),
          builder: (context, snapshot) {
            final waiting = snapshot.data
                    ?.where((conversation) => conversation.waitingForAdmin)
                    .length ??
                0;
            return ListTile(
              key: const ValueKey('pending-support-conversations'),
              dense: widget.compact,
              contentPadding: EdgeInsets.zero,
              horizontalTitleGap: widget.compact ? 10 : null,
              leading: AdminIconTile(
                icon: Icons.support_agent_rounded,
                size: widget.compact ? 40 : 44,
                iconSize: widget.compact ? 20 : 22,
                radius: widget.compact ? 13 : 14,
              ),
              title: Text(
                'Service client',
                maxLines: widget.compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: widget.compact ? theme.titleMedium : theme.titleLarge,
              ),
              subtitle: Text(
                snapshot.hasError
                    ? 'Conversations indisponibles'
                    : '$waiting conversation${waiting == 1 ? '' : 's'} à traiter',
                maxLines: widget.compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.primary,
                size: widget.compact ? 20 : 24,
              ),
              onTap: () => context.pushNamed(SupportInboxWidget.routeName),
            );
          },
        ),
      ),
    );
  }
}

class SupportConversationPage extends StatefulWidget {
  const SupportConversationPage({
    super.key,
    required this.conversation,
    required this.repository,
    this.pickImage,
    this.recorderFactory,
    this.embedded = false,
    this.onClose,
  });

  final SupportConversation conversation;
  final SupportConversationRepository repository;
  final Future<Uint8List?> Function()? pickImage;
  final SupportVoiceRecorder Function()? recorderFactory;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  State<SupportConversationPage> createState() =>
      _SupportConversationPageState();
}

class _SupportConversationPageState extends State<SupportConversationPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _preparingImage = false;
  bool _recording = false;
  bool _voiceBusy = false;
  Uint8List? _image;
  SupportAudio? _audio;
  SupportVoiceRecorder? _recorder;
  Timer? _recordingTimer;
  final _recordingWatch = Stopwatch();
  String? _pendingAttachmentId;
  String? _error;
  int _messageCount = 0;
  bool _supportActionBusy = false;
  String? _messageActionId;
  late bool _isTreated;
  bool _showScrollToBottom = false;

  static const _cannedResponses = [
    '👋 Bonjour ! Comment pouvons-nous vous aider ?',
    '✅ Votre abonnement a bien été vérifié et activé.',
    '📸 Pouvez-vous nous envoyer une photo de votre reçu ?',
    '⏳ Votre demande est en cours de traitement.',
    '🙏 Merci d’avoir contacté le support CHOLOTO.',
  ];

  @override
  void initState() {
    super.initState();
    _isTreated = widget.conversation.isTreated;
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final shouldShow = (max - offset) > 180;
    if (shouldShow != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        _recording) {
      unawaited(_finishVoice());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    unawaited(_recorder?.dispose().catchError((Object _) {}));
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest(int count) {
    if (count == _messageCount) return;
    _messageCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markAsTreated() async {
    if (_supportActionBusy || _isTreated || widget.conversation.isDeleting) {
      return;
    }
    setState(() => _supportActionBusy = true);
    try {
      await widget.repository.markAsTreated(widget.conversation.id);
      if (mounted) {
        setState(() => _isTreated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation marquée comme traitée.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de marquer cette conversation comme traitée.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _supportActionBusy = false);
    }
  }

  Future<void> _deleteConversation() async {
    if (_supportActionBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Effacer la conversation ?'),
        content: Text(
          'La conversation avec ${widget.conversation.memberLabel} et tous '
          'ses messages seront supprimés définitivement, sans attendre '
          '15 jours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('admin-support-confirm-delete'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _supportActionBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.deleteConversation(widget.conversation.id);
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Conversation effacée.')),
      );
    } catch (_) {
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Suppression impossible. Revenez dans la conversation pour réessayer.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _supportActionBusy = false);
    }
  }

  Future<void> _editMessage(SupportMessage message) async {
    if (_messageActionId != null || !message.sentByAdmin) return;
    var draft = message.text;
    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextFormField(
          key: const ValueKey('admin-support-edit-message-field'),
          initialValue: message.text,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (value) => draft = value,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('admin-support-confirm-edit-message'),
            onPressed: () {
              final text = draft.trim();
              if (text.isNotEmpty) Navigator.pop(dialogContext, text);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (!mounted || updatedText == null || updatedText == message.text) return;

    setState(() => _messageActionId = message.id);
    try {
      await widget.repository.editAdminMessage(
        conversationId: widget.conversation.id,
        messageId: message.id,
        text: updatedText,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message modifié.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de modifier ce message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _messageActionId = null);
    }
  }

  Future<void> _deleteMessage(
    SupportMessage message,
    SupportMessage? replacement,
  ) async {
    if (_messageActionId != null || !message.sentByAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text(
          'Le message et son média éventuel seront supprimés définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('admin-support-confirm-delete-message'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _messageActionId = message.id);
    try {
      await widget.repository.deleteAdminMessage(
        conversationId: widget.conversation.id,
        messageId: message.id,
        replacementMessageId: replacement?.id,
      );
      SupportAudioPlayer.active.value = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message supprimé.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de supprimer ce message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _messageActionId = null);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final messageText = text.isNotEmpty
        ? text
        : _audio != null
            ? 'Note vocale'
            : _image != null
                ? 'Photo'
                : '';
    if (_sending ||
        _preparingImage ||
        _recording ||
        _voiceBusy ||
        messageText.isEmpty ||
        messageText.length > 1000) {
      return;
    }
    final hasAttachment = _image != null || _audio != null;
    if (hasAttachment) {
      _pendingAttachmentId ??=
          widget.repository.newMessageId(widget.conversation.id);
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.sendAdminReply(
        conversationId: widget.conversation.id,
        adminUid: currentUserUid,
        text: messageText,
        image: _image,
        audio: _audio,
        messageId: hasAttachment ? _pendingAttachmentId : null,
      );
      if (mounted) {
        SupportAudioPlayer.active.value = null;
        _controller.clear();
        setState(() {
          _image = null;
          _audio = null;
          _pendingAttachmentId = null;
          _isTreated = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Réponse non envoyée. Vérifiez votre connexion et vos droits.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    if (_sending ||
        _preparingImage ||
        _recording ||
        _voiceBusy ||
        _audio != null) {
      return;
    }
    setState(() {
      _preparingImage = true;
      _error = null;
    });
    try {
      final image = widget.pickImage != null
          ? await widget.pickImage!()
          : await pickPreparedSupportImage();
      if (mounted && image != null) {
        setState(() {
          _image = image;
          _pendingAttachmentId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Cette photo ne peut pas être ajoutée. Choisissez une image JPEG, PNG ou WebP valide.');
      }
    } finally {
      if (mounted) setState(() => _preparingImage = false);
    }
  }

  Future<void> _startVoice() async {
    if (_voiceBusy ||
        _recording ||
        _sending ||
        _preparingImage ||
        _image != null ||
        _audio != null) {
      return;
    }
    FocusScope.of(context).unfocus();
    SupportAudioPlayer.active.value = null;
    setState(() {
      _voiceBusy = true;
      _error = null;
    });
    try {
      _recorder ??=
          widget.recorderFactory?.call() ?? DeviceSupportVoiceRecorder();
      await _recorder!.start(() => unawaited(_finishVoice()));
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.hidden ||
          lifecycle == AppLifecycleState.paused ||
          lifecycle == AppLifecycleState.detached) {
        await _recorder!.cancel();
        return;
      }
      _recordingWatch
        ..reset()
        ..start();
      setState(() => _recording = true);
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (_recordingWatch.elapsed.inSeconds >= maxSupportAudioSeconds) {
          unawaited(_finishVoice());
        } else if (mounted) {
          setState(() {});
        }
      });
    } catch (error) {
      try {
        await _recorder?.cancel();
      } catch (_) {}
      if (mounted) {
        setState(() => _error = error is MicrophonePermissionDenied
            ? 'Autorisez le microphone dans les réglages de l’application ou du navigateur.'
            : 'Enregistrement impossible. Vérifiez le microphone puis réessayez.');
      }
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  Future<void> _finishVoice({bool discard = false}) async {
    if (!_recording || _voiceBusy) return;
    _recordingTimer?.cancel();
    _recordingWatch.stop();
    setState(() => _voiceBusy = true);
    try {
      if (discard) {
        await _recorder!.cancel();
      } else {
        final audio = await _recorder!.stop();
        if (mounted) {
          setState(() {
            _audio = audio;
            _pendingAttachmentId = null;
          });
        }
      }
    } catch (_) {
      try {
        await _recorder?.cancel();
      } catch (_) {}
      if (mounted) {
        setState(() => _error =
            'Enregistrement impossible. Vérifiez le microphone puis réessayez.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _recording = false;
          _voiceBusy = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  String _formatDayHeader(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDay).inDays;

    if (diffDays == 0) {
      return "Aujourd'hui";
    } else if (diffDays == 1) {
      return "Hier";
    } else {
      String two(int n) => n.toString().padLeft(2, '0');
      return "${two(local.day)}/${two(local.month)}/${local.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;

    final content = Column(
      children: [
        // Embedded pane header (when displayed in desktop dual-pane)
        if (widget.embedded) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              border: Border(
                bottom: BorderSide(color: theme.alternate),
              ),
            ),
            child: Row(
              children: [
                _MemberAvatar(label: widget.conversation.memberLabel, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.conversation.memberLabel,
                              style: theme.titleMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AdminStatusPill(
                            compact: true,
                            label: _isTreated
                                ? 'Traité'
                                : widget.conversation.waitingForAdmin
                                    ? 'À répondre'
                                    : 'Répondu',
                            color: _isTreated
                                ? theme.success
                                : widget.conversation.waitingForAdmin
                                    ? theme.warning
                                    : theme.primary,
                          ),
                        ],
                      ),
                      if (widget.conversation.userEmail.isNotEmpty ||
                          widget.conversation.memberReference.isNotEmpty)
                        Text(
                          widget.conversation.userEmail.isNotEmpty
                              ? widget.conversation.userEmail
                              : widget.conversation.memberReference,
                          style: theme.labelSmall
                              .override(color: theme.secondaryText),
                        ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: 'Fermer la vue',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
              ],
            ),
          ),
        ],

        // Action buttons header (kept aligned right for full tests compatibility)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            border: Border(
              bottom: BorderSide(color: theme.alternate),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('admin-support-mark-treated'),
                onPressed: _supportActionBusy ||
                        _isTreated ||
                        widget.conversation.isDeleting
                    ? null
                    : _markAsTreated,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isTreated ? 'Traité' : 'Marquer traité'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('admin-support-delete'),
                onPressed: _supportActionBusy ? null : _deleteConversation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.error,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(
                    widget.conversation.isDeleting ? 'Réessayer' : 'Effacer'),
              ),
            ],
          ),
        ),

        // Message stream with date separators and floating scroll-to-bottom
        Expanded(
          child: Stack(
            children: [
              StreamBuilder<List<SupportMessage>>(
                stream: widget.repository.watchMessages(widget.conversation.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _InboxState(
                      icon: Icons.cloud_off_rounded,
                      message: 'Impossible de charger les messages.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  final messages = snapshot.data!;
                  _scrollToLatest(messages.length);
                  return ListView.builder(
                    key: const ValueKey('admin-support-message-list'),
                    controller: _scrollController,
                    padding: EdgeInsets.all(spacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final showDateHeader = index == 0 ||
                          (message.createdAt != null &&
                              messages[index - 1].createdAt != null &&
                              !_isSameDay(messages[index - 1].createdAt,
                                  message.createdAt));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateHeader && message.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.alternate.withValues(alpha: .6),
                                    borderRadius: BorderRadius.circular(
                                        theme.designToken.radius.full),
                                  ),
                                  child: Text(
                                    _formatDayHeader(message.createdAt!),
                                    style: theme.labelSmall.copyWith(
                                      color: theme.secondaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          _AdminMessageBubble(
                            message: message,
                            conversationId: widget.conversation.id,
                            repository: widget.repository,
                            memberName: widget.conversation.memberLabel,
                            actionBusy: _messageActionId != null,
                            onEdit: message.sentByAdmin
                                ? () => _editMessage(message)
                                : null,
                            onDelete: message.sentByAdmin
                                ? () => _deleteMessage(
                                      message,
                                      index == 0 ? null : messages[index - 1],
                                    )
                                : null,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              if (_showScrollToBottom)
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: Material(
                    color: theme.secondaryBackground,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 20,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bottom composer area (quick replies, voice recording, attachments, input bar)
        Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            border: Border(
              top: BorderSide(color: theme.alternate),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 16, color: theme.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.bodySmall.override(color: theme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Quick canned replies (when not recording voice)
              if (!_recording) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final canned in _cannedResponses)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar:
                                const Icon(Icons.flash_on_rounded, size: 14),
                            label: Text(canned),
                            labelStyle: theme.labelSmall
                                .copyWith(fontWeight: FontWeight.w600),
                            backgroundColor: theme.primaryBackground,
                            side: BorderSide(color: theme.alternate),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  theme.designToken.radius.full),
                            ),
                            onPressed: _sending || _voiceBusy
                                ? null
                                : () {
                                    setState(() {
                                      _controller.text = canned;
                                      _controller.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(offset: canned.length),
                                      );
                                    });
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sm),
              ],

              // Voice recording in progress
              if (_recording) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.error.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.md),
                    border:
                        Border.all(color: theme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      _PulsingRecordingDot(color: theme.error),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        child: Text(
                          'Enregistrement… ${supportAudioTime(_recordingWatch.elapsed)} / 0:30',
                          style: theme.bodyMedium.copyWith(
                            color: theme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('admin-support-cancel-recording'),
                        tooltip: 'Supprimer la note vocale',
                        onPressed: _voiceBusy
                            ? null
                            : () => _finishVoice(discard: true),
                        icon: Icon(Icons.delete_outline_rounded,
                            color: theme.error),
                      ),
                      IconButton(
                        key: const ValueKey('admin-support-stop-recording'),
                        tooltip: 'Arrêter l’enregistrement',
                        onPressed: _voiceBusy ? null : _finishVoice,
                        icon: Icon(Icons.stop_circle_outlined,
                            color: theme.primary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sm),
              ],

              // Recorded audio note preview
              if (_audio != null) ...[
                Container(
                  padding: EdgeInsets.all(spacing.sm),
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.md),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: IgnorePointer(
                          ignoring: _sending,
                          child: SupportAudioPlayer(
                            key: ObjectKey(_audio),
                            load: () async => _audio!,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('admin-support-remove-audio'),
                        tooltip: 'Supprimer la note vocale',
                        onPressed: _sending
                            ? null
                            : () => setState(() {
                                  _audio = null;
                                  _pendingAttachmentId = null;
                                }),
                        icon: Icon(Icons.delete_outline_rounded,
                            color: theme.error),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sm),
              ],

              // Picked image preview
              if (_image != null) ...[
                _AdminSelectedImagePreview(
                  bytes: _image!,
                  onRemove: _sending
                      ? null
                      : () => setState(() {
                            _image = null;
                            _pendingAttachmentId = null;
                          }),
                ),
                SizedBox(height: spacing.sm),
              ],

              // Main input row: attach image, textfield, mic, and send button
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Semantics(
                    button: true,
                    label: 'Ajouter une image',
                    child: IconButton(
                      key: const ValueKey('admin-support-attach-image-button'),
                      tooltip: 'Ajouter une image',
                      onPressed: _sending ||
                              _preparingImage ||
                              _recording ||
                              _voiceBusy ||
                              _audio != null
                          ? null
                          : _pickImage,
                      style: IconButton.styleFrom(
                        foregroundColor: theme.primary,
                        disabledForegroundColor:
                            theme.secondaryText.withValues(alpha: .45),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: _preparingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: theme.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.attach_file_rounded),
                    ),
                  ),
                  SizedBox(width: spacing.xs),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('admin-support-reply-field'),
                      controller: _controller,
                      enabled: !_sending && !_recording && !_voiceBusy,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1000,
                      style: theme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Écrire une réponse…',
                        counterText: '',
                        filled: true,
                        fillColor: theme.primaryBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              theme.designToken.radius.md),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  SizedBox(width: spacing.xs),
                  Semantics(
                    button: true,
                    label: 'Enregistrer une note vocale',
                    child: IconButton(
                      key: const ValueKey('admin-support-record-audio'),
                      tooltip: 'Enregistrer une note vocale (30 s max.)',
                      onPressed: _sending ||
                              _recording ||
                              _voiceBusy ||
                              _preparingImage ||
                              _image != null ||
                              _audio != null
                          ? null
                          : _startVoice,
                      style: IconButton.styleFrom(
                        foregroundColor: theme.primary,
                        disabledForegroundColor:
                            theme.secondaryText.withValues(alpha: .45),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: _voiceBusy && !_recording
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: theme.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.mic_none_rounded),
                    ),
                  ),
                  IconButton.filled(
                    key: const ValueKey('admin-support-send-button'),
                    tooltip: 'Envoyer',
                    onPressed:
                        _sending || _preparingImage || _recording || _voiceBusy
                            ? null
                            : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.info,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: _sending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: theme.info,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(
        color: theme.primaryBackground,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        foregroundColor: theme.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            _MemberAvatar(label: widget.conversation.memberLabel, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.conversation.memberLabel,
                      style: theme.titleMedium),
                  if (widget.conversation.userEmail.isNotEmpty ||
                      widget.conversation.memberReference.isNotEmpty)
                    Text(
                      widget.conversation.userEmail.isNotEmpty
                          ? widget.conversation.userEmail
                          : widget.conversation.memberReference,
                      style:
                          theme.labelSmall.override(color: theme.secondaryText),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _AdminSelectedImagePreview extends StatelessWidget {
  const _AdminSelectedImagePreview({
    required this.bytes,
    required this.onRemove,
  });

  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    final sizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(0);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(theme.designToken.radius.md),
          border: Border.all(color: theme.alternate),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(theme.designToken.radius.sm),
              child: Image.memory(
                bytes,
                key: const ValueKey('admin-support-selected-image'),
                width: 144,
                height: 112,
                fit: BoxFit.cover,
                semanticLabel: 'Image sélectionnée',
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$sizeKb KB',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              top: spacing.xs,
              right: spacing.xs,
              child: IconButton.filled(
                key: const ValueKey('admin-support-remove-image-button'),
                onPressed: onRemove,
                tooltip: 'Retirer l’image',
                style: IconButton.styleFrom(
                  backgroundColor: theme.secondaryBackground,
                  foregroundColor: theme.primaryText,
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AdminMessageAction { edit, delete }

class _AdminMessageBubble extends StatelessWidget {
  const _AdminMessageBubble({
    required this.message,
    required this.conversationId,
    required this.repository,
    required this.actionBusy,
    this.onEdit,
    this.onDelete,
    this.memberName,
  });

  final SupportMessage message;
  final String conversationId;
  final SupportConversationRepository repository;
  final bool actionBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    final fromAdmin = message.sentByAdmin;

    final borderRadius = fromAdmin
        ? BorderRadius.only(
            topLeft: Radius.circular(theme.designToken.radius.md),
            topRight: Radius.circular(theme.designToken.radius.md),
            bottomLeft: Radius.circular(theme.designToken.radius.md),
            bottomRight: const Radius.circular(4),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(theme.designToken.radius.md),
            topRight: Radius.circular(theme.designToken.radius.md),
            bottomRight: Radius.circular(theme.designToken.radius.md),
            bottomLeft: const Radius.circular(4),
          );

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 560),
      margin: EdgeInsets.only(bottom: spacing.md),
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: fromAdmin ? theme.primary : theme.secondaryBackground,
        borderRadius: borderRadius,
        border: fromAdmin ? null : Border.all(color: theme.alternate),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                fromAdmin
                    ? Icons.support_agent_rounded
                    : Icons.person_outline_rounded,
                size: 14,
                color: fromAdmin ? theme.info : theme.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                fromAdmin
                    ? 'Administration CHOLOTO'
                    : (memberName?.isNotEmpty == true ? memberName! : 'Membre'),
                style: theme.labelSmall.override(
                  color: fromAdmin ? theme.info : theme.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          if (message.hasAudio) ...[
            SupportAudioPlayer(
              key: ValueKey('admin-support-audio-${message.id}'),
              onPrimary: fromAdmin,
              load: () => repository.loadMessageAudio(
                  conversationId: conversationId, messageId: message.id),
            ),
            SizedBox(height: spacing.sm),
          ],
          if (message.hasImage) ...[
            _AdminSupportImage(
              key: ValueKey('admin-support-image-${message.id}'),
              image: repository.loadMessageImage(
                conversationId: conversationId,
                messageId: message.id,
              ),
            ),
            SizedBox(height: spacing.sm),
          ],
          if (!message.hasAudio || !isSupportAudioPlaceholder(message.text))
            Text(
              message.text,
              style: theme.bodyLarge.override(
                color: fromAdmin ? theme.info : theme.primaryText,
              ),
            ),
          if (message.createdAt != null) ...[
            SizedBox(height: spacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  fromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatSupportDate(message.createdAt),
                  style: theme.labelSmall.override(
                    color: fromAdmin
                        ? theme.info.withValues(alpha: .75)
                        : theme.secondaryText,
                  ),
                ),
                if (message.editedAt != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Modifié',
                    style: theme.labelSmall.override(
                      color: fromAdmin
                          ? theme.info.withValues(alpha: .75)
                          : theme.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (fromAdmin) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: theme.info.withValues(alpha: .85),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    final messageMenu = SizedBox(
      width: 34,
      height: 38,
      child: PopupMenuButton<_AdminMessageAction>(
        key: ValueKey('admin-support-message-menu-${message.id}'),
        enabled: !actionBusy,
        tooltip: 'Actions sur le message',
        padding: EdgeInsets.zero,
        iconSize: 22,
        icon: actionBusy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.secondaryText,
                ),
              )
            : Icon(Icons.more_vert_rounded, color: theme.secondaryText),
        onSelected: (action) {
          switch (action) {
            case _AdminMessageAction.edit:
              onEdit?.call();
            case _AdminMessageAction.delete:
              onDelete?.call();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _AdminMessageAction.edit,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 19),
                SizedBox(width: 10),
                Text('Modifier'),
              ],
            ),
          ),
          PopupMenuItem(
            value: _AdminMessageAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 19),
                SizedBox(width: 10),
                Text('Supprimer'),
              ],
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: fromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: fromAdmin
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: bubble),
                Padding(
                  padding: EdgeInsets.only(left: spacing.xs),
                  child: messageMenu,
                ),
              ],
            )
          : bubble,
    );
  }
}

class _AdminSupportImage extends StatefulWidget {
  const _AdminSupportImage({super.key, required this.image});

  final Future<Uint8List> image;

  @override
  State<_AdminSupportImage> createState() => _AdminSupportImageState();
}

class _AdminSupportImageState extends State<_AdminSupportImage> {
  late final Future<Uint8List> _image = widget.image;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    return FutureBuilder<Uint8List>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: theme.error, size: 20),
              SizedBox(width: spacing.xs),
              Text('Impossible de charger l’image.',
                  style: theme.bodySmall.override(color: theme.error)),
            ],
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: EdgeInsets.all(spacing.sm),
              child: CircularProgressIndicator(
                color: theme.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final bytes = snapshot.data!;
        return InkWell(
          onTap: () => _showAdminSupportImage(context, bytes),
          borderRadius: BorderRadius.circular(theme.designToken.radius.sm),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.sm),
                child: Image.memory(
                  bytes,
                  width: 300,
                  height: 240,
                  fit: BoxFit.cover,
                  semanticLabel: 'Image jointe au message',
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white,
                    size: 16,
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

Future<void> _showAdminSupportImage(BuildContext context, Uint8List bytes) =>
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return AlertDialog(
          backgroundColor: theme.secondaryBackground,
          content: SizedBox(
            width: 760,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                semanticLabel: 'Image jointe au message',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );

class _InboxState extends StatelessWidget {
  const _InboxState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(theme.designToken.spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: theme.primary),
          SizedBox(height: theme.designToken.spacing.md),
          Text(message, textAlign: TextAlign.center, style: theme.bodyLarge),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.label,
    this.size = 40,
  });

  final String label;
  final double size;

  String get _initials {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getColor(BuildContext context) {
    const colors = [
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.purple,
      Colors.deepOrange,
      Colors.cyan,
      Colors.pink,
    ];
    int hash = 0;
    for (int i = 0; i < label.length; i++) {
      hash = (hash << 5) - hash + label.codeUnitAt(i);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: color,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PulsingRecordingDot extends StatefulWidget {
  const _PulsingRecordingDot({required this.color});

  final Color color;

  @override
  State<_PulsingRecordingDot> createState() => _PulsingRecordingDotState();
}

class _PulsingRecordingDotState extends State<_PulsingRecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1.0).animate(_animController),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

String _formatSupportDate(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)} '
      '${two(local.hour)}:${two(local.minute)}';
}
