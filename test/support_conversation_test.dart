import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio.dart';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_firestore.dart';

void main() {
  test('anonymous conversations use a readable label and short reference', () {
    const conversation = SupportConversation(
      '123e4567-e89b-42d3-a456-426614174000',
      {
        'user_uid': '123e4567-e89b-42d3-a456-426614174000',
        'guest_access': true,
      },
    );

    expect(conversation.isAnonymous, isTrue);
    expect(conversation.memberLabel, 'Visiteur anonyme');
    expect(conversation.memberReference, 'Réf. 174000');
    expect(conversation.memberLabel, isNot(contains('123e4567')));
  });

  test('known member identity remains unchanged', () {
    const conversation = SupportConversation('member-id', {
      'user_uid': 'member-id',
      'user_display_name': ' Marie Exemple ',
      'user_email': ' marie@example.test ',
    });

    expect(conversation.isAnonymous, isFalse);
    expect(conversation.memberLabel, 'Marie Exemple');
    expect(conversation.userEmail, 'marie@example.test');
    expect(conversation.memberReference, isEmpty);
  });

  test('treated conversations stay stored but no longer wait for an admin',
      () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {
      'user_uid': 'member',
      'status': 'open',
      'last_sender_role': 'user',
    };
    final repository = SupportConversationRepository(firestore: db);

    const pending = SupportConversation('member', {
      'user_uid': 'member',
      'status': 'open',
      'last_sender_role': 'user',
    });
    const treated = SupportConversation('member', {
      'user_uid': 'member',
      'status': 'treated',
      'last_sender_role': 'user',
    });
    expect(pending.waitingForAdmin, isTrue);
    expect(treated.isTreated, isTrue);
    expect(treated.waitingForAdmin, isFalse);
    expect(
      const SupportConversation('member', {
        'status': 'deleting',
        'last_sender_role': 'user',
      }).waitingForAdmin,
      isFalse,
    );

    await repository.markAsTreated('member');
    expect(
      db.rows['support_conversations/member']?['status'],
      'treated',
    );
    expect(db.rows, hasLength(1));
  });

  test('admin reply atomically updates summary and appends immutable message',
      () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {
      'user_uid': 'member',
      'user_email': 'member@example.test',
      'topic': 'subscription',
      'status': 'open',
      'created_at': DateTime(2026),
      'updated_at': DateTime(2026),
      'last_message': 'Comment payer ?',
      'last_message_id': 'm1',
      'last_sender_role': 'user',
    };
    final repository = SupportConversationRepository(firestore: db);

    await repository.sendAdminReply(
      conversationId: 'member',
      adminUid: 'admin',
      text: ' Vous pouvez payer par MonCash. ',
      messageId: 'a1',
    );

    expect(db.reads, [
      'support_conversations/member',
      'support_conversations/member/messages/a1'
    ]);
    expect(db.rows['support_conversations/member']!['last_message'],
        'Vous pouvez payer par MonCash.');
    expect(db.rows['support_conversations/member']!['last_message_id'], 'a1');
    expect(
        db.rows['support_conversations/member']!['last_sender_role'], 'admin');
    expect(db.rows['support_conversations/member']!['status'], 'open');
    expect(
        db.rows['support_conversations/member']!['created_at'], DateTime(2026));
    expect(db.rows['support_conversations/member/messages/a1'], {
      'sender_uid': 'admin',
      'sender_role': 'admin',
      'text': 'Vous pouvez payer par MonCash.',
      'created_at': isNotNull,
    });

    await repository.sendAdminReply(
      conversationId: 'member',
      adminUid: 'admin',
      text: 'Vous pouvez payer par MonCash.',
      messageId: 'a1',
    );
    expect(
      db.rows.keys.where((path) => path.contains('/messages/')),
      ['support_conversations/member/messages/a1'],
    );
  });

  test('missing conversation, owner mismatch and invalid reply write nothing',
      () async {
    final db = MemoryFirestore();
    final repository = SupportConversationRepository(firestore: db);

    await expectLater(
      repository.sendAdminReply(
        conversationId: 'member',
        adminUid: 'admin',
        text: 'Bonjour',
        messageId: 'a1',
      ),
      throwsStateError,
    );
    expect(db.rows, isEmpty);

    db.rows['support_conversations/member'] = {'user_uid': 'foreign'};
    await expectLater(
      repository.sendAdminReply(
        conversationId: 'member',
        adminUid: 'admin',
        text: 'Bonjour',
        messageId: 'a2',
      ),
      throwsStateError,
    );
    await expectLater(
      repository.sendAdminReply(
        conversationId: 'member',
        adminUid: '',
        text: 'Bonjour',
        messageId: 'a3',
      ),
      throwsArgumentError,
    );
    expect(db.rows.keys, ['support_conversations/member']);
  });

  test('admin image reply writes its immutable attachment atomically',
      () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {'user_uid': 'member'};
    final repository = SupportConversationRepository(firestore: db);
    final image = Uint8List.fromList([1, 2, 3]);

    await repository.sendAdminReply(
      conversationId: 'member',
      adminUid: 'admin',
      text: 'Photo',
      image: image,
      messageId: 'photo-1',
    );

    expect(db.rows['support_conversations/member/messages/photo-1'],
        containsPair('attachment_type', 'image'));
    expect(
      db.rows[
          'support_conversations/member/messages/photo-1/attachments/image'],
      {
        'base64': 'AQID',
        'mime_type': 'image/jpeg',
        'byte_length': 3,
      },
    );
  });

  test('admin voice reply writes WAV metadata and rejects two attachments',
      () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {'user_uid': 'member'};
    final repository = SupportConversationRepository(firestore: db);
    final audio = SupportAudio.fromPcm(Uint8List(16000));

    await repository.sendAdminReply(
      conversationId: 'member',
      adminUid: 'admin',
      text: 'Note vocale',
      audio: audio,
      messageId: 'voice-1',
    );

    expect(db.rows['support_conversations/member/messages/voice-1'],
        containsPair('attachment_type', 'audio'));
    expect(
      db.rows['support_conversations/member/messages/voice-1/attachments/audio']
          ?['duration_ms'],
      1000,
    );
    await expectLater(
      repository.sendAdminReply(
        conversationId: 'member',
        adminUid: 'admin',
        text: 'Invalide',
        image: Uint8List(1),
        audio: audio,
      ),
      throwsArgumentError,
    );
  });

  test('admin edits a message and keeps the latest summary in sync', () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {
      'user_uid': 'member',
      'last_message': 'Ancienne réponse',
      'last_message_id': 'a1',
      'last_sender_role': 'admin',
    };
    db.rows['support_conversations/member/messages/a1'] = {
      'sender_uid': 'admin',
      'sender_role': 'admin',
      'text': 'Ancienne réponse',
      'created_at': DateTime(2026),
    };
    final repository = SupportConversationRepository(firestore: db);

    await repository.editAdminMessage(
      conversationId: 'member',
      messageId: 'a1',
      text: ' Réponse corrigée ',
    );

    expect(
      db.rows['support_conversations/member/messages/a1'],
      containsPair('text', 'Réponse corrigée'),
    );
    expect(
      db.rows['support_conversations/member/messages/a1']?['edited_at'],
      isNotNull,
    );
    expect(
      db.rows['support_conversations/member']?['last_message'],
      'Réponse corrigée',
    );
    expect(db.rows['support_conversations/member']?['updated_at'], isNotNull);
  });

  test('admin deletes its latest message, media and restores prior summary',
      () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {
      'user_uid': 'member',
      'last_message': 'Photo envoyée',
      'last_message_id': 'a1',
      'last_sender_role': 'admin',
    };
    db.rows['support_conversations/member/messages/u1'] = {
      'sender_uid': 'member',
      'sender_role': 'user',
      'text': 'Pouvez-vous vérifier ?',
      'created_at': DateTime(2026),
    };
    db.rows['support_conversations/member/messages/a1'] = {
      'sender_uid': 'admin',
      'sender_role': 'admin',
      'text': 'Photo envoyée',
      'attachment_type': 'image',
      'created_at': DateTime(2026, 1, 2),
    };
    db.rows['support_conversations/member/messages/a1/attachments/image'] = {
      'base64': 'AQID',
    };
    final repository = SupportConversationRepository(firestore: db);

    await repository.deleteAdminMessage(
      conversationId: 'member',
      messageId: 'a1',
      replacementMessageId: 'u1',
    );

    expect(
      db.rows,
      isNot(contains('support_conversations/member/messages/a1')),
    );
    expect(
      db.rows,
      isNot(contains(
          'support_conversations/member/messages/a1/attachments/image')),
    );
    expect(
      db.rows['support_conversations/member']?['last_message'],
      'Pouvez-vous vérifier ?',
    );
    expect(
      db.rows['support_conversations/member']?['last_message_id'],
      'u1',
    );
    expect(
      db.rows['support_conversations/member']?['last_sender_role'],
      'user',
    );
  });

  test('member messages cannot be edited or deleted through admin actions',
      () async {
    final db = MemoryFirestore();
    db.rows['support_conversations/member'] = {
      'user_uid': 'member',
      'last_message_id': 'u1',
    };
    db.rows['support_conversations/member/messages/u1'] = {
      'sender_uid': 'member',
      'sender_role': 'user',
      'text': 'Message membre',
    };
    final repository = SupportConversationRepository(firestore: db);

    await expectLater(
      repository.editAdminMessage(
        conversationId: 'member',
        messageId: 'u1',
        text: 'Modification interdite',
      ),
      throwsStateError,
    );
    await expectLater(
      repository.deleteAdminMessage(
        conversationId: 'member',
        messageId: 'u1',
      ),
      throwsStateError,
    );
    expect(
      db.rows['support_conversations/member/messages/u1']?['text'],
      'Message membre',
    );
  });
}
