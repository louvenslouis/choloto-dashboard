import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio.dart';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_firestore.dart';

void main() {
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
}
