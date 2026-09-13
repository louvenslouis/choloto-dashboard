import 'package:cloud_firestore/cloud_firestore.dart';

const supportConversationRetention = Duration(days: 15);

abstract class SupportConversationCleanupStore {
  Future<List<String>> findExpiredConversationIds(
    DateTime cutoff, {
    int limit,
  });

  Future<List<String>> findExpiredMessageIds(
    String conversationId,
    DateTime cutoff, {
    int limit,
  });

  Future<void> deleteMessageTrees(
    String conversationId,
    List<String> messageIds,
  );

  Future<bool> deleteConversationIfExpired(
    String conversationId,
    DateTime cutoff,
  );
}

class FirestoreSupportConversationCleanupStore
    implements SupportConversationCleanupStore {
  FirestoreSupportConversationCleanupStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _conversationPageSize = 20;
  static const _messagePageSize = 100;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('support_conversations');

  @override
  Future<List<String>> findExpiredConversationIds(
    DateTime cutoff, {
    int limit = _conversationPageSize,
  }) async {
    final snapshot = await _conversations
        .where(
          'updated_at',
          isLessThanOrEqualTo: Timestamp.fromDate(cutoff),
        )
        .limit(limit)
        .get();
    return snapshot.docs.map((document) => document.id).toList();
  }

  @override
  Future<List<String>> findExpiredMessageIds(
    String conversationId,
    DateTime cutoff, {
    int limit = _messagePageSize,
  }) async {
    final snapshot = await _conversations
        .doc(conversationId)
        .collection('messages')
        .where(
          'created_at',
          isLessThanOrEqualTo: Timestamp.fromDate(cutoff),
        )
        .limit(limit)
        .get();
    return snapshot.docs.map((document) => document.id).toList();
  }

  @override
  Future<void> deleteMessageTrees(
    String conversationId,
    List<String> messageIds,
  ) async {
    final batch = _firestore.batch();
    for (final messageId in messageIds) {
      final message = _conversations
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);
      batch.delete(message.collection('attachments').doc('image'));
      batch.delete(message.collection('attachments').doc('audio'));
      batch.delete(message);
    }
    await batch.commit();
  }

  @override
  Future<bool> deleteConversationIfExpired(
    String conversationId,
    DateTime cutoff,
  ) =>
      _firestore.runTransaction((transaction) async {
        final conversation = _conversations.doc(conversationId);
        final snapshot = await transaction.get(conversation);
        final updatedAt = snapshot.data()?['updated_at'];
        if (!snapshot.exists ||
            updatedAt is! Timestamp ||
            updatedAt.toDate().isAfter(cutoff)) {
          return false;
        }
        transaction.delete(conversation);
        return true;
      });
}

class SupportConversationRetentionService {
  SupportConversationRetentionService({SupportConversationCleanupStore? store})
      : _store = store ?? FirestoreSupportConversationCleanupStore();

  final SupportConversationCleanupStore _store;

  Future<int> deleteExpiredConversations({DateTime? now}) async {
    final cutoff =
        (now ?? DateTime.now()).subtract(supportConversationRetention);
    var deletedConversations = 0;

    while (true) {
      final conversationIds = await _store.findExpiredConversationIds(cutoff);
      if (conversationIds.isEmpty) return deletedConversations;

      for (final conversationId in conversationIds) {
        while (true) {
          final messageIds =
              await _store.findExpiredMessageIds(conversationId, cutoff);
          if (messageIds.isEmpty) break;
          await _store.deleteMessageTrees(conversationId, messageIds);
        }
        if (await _store.deleteConversationIfExpired(conversationId, cutoff)) {
          deletedConversations += 1;
        }
      }
    }
  }
}
