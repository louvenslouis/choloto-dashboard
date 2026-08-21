import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class UserDocumentCreationResult {
  const UserDocumentCreationResult({
    required this.email,
    required this.uid,
    required this.created,
    required this.repaired,
  });

  final String email;
  final String uid;
  final bool created;
  final bool repaired;
}

class UserDocumentCreationException implements Exception {
  const UserDocumentCreationException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class UserDocumentCreator {
  const UserDocumentCreator._();

  static Future<UserDocumentCreationResult> ensureByEmail(
    String email, {
    http.Client? client,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw const UserDocumentCreationException(
        'Votre session a expiré. Reconnectez-vous puis réessayez.',
        code: 'unauthenticated',
      );
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const UserDocumentCreationException(
        'Votre session a expiré. Reconnectez-vous puis réessayez.',
        code: 'unauthenticated',
      );
    }

    final ownsClient = client == null;
    final requestClient = client ?? http.Client();
    try {
      final projectId = Firebase.app().options.projectId;
      final response = await requestClient.post(
        Uri.https(
          'us-central1-$projectId.cloudfunctions.net',
          '/ensureUserDocumentByEmail',
        ),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {'email': normalizedEmail},
        }),
      );

      final payload = _decodePayload(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _exceptionFromPayload(payload, response.statusCode);
      }

      final error = payload['error'];
      if (error != null) {
        throw _exceptionFromPayload(payload, response.statusCode);
      }

      final data = payload['data'];
      if (data is! Map) {
        throw const UserDocumentCreationException(
          'La réponse du serveur est invalide. Réessayez.',
          code: 'invalid-response',
        );
      }

      return UserDocumentCreationResult(
        email: (data['email'] as String?) ?? normalizedEmail,
        uid: (data['uid'] as String?) ?? '',
        created: data['created'] == true,
        repaired: data['repaired'] == true,
      );
    } on UserDocumentCreationException {
      rethrow;
    } on FormatException {
      throw const UserDocumentCreationException(
        'Le serveur a renvoyé une réponse invalide. Réessayez.',
        code: 'invalid-response',
      );
    } catch (_) {
      throw const UserDocumentCreationException(
        'Impossible de joindre le service. Vérifiez la connexion et réessayez.',
        code: 'network-error',
      );
    } finally {
      if (ownsClient) requestClient.close();
    }
  }

  static Map<String, dynamic> _decodePayload(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static UserDocumentCreationException _exceptionFromPayload(
    Map<String, dynamic> payload,
    int statusCode,
  ) {
    final error = payload['error'];
    final errorMap = error is Map ? Map<String, dynamic>.from(error) : null;
    final rawCode = errorMap?['status']?.toString() ??
        errorMap?['code']?.toString() ??
        statusCode.toString();
    final code = rawCode.toLowerCase();
    final message = switch (code) {
      'unauthenticated' ||
      '401' =>
        'Votre session a expiré. Reconnectez-vous puis réessayez.',
      'permission_denied' ||
      'permission-denied' ||
      '403' =>
        'Vous n’êtes pas autorisé à ajouter un utilisateur.',
      'not_found' ||
      'not-found' ||
      '404' =>
        'Aucun compte Firebase ne correspond à cet e-mail.',
      'invalid_argument' ||
      'invalid-argument' ||
      '400' =>
        'Saisissez une adresse e-mail valide.',
      _ => 'Impossible de créer le document utilisateur. Réessayez.',
    };

    return UserDocumentCreationException(message, code: code);
  }
}
