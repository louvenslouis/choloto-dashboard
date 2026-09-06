import 'package:c_h_o_l_o_t_o_dashboard/publications_history/bingo_comments_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a stored Bingo comment and its author profile', () {
    final createdAt = DateTime(2026, 8, 23, 9, 30);
    final updatedAt = DateTime(2026, 8, 23, 9, 35);

    final comment = parseBingoCommentEntry(
      id: 'user-123',
      commentData: {
        'user': ' user-123 ',
        'text': ' Mwen te genyen avèk CHOLOTO. ',
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'adminLiked': true,
        'adminLikedAt': updatedAt,
        'adminReply': 'Merci pour votre confiance !',
        'adminReplyAt': updatedAt,
      },
      userData: {
        'display_name': ' Maeva ',
        'email': 'maeva@example.com',
      },
      likeCount: 4,
    );

    expect(comment, isNotNull);
    expect(comment!.userId, 'user-123');
    expect(comment.text, 'Mwen te genyen avèk CHOLOTO.');
    expect(comment.displayName, 'Maeva');
    expect(comment.email, 'maeva@example.com');
    expect(comment.createdAt, createdAt);
    expect(comment.updatedAt, updatedAt);
    expect(comment.wasEdited, isTrue);
    expect(comment.adminLiked, isTrue);
    expect(comment.adminLikedAt, updatedAt);
    expect(comment.adminReply, 'Merci pour votre confiance !');
    expect(comment.adminReplyAt, updatedAt);
    expect(comment.hasAdminReply, isTrue);
    expect(comment.likeCount, 4);
    expect(comment.hidden, isFalse);
    expect(comment.hiddenAt, isNull);
  });

  test('uses a stable author fallback when the profile is missing', () {
    final comment = parseBingoCommentEntry(
      id: 'comment-id',
      commentData: {
        'user': 'abcdefghijk',
        'text': 'Bravo !',
      },
    );

    expect(comment, isNotNull);
    expect(comment!.displayName, 'Utilisateur abcdefgh');
    expect(comment.email, isEmpty);
    expect(comment.wasEdited, isFalse);
    expect(comment.adminLiked, isFalse);
    expect(comment.hasAdminReply, isFalse);
    expect(comment.likeCount, 0);
  });

  test('maps an archived comment as hidden for the moderation list', () {
    final hiddenAt = DateTime(2026, 8, 30, 10, 15);
    final comment = parseBingoCommentEntry(
      id: 'hidden-comment',
      commentData: {
        'user': 'user-123',
        'text': 'Commentaire à modérer',
        'hiddenAt': hiddenAt,
      },
      hidden: true,
    );

    expect(comment, isNotNull);
    expect(comment!.hidden, isTrue);
    expect(comment.hiddenAt, hiddenAt);
  });

  test('ignores malformed or empty comment documents', () {
    expect(
      parseBingoCommentEntry(
        id: 'empty-comment',
        commentData: const {'user': 'user-123', 'text': '   '},
      ),
      isNull,
    );
    expect(
      parseBingoCommentEntry(
        id: 'missing-owner',
        commentData: const {'text': 'Commentaire sans propriétaire'},
      ),
      isNull,
    );
  });
}
