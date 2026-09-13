import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation_retention.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCleanupStore implements SupportConversationCleanupStore {
  _MemoryCleanupStore({
    required this.conversationUpdatedAt,
    required this.messageCreatedAt,
  });

  final Map<String, DateTime> conversationUpdatedAt;
  final Map<String, Map<String, DateTime>> messageCreatedAt;
  final List<String> operations = [];
  DateTime? receivedCutoff;

  @override
  Future<List<String>> findExpiredConversationIds(
    DateTime cutoff, {
    int limit = 20,
  }) async {
    receivedCutoff = cutoff;
    return conversationUpdatedAt.entries
        .where((entry) => !entry.value.isAfter(cutoff))
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  Future<List<String>> findExpiredMessageIds(
    String conversationId,
    DateTime cutoff, {
    int limit = 100,
  }) async =>
      (messageCreatedAt[conversationId] ?? const {})
          .entries
          .where((entry) => !entry.value.isAfter(cutoff))
          .take(limit)
          .map((entry) => entry.key)
          .toList();

  @override
  Future<void> deleteMessageTrees(
    String conversationId,
    List<String> messageIds,
  ) async {
    for (final messageId in messageIds) {
      operations.add('message:$conversationId/$messageId');
      messageCreatedAt[conversationId]?.remove(messageId);
    }
  }

  @override
  Future<bool> deleteConversationIfExpired(
    String conversationId,
    DateTime cutoff,
  ) async {
    final updatedAt = conversationUpdatedAt[conversationId];
    if (updatedAt == null || updatedAt.isAfter(cutoff)) return false;
    operations.add('conversation:$conversationId');
    conversationUpdatedAt.remove(conversationId);
    return true;
  }
}

void main() {
  test('a launch removes complete conversations inactive for 15 days',
      () async {
    final now = DateTime.utc(2026, 9, 12, 12);
    final store = _MemoryCleanupStore(
      conversationUpdatedAt: {
        'expired': now.subtract(const Duration(days: 15)),
        'active': now.subtract(const Duration(days: 14, hours: 23)),
      },
      messageCreatedAt: {
        'expired': {
          'text': now.subtract(const Duration(days: 16)),
          'image': now.subtract(const Duration(days: 15)),
        },
        'active': {'recent': now.subtract(const Duration(days: 1))},
      },
    );

    final deleted = await SupportConversationRetentionService(store: store)
        .deleteExpiredConversations(now: now);

    expect(deleted, 1);
    expect(store.receivedCutoff, DateTime.utc(2026, 8, 28, 12));
    expect(store.operations, [
      'message:expired/text',
      'message:expired/image',
      'conversation:expired',
    ]);
    expect(store.conversationUpdatedAt, contains('active'));
    expect(store.messageCreatedAt['active'], contains('recent'));
  });

  test('a conversation reactivated during cleanup is kept', () async {
    final now = DateTime.utc(2026, 9, 12, 12);
    final store = _MemoryCleanupStore(
      conversationUpdatedAt: {
        'reactivated': now.subtract(const Duration(days: 16)),
      },
      messageCreatedAt: {
        'reactivated': {'old': now.subtract(const Duration(days: 16))},
      },
    );
    final originalDelete = store.deleteMessageTrees;
    final reactivatingStore = _ReactivatingCleanupStore(
      delegate: store,
      now: now,
      onDelete: originalDelete,
    );

    final deleted = await SupportConversationRetentionService(
      store: reactivatingStore,
    ).deleteExpiredConversations(now: now);

    expect(deleted, 0);
    expect(store.conversationUpdatedAt, contains('reactivated'));
  });
}

class _ReactivatingCleanupStore implements SupportConversationCleanupStore {
  _ReactivatingCleanupStore({
    required this.delegate,
    required this.now,
    required this.onDelete,
  });

  final _MemoryCleanupStore delegate;
  final DateTime now;
  final Future<void> Function(String, List<String>) onDelete;

  @override
  Future<List<String>> findExpiredConversationIds(DateTime cutoff,
          {int limit = 20}) =>
      delegate.findExpiredConversationIds(cutoff, limit: limit);

  @override
  Future<List<String>> findExpiredMessageIds(
          String conversationId, DateTime cutoff,
          {int limit = 100}) =>
      delegate.findExpiredMessageIds(conversationId, cutoff, limit: limit);

  @override
  Future<void> deleteMessageTrees(
      String conversationId, List<String> messageIds) async {
    await onDelete(conversationId, messageIds);
    delegate.conversationUpdatedAt[conversationId] = now;
  }

  @override
  Future<bool> deleteConversationIfExpired(
          String conversationId, DateTime cutoff) =>
      delegate.deleteConversationIfExpired(conversationId, cutoff);
}
