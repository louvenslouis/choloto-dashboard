import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'support_conversation.dart';
import 'support_audio_player.dart';
import 'support_text.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    final desktop = MediaQuery.sizeOf(context).width >= 992;
    return Scaffold(
      key: _scaffold,
      backgroundColor: theme.primaryBackground,
      drawer: desktop
          ? null
          : const Drawer(child: SidenavWidget(forceVisible: true)),
      appBar: desktop ? null : const AdminMobileAppBar(title: 'Service client'),
      bottomNavigationBar: desktop
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
              child: Center(
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
                      StreamBuilder<List<SupportConversation>>(
                        stream: _repository.watchAll(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const AdminSurface(
                              child: _InboxState(
                                icon: Icons.cloud_off_rounded,
                                message:
                                    'Impossible de charger les conversations. Vérifiez la connexion et les droits administrateur.',
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                  color: theme.primary),
                            );
                          }
                          return SupportConversationList(
                            conversations: snapshot.data!,
                            onOpen: (conversation) =>
                                Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SupportConversationPage(
                                  conversation: conversation,
                                  repository: _repository,
                                ),
                              ),
                            ),
                          );
                        },
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
}

class SupportConversationList extends StatelessWidget {
  const SupportConversationList({
    super.key,
    required this.conversations,
    required this.onOpen,
  });

  final List<SupportConversation> conversations;
  final ValueChanged<SupportConversation> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    if (conversations.isEmpty) {
      return const AdminSurface(
        child: _InboxState(
          icon: Icons.forum_outlined,
          message: 'Aucune conversation pour le moment.',
        ),
      );
    }
    return Column(
      children: [
        for (final conversation in conversations)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.md),
            child: AdminSurface(
              borderColor: conversation.waitingForAdmin
                  ? theme.warning.withValues(alpha: .55)
                  : null,
              child: ListTile(
                key: ValueKey('support-conversation-${conversation.id}'),
                contentPadding: EdgeInsets.zero,
                leading: AdminIconTile(
                  icon: conversation.waitingForAdmin
                      ? Icons.mark_unread_chat_alt_rounded
                      : Icons.mark_chat_read_rounded,
                  color: conversation.waitingForAdmin
                      ? theme.warning
                      : theme.success,
                ),
                title: Text(conversation.memberLabel, style: theme.titleMedium),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (conversation.userEmail.isNotEmpty &&
                        conversation.userEmail != conversation.memberLabel)
                      Text(
                        conversation.userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelMedium
                            .override(color: theme.secondaryText),
                      ),
                    SizedBox(height: spacing.xs),
                    Text(
                      conversation.lastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AdminStatusPill(
                      compact: true,
                      label: conversation.waitingForAdmin
                          ? 'À répondre'
                          : 'Répondu',
                      color: conversation.waitingForAdmin
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
                onTap: () => onOpen(conversation),
              ),
            ),
          ),
      ],
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
  });

  final SupportConversation conversation;
  final SupportConversationRepository repository;

  @override
  State<SupportConversationPage> createState() =>
      _SupportConversationPageState();
}

class _SupportConversationPageState extends State<SupportConversationPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  String? _error;
  int _messageCount = 0;

  @override
  void dispose() {
    _controller.dispose();
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_sending || text.isEmpty || text.length > 1000) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.sendAdminReply(
        conversationId: widget.conversation.id,
        adminUid: currentUserUid,
        text: text,
      );
      if (mounted) _controller.clear();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Réponse non envoyée. Vérifiez votre connexion et vos droits.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        foregroundColor: theme.primaryText,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.memberLabel, style: theme.titleMedium),
            if (widget.conversation.userEmail.isNotEmpty)
              Text(
                widget.conversation.userEmail,
                style: theme.labelSmall.override(color: theme.secondaryText),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<SupportMessage>>(
                    stream:
                        widget.repository.watchMessages(widget.conversation.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _InboxState(
                          icon: Icons.cloud_off_rounded,
                          message: 'Impossible de charger les messages.',
                        );
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child:
                              CircularProgressIndicator(color: theme.primary),
                        );
                      }
                      final messages = snapshot.data!;
                      _scrollToLatest(messages.length);
                      return ListView.builder(
                        key: const ValueKey('admin-support-message-list'),
                        controller: _scrollController,
                        padding: EdgeInsets.all(spacing.md),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _AdminMessageBubble(
                          message: messages[index],
                          conversationId: widget.conversation.id,
                          repository: widget.repository,
                        ),
                      );
                    },
                  ),
                ),
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
                          child: Text(_error!,
                              style:
                                  theme.bodySmall.override(color: theme.error)),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('admin-support-reply-field'),
                              controller: _controller,
                              enabled: !_sending,
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
                          SizedBox(width: spacing.sm),
                          IconButton.filled(
                            key: const ValueKey('admin-support-send-button'),
                            onPressed: _sending ? null : _send,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMessageBubble extends StatelessWidget {
  const _AdminMessageBubble({
    required this.message,
    required this.conversationId,
    required this.repository,
  });

  final SupportMessage message;
  final String conversationId;
  final SupportConversationRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final spacing = theme.designToken.spacing;
    final fromAdmin = message.sentByAdmin;
    return Align(
      alignment: fromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: EdgeInsets.only(bottom: spacing.md),
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: fromAdmin ? theme.primary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(theme.designToken.radius.md),
          border: fromAdmin ? null : Border.all(color: theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fromAdmin ? 'Administration CHOLOTO' : 'Membre',
              style: theme.labelSmall.override(
                color: fromAdmin ? theme.info : theme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
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
              Text(
                _formatSupportDate(message.createdAt),
                style: theme.labelSmall.override(
                  color: fromAdmin
                      ? theme.info.withValues(alpha: .7)
                      : theme.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.designToken.radius.sm),
            child: Image.memory(
              bytes,
              width: 300,
              height: 240,
              fit: BoxFit.cover,
              semanticLabel: 'Image jointe au message',
            ),
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

String _formatSupportDate(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)} '
      '${two(local.hour)}:${two(local.minute)}';
}
