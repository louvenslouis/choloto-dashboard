import 'dart:convert';
import 'dart:typed_data';

import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_inbox_widget.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_voice_recorder.dart';
import 'package:c_h_o_l_o_t_o_dashboard/flutter_flow/internationalization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_firestore.dart';

class _ImageSupportRepository extends SupportConversationRepository {
  _ImageSupportRepository() : super(firestore: MemoryFirestore());

  static final Uint8List imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  @override
  Stream<List<SupportMessage>> watchMessages(String userUid) => Stream.value([
        SupportMessage('photo', {
          'sender_uid': 'member',
          'sender_role': 'user',
          'text': 'Photo',
          'attachment_type': 'image',
          'created_at': DateTime(2026, 9, 9),
        }),
      ]);

  @override
  Future<Uint8List> loadMessageImage({
    required String conversationId,
    required String messageId,
  }) async {
    expect(conversationId, 'member');
    expect(messageId, 'photo');
    return imageBytes;
  }
}

class _ComposerRepository extends SupportConversationRepository {
  _ComposerRepository() : super(firestore: MemoryFirestore());

  String? text;
  Uint8List? image;
  SupportAudio? audio;
  String? messageId;

  @override
  Stream<List<SupportMessage>> watchMessages(String userUid) =>
      Stream.value(const []);

  @override
  String newMessageId(String conversationId) => 'attachment-1';

  @override
  Future<void> sendAdminReply({
    required String conversationId,
    required String adminUid,
    required String text,
    Uint8List? image,
    SupportAudio? audio,
    String? messageId,
  }) async {
    this.text = text;
    this.image = image;
    this.audio = audio;
    this.messageId = messageId;
  }
}

class _ActionRepository extends SupportConversationRepository {
  _ActionRepository() : super(firestore: MemoryFirestore());

  bool markedAsTreated = false;
  bool deleted = false;

  @override
  Stream<List<SupportMessage>> watchMessages(String userUid) =>
      Stream.value(const []);

  @override
  Future<void> markAsTreated(String conversationId) async {
    expect(conversationId, 'member');
    markedAsTreated = true;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    expect(conversationId, 'member');
    deleted = true;
  }
}

class _MessageActionRepository extends SupportConversationRepository {
  _MessageActionRepository() : super(firestore: MemoryFirestore());

  String? editedMessageId;
  String? editedText;
  String? deletedMessageId;
  String? replacementMessageId;

  @override
  Stream<List<SupportMessage>> watchMessages(String userUid) => Stream.value([
        SupportMessage('u1', {
          'sender_uid': 'member',
          'sender_role': 'user',
          'text': 'Question du membre',
          'created_at': DateTime(2026, 9, 18, 9),
        }),
        SupportMessage('a1', {
          'sender_uid': 'admin',
          'sender_role': 'admin',
          'text': 'Première réponse',
          'created_at': DateTime(2026, 9, 18, 9, 5),
          'edited_at': DateTime(2026, 9, 18, 9, 6),
        }),
        SupportMessage('a2', {
          'sender_uid': 'admin',
          'sender_role': 'admin',
          'text': 'Dernière réponse',
          'created_at': DateTime(2026, 9, 18, 9, 10),
        }),
      ]);

  @override
  Future<void> editAdminMessage({
    required String conversationId,
    required String messageId,
    required String text,
  }) async {
    expect(conversationId, 'member');
    editedMessageId = messageId;
    editedText = text;
  }

  @override
  Future<void> deleteAdminMessage({
    required String conversationId,
    required String messageId,
    String? replacementMessageId,
  }) async {
    expect(conversationId, 'member');
    deletedMessageId = messageId;
    this.replacementMessageId = replacementMessageId;
  }
}

class _VoiceRecorder implements SupportVoiceRecorder {
  bool recording = false;

  @override
  Future<void> start(void Function() onLimit) async => recording = true;

  @override
  Future<SupportAudio> stop() async {
    recording = false;
    return SupportAudio.fromPcm(Uint8List(16000));
  }

  @override
  Future<void> cancel() async => recording = false;

  @override
  Future<void> dispose() async => recording = false;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('support inbox list fits a narrow ${brightness.name} viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SupportConversation? opened;
      final conversation = SupportConversation('member', {
        'user_uid': 'member',
        'user_display_name': 'Marie Exemple',
        'user_email': 'marie@example.test',
        'last_message': 'Je souhaite payer mon abonnement avec MonCash.',
        'last_sender_role': 'user',
        'updated_at': DateTime(2026, 9, 6, 10, 30),
      });
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SupportConversationList(
              conversations: [conversation],
              onOpen: (value) => opened = value,
            ),
          ),
        ),
      ));

      expect(find.text('Marie Exemple'), findsOneWidget);
      expect(find.text('À répondre'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester
          .tap(find.byKey(const ValueKey('support-conversation-member')));
      expect(opened, same(conversation));
    });
  }

  testWidgets('support inbox has an explicit empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SupportConversationList(
          conversations: const [],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('Aucune conversation pour le moment.'), findsOneWidget);
  });

  testWidgets('support actions are inside the conversation and aligned right',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ActionRepository();
    const conversation = SupportConversation('member', {
      'user_uid': 'member',
      'user_display_name': 'Marie Exemple',
      'last_message': 'Pouvez-vous vérifier mon paiement ?',
      'last_sender_role': 'user',
      'status': 'open',
    });
    await tester.pumpWidget(MaterialApp(
      home: SupportConversationPage(
        conversation: conversation,
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    final treatedButton =
        find.byKey(const ValueKey('admin-support-mark-treated'));
    final deleteButton = find.byKey(const ValueKey('admin-support-delete'));
    expect(treatedButton, findsOneWidget);
    expect(deleteButton, findsOneWidget);
    expect(
      tester.getTopRight(deleteButton).dx,
      closeTo(tester.getTopRight(treatedButton).dx, .1),
    );
    expect(tester.getTopRight(deleteButton).dx, closeTo(344, .1));

    await tester.tap(treatedButton);
    await tester.pumpAndSettle();
    expect(repository.markedAsTreated, isTrue);
    expect(find.text('Traité'), findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('admin-support-confirm-delete')),
    );
    await tester.pumpAndSettle();
    expect(repository.deleted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('treated support conversation is not presented as pending',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SupportConversationList(
          conversations: const [
            SupportConversation('member', {
              'user_uid': 'member',
              'last_message': 'Merci',
              'last_sender_role': 'user',
              'status': 'treated',
            }),
          ],
          onOpen: (_) {},
        ),
      ),
    ));

    expect(find.text('Traité'), findsOneWidget);
    expect(find.text('À répondre'), findsNothing);
  });

  testWidgets('interrupted deletion stays visible in the inbox',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SupportConversationList(
          conversations: const [
            SupportConversation('member', {
              'user_uid': 'member',
              'last_message': 'Message en cours de suppression',
              'last_sender_role': 'user',
              'status': 'deleting',
            }),
          ],
          onOpen: (_) {},
        ),
      ),
    ));

    expect(find.text('Suppression…'), findsOneWidget);
    expect(find.text('À répondre'), findsNothing);
  });

  testWidgets('admin conversation displays and enlarges a received image',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ImageSupportRepository();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: SupportConversationPage(
        conversation: const SupportConversation('member', {
          'user_uid': 'member',
          'user_display_name': 'Marie Exemple',
        }),
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-support-image-photo')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('admin-support-image-photo')));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
  });

  testWidgets('administrator can select and send an image', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ComposerRepository();

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SupportConversationPage(
        conversation:
            const SupportConversation('member', {'user_uid': 'member'}),
        repository: repository,
        pickImage: () async => _ImageSupportRepository.imageBytes,
      ),
    ));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('admin-support-attach-image-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-support-selected-image')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-support-send-button')));
    await tester.pumpAndSettle();

    expect(repository.text, 'Photo');
    expect(repository.image, isNotEmpty);
    expect(repository.audio, isNull);
    expect(repository.messageId, 'attachment-1');
  });

  testWidgets('administrator can record, preview and send a voice note',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ComposerRepository();
    final recorder = _VoiceRecorder();

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SupportConversationPage(
        conversation:
            const SupportConversation('member', {'user_uid': 'member'}),
        repository: repository,
        recorderFactory: () => recorder,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-support-record-audio')));
    await tester.pump();
    expect(find.byKey(const ValueKey('admin-support-stop-recording')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('admin-support-stop-recording')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-support-remove-audio')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-support-send-button')));
    await tester.pumpAndSettle();

    expect(repository.text, 'Note vocale');
    expect(repository.image, isNull);
    expect(repository.audio?.durationMs, 1000);
    expect(repository.messageId, 'attachment-1');
  });

  testWidgets('administrator can edit and delete admin messages only',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MessageActionRepository();

    await tester.pumpWidget(MaterialApp(
      home: SupportConversationPage(
        conversation:
            const SupportConversation('member', {'user_uid': 'member'}),
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Modifié'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('admin-support-message-menu-u1')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('admin-support-message-menu-a1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('admin-support-edit-message-field')),
      'Réponse corrigée',
    );
    await tester.tap(
      find.byKey(const ValueKey('admin-support-confirm-edit-message')),
    );
    await tester.pumpAndSettle();

    expect(repository.editedMessageId, 'a1');
    expect(repository.editedText, 'Réponse corrigée');

    await tester.tap(
      find.byKey(const ValueKey('admin-support-message-menu-a2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('admin-support-confirm-delete-message')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedMessageId, 'a2');
    expect(repository.replacementMessageId, 'a1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('support inbox can filter conversations by search query',
      (tester) async {
    final conversations = [
      const SupportConversation('user1', {
        'user_uid': 'user1',
        'user_display_name': 'Alice Martin',
        'user_email': 'alice@example.test',
        'last_message': 'Question sur mon abonnement',
        'last_sender_role': 'user',
      }),
      const SupportConversation('user2', {
        'user_uid': 'user2',
        'user_display_name': 'Bob Dupont',
        'user_email': 'bob@example.test',
        'last_message': 'Paiement envoyé',
        'last_sender_role': 'user',
      }),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SupportConversationList(
            conversations: conversations,
            onOpen: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Dupont'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pumpAndSettle();

    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Dupont'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Introuvable');
    await tester.pumpAndSettle();

    expect(find.text('Aucune conversation ne correspond à vos filtres.'),
        findsOneWidget);
  });

  testWidgets('support inbox can filter by status chip', (tester) async {
    final conversations = [
      const SupportConversation('user1', {
        'user_uid': 'user1',
        'user_display_name': 'Alice Martin',
        'last_message': 'Aide SVP',
        'last_sender_role': 'user',
        'status': 'open',
      }),
      const SupportConversation('user2', {
        'user_uid': 'user2',
        'user_display_name': 'Bob Dupont',
        'last_message': 'Merci beaucoup',
        'last_sender_role': 'user',
        'status': 'treated',
      }),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SupportConversationList(
            conversations: conversations,
            onOpen: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Dupont'), findsOneWidget);

    await tester.tap(find.text('À répondre (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Dupont'), findsNothing);

    await tester.tap(find.text('Traités (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Alice Martin'), findsNothing);
    expect(find.text('Bob Dupont'), findsOneWidget);

    await tester.tap(find.text('Tous (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Dupont'), findsOneWidget);
  });

  testWidgets('canned responses populate reply input', (tester) async {
    final repository = _ComposerRepository();
    const conversation = SupportConversation('member', {
      'user_uid': 'member',
      'user_display_name': 'Marie Exemple',
      'last_message': 'Bonjour',
    });

    await tester.pumpWidget(MaterialApp(
      home: SupportConversationPage(
        conversation: conversation,
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    final cannedChip =
        find.text('👋 Bonjour ! Comment pouvons-nous vous aider ?');
    expect(cannedChip, findsOneWidget);

    await tester.tap(cannedChip);
    await tester.pumpAndSettle();

    final replyField = tester.widget<TextField>(
      find.byKey(const ValueKey('admin-support-reply-field')),
    );
    expect(
      replyField.controller?.text,
      '👋 Bonjour ! Comment pouvons-nous vous aider ?',
    );
  });

  testWidgets('support inbox renders desktop dual pane when width >= 900',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const conversation = SupportConversation('member', {
      'user_uid': 'member',
      'user_display_name': 'Marie Exemple',
      'user_email': 'marie@example.test',
      'last_message': 'Bonjour',
      'last_sender_role': 'user',
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SupportConversationList(
          conversations: const [conversation],
          selectedConversationId: 'member',
          isEmbedded: true,
          onOpen: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Marie Exemple'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // search field
  });
}
