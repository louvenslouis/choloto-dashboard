import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class UserAuthProviderException implements Exception {
  const UserAuthProviderException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

Map<String, List<String>> parseUserAuthProvidersPayload(
  Map<String, dynamic> payload,
) {
  final data = payload['data'];
  if (data is! Map) {
    throw const UserAuthProviderException(
      'La réponse du serveur est invalide.',
      code: 'invalid-response',
    );
  }

  final providers = data['providers'];
  if (providers is! Map) {
    throw const UserAuthProviderException(
      'La réponse du serveur est invalide.',
      code: 'invalid-response',
    );
  }

  return providers.map((uid, rawProviders) {
    if (uid is! String || rawProviders is! List) {
      throw const UserAuthProviderException(
        'La réponse du serveur est invalide.',
        code: 'invalid-response',
      );
    }

    final normalizedProviders = rawProviders
        .whereType<String>()
        .map((provider) => provider.trim())
        .where((provider) => provider.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return MapEntry(uid, normalizedProviders);
  });
}

class UserAuthProviderService {
  const UserAuthProviderService._();

  static const _batchSize = 100;

  static Future<Map<String, List<String>>> loadForUserIds(
    Iterable<String> userIds, {
    http.Client? client,
  }) async {
    final normalizedUserIds = userIds
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedUserIds.isEmpty) return const {};

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw const UserAuthProviderException(
        'Votre session a expiré.',
        code: 'unauthenticated',
      );
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const UserAuthProviderException(
        'Votre session a expiré.',
        code: 'unauthenticated',
      );
    }

    final ownsClient = client == null;
    final requestClient = client ?? http.Client();
    final providersByUid = <String, List<String>>{};

    try {
      final projectId = Firebase.app().options.projectId;
      for (var offset = 0;
          offset < normalizedUserIds.length;
          offset += _batchSize) {
        final end = (offset + _batchSize).clamp(0, normalizedUserIds.length);
        final batch = normalizedUserIds.sublist(offset, end);
        final response = await requestClient.post(
          Uri.https(
            'us-central1-$projectId.cloudfunctions.net',
            '/getUserAuthProviders',
          ),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {'uids': batch},
          }),
        );

        final payload = _decodePayload(response.body);
        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            payload['error'] != null) {
          throw _exceptionFromPayload(payload, response.statusCode);
        }
        providersByUid.addAll(parseUserAuthProvidersPayload(payload));
      }

      return providersByUid;
    } on UserAuthProviderException {
      rethrow;
    } on FormatException {
      throw const UserAuthProviderException(
        'La réponse du serveur est invalide.',
        code: 'invalid-response',
      );
    } catch (_) {
      throw const UserAuthProviderException(
        'Impossible de charger les méthodes de connexion.',
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

  static UserAuthProviderException _exceptionFromPayload(
    Map<String, dynamic> payload,
    int statusCode,
  ) {
    final error = payload['error'];
    final errorMap = error is Map ? Map<String, dynamic>.from(error) : null;
    final rawCode = errorMap?['status']?.toString() ??
        errorMap?['code']?.toString() ??
        statusCode.toString();
    final code = rawCode.toLowerCase();

    return UserAuthProviderException(
      switch (code) {
        'unauthenticated' || '401' => 'Votre session a expiré.',
        'permission_denied' ||
        'permission-denied' ||
        '403' =>
          'Vous n’êtes pas autorisé à consulter ces informations.',
        _ => 'Impossible de charger les méthodes de connexion.',
      },
      code: code,
    );
  }
}
