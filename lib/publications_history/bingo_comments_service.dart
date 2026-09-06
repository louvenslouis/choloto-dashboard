import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bingoAdminReplyMaxLength = 500;

class BingoActivitySnapshot {
  BingoActivitySnapshot({
    required Iterable<String> commentIds,
    required Iterable<String> reactionIds,
    Iterable<String> seenCommentIds = const [],
    Iterable<String> seenReactionIds = const [],
  })  : commentIds = Set.unmodifiable(commentIds),
        reactionIds = Set.unmodifiable(reactionIds),
        newCommentIds = Set.unmodifiable(
          commentIds.toSet().difference(seenCommentIds.toSet()),
        ),
        newReactionIds = Set.unmodifiable(
          reactionIds.toSet().difference(seenReactionIds.toSet()),
        );

  final Set<String> commentIds;
  final Set<String> reactionIds;
  final Set<String> newCommentIds;
  final Set<String> newReactionIds;

  int get commentCount => commentIds.length;
  int get reactionCount => reactionIds.length;
  int get newCommentCount => newCommentIds.length;
  int get newReactionCount => newReactionIds.length;
  int get newActivityCount => newCommentCount + newReactionCount;
  bool get hasNewActivity => newActivityCount > 0;
}

class BingoActivityOverview {
  const BingoActivityOverview({
    required this.commentCount,
    required this.reactionCount,
    required this.newCommentCount,
    required this.newReactionCount,
    required this.bingoWithNewActivityCount,
  });

  final int commentCount;
  final int reactionCount;
  final int newCommentCount;
  final int newReactionCount;
  final int bingoWithNewActivityCount;

  int get newActivityCount => newCommentCount + newReactionCount;
  bool get hasNewActivity => newActivityCount > 0;
}

class BingoActivityService {
  const BingoActivityService._();

  static const _preferencePrefix = 'choloto_admin_bingo_activity_v1';
  static const _dashboardPublicationLimit = 20;

  static Future<BingoActivitySnapshot> load(
    DocumentReference bingoReference,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    return _loadWithPreferences(bingoReference, preferences);
  }

  static Future<BingoActivitySnapshot> _loadWithPreferences(
    DocumentReference bingoReference,
    SharedPreferences preferences,
  ) async {
    final snapshots = await Future.wait([
      bingoReference.collection('comments').get(),
      bingoReference.collection('hiddenComments').get(),
      bingoReference.collection('bingostats').get(),
    ]);

    final commentIds = {
      ...snapshots[0].docs.map((document) => document.id),
      ...snapshots[1].docs.map((document) => document.id),
    };
    final reactionIds =
        snapshots[2].docs.map((document) => document.id).toSet();

    return BingoActivitySnapshot(
      commentIds: commentIds,
      reactionIds: reactionIds,
      seenCommentIds:
          preferences.getStringList(_key(bingoReference, 'comments')) ??
              const [],
      seenReactionIds:
          preferences.getStringList(_key(bingoReference, 'reactions')) ??
              const [],
    );
  }

  static Future<BingoActivityOverview> loadOverview() async {
    final bingoSnapshot = await FirebaseFirestore.instance
        .collection('bingo')
        .orderBy('date', descending: true)
        .limit(_dashboardPublicationLimit)
        .get();
    final preferences = await SharedPreferences.getInstance();
    final activities = await Future.wait(
      bingoSnapshot.docs.map(
        (document) => _loadWithPreferences(document.reference, preferences),
      ),
    );

    var commentCount = 0;
    var reactionCount = 0;
    var newCommentCount = 0;
    var newReactionCount = 0;
    var bingoWithNewActivityCount = 0;
    for (final activity in activities) {
      commentCount += activity.commentCount;
      reactionCount += activity.reactionCount;
      newCommentCount += activity.newCommentCount;
      newReactionCount += activity.newReactionCount;
      if (activity.hasNewActivity) bingoWithNewActivityCount++;
    }

    return BingoActivityOverview(
      commentCount: commentCount,
      reactionCount: reactionCount,
      newCommentCount: newCommentCount,
      newReactionCount: newReactionCount,
      bingoWithNewActivityCount: bingoWithNewActivityCount,
    );
  }

  static Future<void> markCommentsSeen(
    DocumentReference bingoReference,
    Iterable<String> commentIds,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key(bingoReference, 'comments'),
      commentIds.toSet().toList()..sort(),
    );
  }

  static Future<void> markReactionsSeen(
    DocumentReference bingoReference,
    Iterable<String> reactionIds,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key(bingoReference, 'reactions'),
      reactionIds.toSet().toList()..sort(),
    );
  }

  static String _key(DocumentReference bingoReference, String activityType) {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'local-admin';
    final bingoPath = bingoReference.path.replaceAll('/', '__');
    return '${_preferencePrefix}_${adminId}_${bingoPath}_$activityType';
  }
}

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
