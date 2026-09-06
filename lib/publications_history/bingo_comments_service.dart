import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const bingoAdminReplyMaxLength = 500;

class BingoCommentEntry {
  const BingoCommentEntry({
    required this.id,
    required this.userId,
    required this.text,
    required this.displayName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.adminLiked,
    required this.adminLikedAt,
    required this.adminReply,
    required this.adminReplyAt,
    required this.likeCount,
    required this.hidden,
    required this.hiddenAt,
  });

  final String id;
  final String userId;
  final String text;
  final String displayName;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool adminLiked;
  final DateTime? adminLikedAt;
  final String adminReply;
  final DateTime? adminReplyAt;
  final int likeCount;
  final bool hidden;
  final DateTime? hiddenAt;

  bool get hasAdminReply => adminReply.isNotEmpty;

  bool get wasEdited {
    final created = createdAt;
    final updated = updatedAt;
    return created != null &&
        updated != null &&
        updated.difference(created).abs() > const Duration(seconds: 1);
  }
}

BingoCommentEntry? parseBingoCommentEntry({
  required String id,
  required Map<String, dynamic> commentData,
  Map<String, dynamic>? userData,
  int likeCount = 0,
  bool hidden = false,
}) {
  final userId = _stringValue(commentData['user']);
  final text = _stringValue(commentData['text']);
  if (userId.isEmpty || text.isEmpty) return null;

  final displayName = _stringValue(userData?['display_name']);
  final email = _stringValue(userData?['email']);

  return BingoCommentEntry(
    id: id,
    userId: userId,
    text: text,
    displayName: displayName.isNotEmpty
        ? displayName
        : email.isNotEmpty
            ? email
            : _fallbackUserLabel(userId),
    email: email,
    createdAt: _dateTimeValue(commentData['createdAt']),
    updatedAt: _dateTimeValue(commentData['updatedAt']),
    adminLiked: commentData['adminLiked'] == true,
    adminLikedAt: _dateTimeValue(commentData['adminLikedAt']),
    adminReply: _stringValue(commentData['adminReply']),
    adminReplyAt: _dateTimeValue(commentData['adminReplyAt']),
    likeCount: likeCount,
    hidden: hidden,
    hiddenAt: _dateTimeValue(commentData['hiddenAt']),
  );
}

class BingoCommentsService {
  const BingoCommentsService._();

  static Future<int> count(DocumentReference bingoReference) async {
    final snapshots = await Future.wait([
      bingoReference.collection('comments').count().get(),
      bingoReference.collection('hiddenComments').count().get(),
    ]);
    return snapshots.fold<int>(
      0,
      (total, snapshot) => total + (snapshot.count ?? 0),
    );
  }

  static Future<List<BingoCommentEntry>> load(
    DocumentReference bingoReference,
  ) async {
    final snapshots = await Future.wait([
      bingoReference
          .collection('comments')
          .orderBy('updatedAt', descending: true)
          .get(),
      bingoReference
          .collection('hiddenComments')
          .orderBy('updatedAt', descending: true)
          .get(),
    ]);
    final commentsSnapshot = snapshots[0];
    final hiddenCommentsSnapshot = snapshots[1];
    final storedComments = [
      ...commentsSnapshot.docs
          .map((document) => (document: document, hidden: false)),
      ...hiddenCommentsSnapshot.docs
          .map((document) => (document: document, hidden: true)),
    ];

    final userIds = storedComments
        .map((stored) => _stringValue(stored.document.data()['user']))
        .where((userId) => userId.isNotEmpty)
        .toSet();
    final userSnapshots = await Future.wait(
      userIds.map(
        (userId) =>
            FirebaseFirestore.instance.collection('user').doc(userId).get(),
      ),
    );
    final usersById = <String, Map<String, dynamic>>{};
    for (final snapshot in userSnapshots) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        usersById[snapshot.id] = data;
      }
    }
    final likeCounts = await Future.wait(
      storedComments.map(
        (stored) => bingoReference
            .collection('comments')
            .doc(stored.document.id)
            .collection('likes')
            .count()
            .get(),
      ),
    );
    final likeCountByCommentId = <String, int>{};
    for (var index = 0; index < storedComments.length; index++) {
      likeCountByCommentId[storedComments[index].document.id] =
          likeCounts[index].count ?? 0;
    }

    final comments = storedComments
        .map(
          (stored) => parseBingoCommentEntry(
            id: stored.document.id,
            commentData: stored.document.data(),
            userData: usersById[_stringValue(stored.document.data()['user'])],
            likeCount: likeCountByCommentId[stored.document.id] ?? 0,
            hidden: stored.hidden,
          ),
        )
        .whereType<BingoCommentEntry>()
        .toList();
    comments.sort((first, second) {
      final firstDate = first.updatedAt ?? first.createdAt;
      final secondDate = second.updatedAt ?? second.createdAt;
      if (firstDate == null) return secondDate == null ? 0 : 1;
      if (secondDate == null) return -1;
      return secondDate.compareTo(firstDate);
    });
    return List.unmodifiable(comments);
  }

  static Future<void> setAdminLike({
    required DocumentReference bingoReference,
    required String commentId,
    required bool liked,
    bool hidden = false,
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || adminId.isEmpty) {
      throw StateError('Administrator authentication is required.');
    }

    final commentReference = bingoReference
        .collection(hidden ? 'hiddenComments' : 'comments')
        .doc(commentId);
    final likeReference = bingoReference
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(adminId);
    final batch = FirebaseFirestore.instance.batch();
    if (liked) {
      batch.update(commentReference, {
        'adminLiked': true,
        'adminLikedAt': FieldValue.serverTimestamp(),
        'adminLikedBy': adminId,
      });
      batch.set(likeReference, {
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.update(commentReference, {
        'adminLiked': FieldValue.delete(),
        'adminLikedAt': FieldValue.delete(),
        'adminLikedBy': FieldValue.delete(),
      });
      batch.delete(likeReference);
    }
    await batch.commit();
  }

  static Future<void> setAdminReply({
    required DocumentReference bingoReference,
    required String commentId,
    required String reply,
    bool hidden = false,
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || adminId.isEmpty) {
      throw StateError('Administrator authentication is required.');
    }

    final normalizedReply = reply.trim();
    if (normalizedReply.length > bingoAdminReplyMaxLength) {
      throw ArgumentError.value(reply, 'reply', 'Reply is too long.');
    }

    final commentReference = bingoReference
        .collection(hidden ? 'hiddenComments' : 'comments')
        .doc(commentId);
    if (normalizedReply.isEmpty) {
      await commentReference.update({
        'adminReply': FieldValue.delete(),
        'adminReplyAt': FieldValue.delete(),
        'adminReplyBy': FieldValue.delete(),
      });
      return;
    }
    await commentReference.update({
      'adminReply': normalizedReply,
      'adminReplyAt': FieldValue.serverTimestamp(),
      'adminReplyBy': adminId,
    });
  }

  static Future<void> setHidden({
    required DocumentReference bingoReference,
    required String commentId,
    required bool hidden,
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || adminId.isEmpty) {
      throw StateError('Administrator authentication is required.');
    }

    final visibleReference =
        bingoReference.collection('comments').doc(commentId);
    final hiddenReference =
        bingoReference.collection('hiddenComments').doc(commentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final sourceReference = hidden ? visibleReference : hiddenReference;
      final source = await transaction.get(sourceReference);
      final data = source.data();
      if (!source.exists || data == null) {
        throw StateError('The comment no longer exists.');
      }

      if (hidden) {
        transaction.set(hiddenReference, {
          ...data,
          'hiddenAt': FieldValue.serverTimestamp(),
          'hiddenBy': adminId,
        });
        transaction.delete(visibleReference);
        return;
      }

      final restoredData = Map<String, dynamic>.from(data)
        ..remove('hiddenAt')
        ..remove('hiddenBy');
      transaction.set(visibleReference, restoredData);
      transaction.delete(hiddenReference);
    });
  }
}

String _stringValue(dynamic value) => value is String ? value.trim() : '';

DateTime? _dateTimeValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return value is DateTime ? value : null;
}

String _fallbackUserLabel(String userId) {
  final suffix = userId.length <= 8 ? userId : userId.substring(0, 8);
  return 'Utilisateur $suffix';
}
