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
  String get userEmail => (data['user_email'] as String? ?? '').trim();
  String get userDisplayName =>
      (data['user_display_name'] as String? ?? '').trim();
  String get lastMessage => data['last_message'] as String? ?? '';
  String get lastSenderRole => data['last_sender_role'] as String? ?? '';
  String get status => data['status'] as String? ?? 'open';
  DateTime? get createdAt => supportDate(data['created_at']);
  DateTime? get updatedAt => supportDate(data['updated_at']);
  bool get isTreated => status == 'treated';
  bool get isDeleting => status == 'deleting';
  bool get waitingForAdmin =>
      !isTreated && !isDeleting && lastSenderRole == 'user';
  bool get isAnonymous =>
      data['guest_access'] == true ||
      (userDisplayName.isEmpty && userEmail.isEmpty);

  String get memberLabel => userDisplayName.isNotEmpty
      ? userDisplayName
      : userEmail.isNotEmpty
          ? userEmail
          : 'Visiteur anonyme';

  /// A short, stable reference lets administrators distinguish anonymous
  /// visitors without exposing the complete technical conversation id.
  String get memberReference {
    if (!isAnonymous) return '';
    final compactId = userUid.replaceAll('-', '');
    if (compactId.isEmpty) return '';
    final start = compactId.length > 6 ? compactId.length - 6 : 0;
    return 'Réf. ${compactId.substring(start).toUpperCase()}';
  }
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
  DateTime? get editedAt => supportDate(data['edited_at']);
  bool get sentByAdmin => senderRole == 'admin';
}

class SupportConversationRepository {
  SupportConversationRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore db;

  static const _deletionPageSize = 100;
  static const _conversationListLimit = 20;
  static const _messageListLimit = 50;

  CollectionReference<Map<String, dynamic>> get conversations =>
      db.collection('support_conversations');

  String newMessageId(String conversationId) =>
      conversations.doc(conversationId).collection('messages').doc().id;

  Stream<List<SupportConversation>> watchAll() => conversations
      .orderBy('updated_at', descending: true)
      .limit(_conversationListLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SupportConversation(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => (b.updatedAt ?? DateTime(1970))
            .compareTo(a.updatedAt ?? DateTime(1970))));

  Future<void> markAsTreated(String conversationId) async {
    _validateConversationId(conversationId);
    final conversationRef = conversations.doc(conversationId);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversationRef);
      if (!snapshot.exists || snapshot.data()?['user_uid'] != conversationId) {
        throw StateError('support-conversation-missing');
      }
      if (snapshot.data()?['status'] == 'treated') return;
      transaction.update(conversationRef, {'status': 'treated'});
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    _validateConversationId(conversationId);
    final conversationRef = conversations.doc(conversationId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversationRef);
      if (!snapshot.exists) return;
      if (snapshot.data()?['user_uid'] != conversationId) {
        throw StateError('support-conversation-owner');
      }
      if (snapshot.data()?['status'] != 'deleting') {
        transaction.update(conversationRef, {'status': 'deleting'});
      }
    });

    while (true) {
      final snapshot = await conversationRef
          .collection('messages')
          .limit(_deletionPageSize)
          .get();
      if (snapshot.docs.isEmpty) break;
      final batch = db.batch();
      for (final message in snapshot.docs) {
        batch.delete(message.reference.collection('attachments').doc('image'));
        batch.delete(message.reference.collection('attachments').doc('audio'));
        batch.delete(message.reference);
      }
      await batch.commit();
    }
    await conversationRef.delete();
  }

  void _validateConversationId(String conversationId) {
    if (conversationId.isEmpty ||
        conversationId.length > 128 ||
        conversationId.contains('/')) {
      throw ArgumentError('invalid-support-conversation');
    }
  }

  Stream<List<SupportMessage>> watchMessages(String userUid) => conversations
      .doc(userUid)
      .collection('messages')
      .orderBy('created_at', descending: true)
      .limit(_messageListLimit)
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
    Uint8List? image,
    SupportAudio? audio,
    String? messageId,
  }) async {
    final normalized = text.trim();
    if (conversationId.isEmpty ||
        adminUid.isEmpty ||
        normalized.isEmpty ||
        normalized.length > 1000 ||
        (image != null && audio != null) ||
        (image != null && (image.isEmpty || image.length > maxProofBytes)) ||
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
    final imageRef = messageRef.collection('attachments').doc('image');
    final audioRef = messageRef.collection('attachments').doc('audio');
    await db.runTransaction((transaction) async {
      final conversation = await transaction.get(conversationRef);
      final existingMessage = await transaction.get(messageRef);
      final existingImage =
          image == null ? null : await transaction.get(imageRef);
      final existingAudio =
          audio == null ? null : await transaction.get(audioRef);
      if (existingMessage.exists) {
        final data = existingMessage.data();
        if (data?['sender_uid'] == adminUid &&
            data?['sender_role'] == 'admin' &&
            data?['text'] == normalized &&
            ((image == null &&
                    audio == null &&
                    data?['attachment_type'] == null) ||
                (image != null &&
                    data?['attachment_type'] == 'image' &&
                    existingImage?.data()?['base64'] == base64Encode(image)) ||
                (audio != null &&
                    data?['attachment_type'] == 'audio' &&
                    existingAudio?.data()?['base64'] ==
                        base64Encode(audio.bytes) &&
                    existingAudio?.data()?['duration_ms'] ==
                        audio.durationMs)) &&
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
        if (image != null) 'attachment_type': 'image',
        if (audio != null) 'attachment_type': 'audio',
        'created_at': FieldValue.serverTimestamp(),
      });
      if (image != null) {
        transaction.set(imageRef, {
          'base64': base64Encode(image),
          'mime_type': 'image/jpeg',
          'byte_length': image.length,
        });
      }
      if (audio != null) transaction.set(audioRef, audio.toData());
    });
  }

  Future<void> editAdminMessage({
    required String conversationId,
    required String messageId,
    required String text,
  }) async {
    _validateConversationId(conversationId);
    _validateMessageId(messageId);
    final normalized = text.trim();
    if (normalized.isEmpty || normalized.length > 1000) {
      throw ArgumentError('invalid-support-message-text');
    }

    final conversationRef = conversations.doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc(messageId);
    await db.runTransaction((transaction) async {
      final conversation = await transaction.get(conversationRef);
      final message = await transaction.get(messageRef);
      if (!conversation.exists ||
          conversation.data()?['user_uid'] != conversationId) {
        throw StateError('support-conversation-missing');
      }
      if (!message.exists || message.data()?['sender_role'] != 'admin') {
        throw StateError('support-admin-message-missing');
      }
      if (message.data()?['text'] == normalized) return;

      if (conversation.data()?['last_message_id'] == messageId) {
        transaction.update(conversationRef, {
          'updated_at': FieldValue.serverTimestamp(),
          'last_message': normalized,
        });
      }
      transaction.update(messageRef, {
        'text': normalized,
        'edited_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteAdminMessage({
    required String conversationId,
    required String messageId,
    String? replacementMessageId,
  }) async {
    _validateConversationId(conversationId);
    _validateMessageId(messageId);
    if (replacementMessageId != null) {
      _validateMessageId(replacementMessageId);
      if (replacementMessageId == messageId) {
        throw ArgumentError('invalid-support-message-replacement');
      }
    }

    final conversationRef = conversations.doc(conversationId);
    final messages = conversationRef.collection('messages');
    final messageRef = messages.doc(messageId);
    final replacementRef = replacementMessageId == null
        ? null
        : messages.doc(replacementMessageId);
    final imageRef = messageRef.collection('attachments').doc('image');
    final audioRef = messageRef.collection('attachments').doc('audio');

    await db.runTransaction((transaction) async {
      final conversation = await transaction.get(conversationRef);
      final message = await transaction.get(messageRef);
      final replacement =
          replacementRef == null ? null : await transaction.get(replacementRef);
      if (!conversation.exists ||
          conversation.data()?['user_uid'] != conversationId) {
        throw StateError('support-conversation-missing');
      }
      if (!message.exists || message.data()?['sender_role'] != 'admin') {
        throw StateError('support-admin-message-missing');
      }

      final isLastMessage =
          conversation.data()?['last_message_id'] == messageId;
      if (isLastMessage &&
          (replacement == null ||
              !replacement.exists ||
              replacement.data()?['text'] is! String ||
              replacement.data()?['sender_role'] is! String)) {
        throw StateError('support-message-replacement-missing');
      }

      transaction.delete(imageRef);
      transaction.delete(audioRef);
      transaction.delete(messageRef);
      if (isLastMessage) {
        transaction.update(conversationRef, {
          'updated_at': FieldValue.serverTimestamp(),
          'last_message': replacement!.data()!['text'],
          'last_message_id': replacement.id,
          'last_sender_role': replacement.data()!['sender_role'],
        });
      }
    });
  }

  void _validateMessageId(String messageId) {
    if (messageId.isEmpty ||
        messageId.length > 128 ||
        messageId.contains('/')) {
      throw ArgumentError('invalid-support-message');
    }
  }
}
