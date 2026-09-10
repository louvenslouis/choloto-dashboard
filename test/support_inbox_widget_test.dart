import 'dart:convert';
import 'dart:typed_data';

import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_inbox_widget.dart';
import 'package:flutter/material.dart';
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
}
