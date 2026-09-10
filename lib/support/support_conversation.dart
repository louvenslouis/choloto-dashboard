import 'support_audio.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/payments/payment_request.dart' show maxProofBytes;

DateTime? supportDate(Object? value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
        ? value
        : null;

class SupportConversation {
  const SupportConversation(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  String get userUid => data['user_uid'] as String? ?? id;
  String get userEmail => data['user_email'] as String? ?? '';
  String get userDisplayName => data['user_display_name'] as String? ?? '';
  String get lastMessage => data['last_message'] as String? ?? '';
  String get lastSenderRole => data['last_sender_role'] as String? ?? '';
  DateTime? get createdAt => supportDate(data['created_at']);
  DateTime? get updatedAt => supportDate(data['updated_at']);
  bool get waitingForAdmin => lastSenderRole == 'user';
  String get memberLabel => userDisplayName.isNotEmpty
      ? userDisplayName
      : userEmail.isNotEmpty
          ? userEmail
          : userUid;
}

class SupportMessage {
  const SupportMessage(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  String get senderUid => data['sender_uid'] as String? ?? '';
  String get senderRole => data['sender_role'] as String? ?? '';
  String get text => data['text'] as String? ?? '';
  bool get hasImage => data['attachment_type'] == 'image';
  bool get hasAudio => data['attachment_type'] == 'audio';
  DateTime? get createdAt => supportDate(data['created_at']);
  bool get sentByAdmin => senderRole == 'admin';
}

class SupportConversationRepository {
  SupportConversationRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get conversations =>
      db.collection('support_conversations');

  Stream<List<SupportConversation>> watchAll() =>
      conversations.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => SupportConversation(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => (b.updatedAt ?? DateTime(1970))
            .compareTo(a.updatedAt ?? DateTime(1970))));

  Stream<List<SupportMessage>> watchMessages(String userUid) => conversations
      .doc(userUid)
      .collection('messages')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SupportMessage(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(1970))
            .compareTo(b.createdAt ?? DateTime(1970))));

  Future<Uint8List> loadMessageImage({
    required String conversationId,
    required String messageId,
  }) async {
    final snapshot = await conversations
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .collection('attachments')
        .doc('image')
        .get();
    final data = snapshot.data();
    if (data == null ||
        data['base64'] is! String ||
        (data['base64'] as String).length > 800000) {
      throw const FormatException('support-image-unavailable');
    }
    final bytes = base64Decode(data['base64'] as String);
    if (bytes.isEmpty || bytes.length > maxProofBytes) {
      throw const FormatException('invalid-support-image');
    }
    return bytes;
  }

  Future<SupportAudio> loadMessageAudio(
      {required String conversationId, required String messageId}) async {
    final snapshot = await conversations
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .collection('attachments')
        .doc('audio')
        .get();
    return SupportAudio.fromData(snapshot.data());
  }

  Future<void> sendAdminReply({
    required String conversationId,
    required String adminUid,
    required String text,
    String? messageId,
  }) async {
    final normalized = text.trim();
    if (conversationId.isEmpty ||
        adminUid.isEmpty ||
        normalized.isEmpty ||
        normalized.length > 1000 ||
        (messageId != null &&
            (messageId.isEmpty ||
                messageId.length > 128 ||
                messageId.contains('/')))) {
      throw ArgumentError('invalid-support-reply');
    }

    final conversationRef = conversations.doc(conversationId);
    final resolvedMessageId =
        messageId ?? conversationRef.collection('messages').doc().id;
    final messageRef =
        conversationRef.collection('messages').doc(resolvedMessageId);
    await db.runTransaction((transaction) async {
      final conversation = await transaction.get(conversationRef);
      final existingMessage = await transaction.get(messageRef);
      if (existingMessage.exists) {
        final data = existingMessage.data();
        if (data?['sender_uid'] == adminUid &&
            data?['sender_role'] == 'admin' &&
            data?['text'] == normalized &&
            conversation.data()?['last_message_id'] == resolvedMessageId) {
          return;
        }
        throw StateError('support-message-id');
      }
      if (!conversation.exists ||
          conversation.data()?['user_uid'] != conversationId) {
        throw StateError('support-conversation-missing');
      }
      transaction.update(conversationRef, {
        'status': 'open',
        'updated_at': FieldValue.serverTimestamp(),
        'last_message': normalized,
        'last_message_id': resolvedMessageId,
        'last_sender_role': 'admin',
      });
      transaction.set(messageRef, {
        'sender_uid': adminUid,
        'sender_role': 'admin',
        'text': normalized,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
