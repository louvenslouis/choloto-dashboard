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
}
