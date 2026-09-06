import 'dart:convert';

import '/auth/firebase_auth/google_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _analyticsPropertyId = '503828194';
const _analyticsApiHost = 'analyticsdata.googleapis.com';
const _analyticsCacheDuration = Duration(minutes: 5);

class AnalyticsDailyActiveUsers {
  const AnalyticsDailyActiveUsers({
    required this.date,
    required this.activeUsers,
  });

  final DateTime date;
  final int activeUsers;
}

class AnalyticsTopScreen {
  const AnalyticsTopScreen({
    required this.name,
    required this.views,
    required this.activeUsers,
  });

  final String name;
  final int views;
  final int activeUsers;
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.generatedAt,
    required this.realtimeActiveUsers,
    required this.todayActiveUsers,
    required this.todayNewUsers,
    required this.averageSessionDurationSeconds,
    required this.activeUsers7Days,
    required this.activeUsers30Days,
    required this.dailyActiveUsers,
    required this.topScreens,
  });

  final DateTime? generatedAt;
  final int realtimeActiveUsers;
  final int todayActiveUsers;
  final int todayNewUsers;
  final double averageSessionDurationSeconds;
  final int activeUsers7Days;
  final int activeUsers30Days;
  final List<AnalyticsDailyActiveUsers> dailyActiveUsers;
  final List<AnalyticsTopScreen> topScreens;
}

class AnalyticsOverviewException implements Exception {
  const AnalyticsOverviewException(this.message, {this.code});

  final String message;
  final String? code;

  bool get requiresConfiguration =>
      code == 'failed_precondition' ||
      code == 'failed-precondition' ||
      code == '404';

  bool get requiresAuthorization =>
      code == 'authorization-required' || code == '401';

  @override
  String toString() => message;
}

AnalyticsOverview parseAnalyticsOverviewPayload(Map<String, dynamic> payload) {
  final rawData = payload['data'];
  if (rawData is! Map) {
    throw const AnalyticsOverviewException(
      'La réponse Analytics est invalide.',
      code: 'invalid-response',
    );
  }
  final data = Map<String, dynamic>.from(rawData);
  final rawToday = data['today'];
  final today = rawToday is Map
      ? Map<String, dynamic>.from(rawToday)
      : const <String, dynamic>{};

  final dailyActiveUsers = _mapList(data['dailyActiveUsers'])
      .map((row) {
        final date = DateTime.tryParse(row['date']?.toString() ?? '');
        if (date == null) return null;
        return AnalyticsDailyActiveUsers(
          date: date,
          activeUsers: _intValue(row['activeUsers']),
        );
      })
      .whereType<AnalyticsDailyActiveUsers>()
      .toList(growable: false)
    ..sort((first, second) => first.date.compareTo(second.date));

  final topScreens = _mapList(data['topScreens'])
      .map(
        (row) => AnalyticsTopScreen(
          name: _screenName(row['name']),
          views: _intValue(row['views']),
          activeUsers: _intValue(row['activeUsers']),
        ),
      )
      .toList(growable: false);

  return AnalyticsOverview(
    generatedAt: DateTime.tryParse(data['generatedAt']?.toString() ?? ''),
    realtimeActiveUsers: _intValue(data['realtimeActiveUsers']),
    todayActiveUsers: _intValue(today['activeUsers']),
    todayNewUsers: _intValue(today['newUsers']),
    averageSessionDurationSeconds:
        _doubleValue(today['averageSessionDurationSeconds']),
    activeUsers7Days: _intValue(data['activeUsers7Days']),
    activeUsers30Days: _intValue(data['activeUsers30Days']),
    dailyActiveUsers: dailyActiveUsers,
    topScreens: topScreens,
  );
}

class AnalyticsOverviewService {
  const AnalyticsOverviewService._();

  static AnalyticsOverview? _cachedOverview;
  static DateTime? _cacheExpiresAt;
  static String? _cachedUserId;

  static Future<AnalyticsOverview> load({
    http.Client? client,
    bool forceRefresh = false,
    String? accessToken,
  }) async {
    final currentUser =
        accessToken == null ? FirebaseAuth.instance.currentUser : null;
    if (currentUser == null && accessToken == null) {
      throw const AnalyticsOverviewException(
        'Votre session a expiré.',
        code: 'unauthenticated',
      );
    }

    final token = accessToken ?? cachedGoogleAnalyticsAccessToken;
    if (token == null || token.trim().isEmpty) {
      throw const AnalyticsOverviewException(
        'Autorisez votre compte Google à consulter Analytics.',
        code: 'authorization-required',
      );
    }

    final cacheUserId = currentUser?.uid ?? 'injected-token';
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedOverview != null &&
        _cachedUserId == cacheUserId &&
        _cacheExpiresAt?.isAfter(now) == true) {
      return _cachedOverview!;
    }

    final ownsClient = client == null;
    final requestClient = client ?? http.Client();
    try {
      final responses = await Future.wait([
        _postAnalytics(
          client: requestClient,
          path: '/v1beta/properties/$_analyticsPropertyId:batchRunReports',
          accessToken: token,
          body: _analyticsReportRequests(),
        ),
        _postAnalytics(
          client: requestClient,
          path: '/v1beta/properties/$_analyticsPropertyId:runRealtimeReport',
          accessToken: token,
          body: const {
            'metrics': [
              {'name': 'activeUsers'},
            ],
          },
        ),
      ]);
      final overview = _buildAnalyticsOverview(responses[0], responses[1]);
      _cachedOverview = overview;
      _cachedUserId = cacheUserId;
      _cacheExpiresAt = now.add(_analyticsCacheDuration);
      return overview;
    } on AnalyticsOverviewException {
      rethrow;
    } on FormatException {
      throw const AnalyticsOverviewException(
        'La réponse Analytics est invalide.',
        code: 'invalid-response',
      );
    } catch (_) {
      throw const AnalyticsOverviewException(
        'Impossible de charger Google Analytics.',
        code: 'network-error',
      );
    } finally {
      if (ownsClient) requestClient.close();
    }
  }

  static Future<AnalyticsOverview> authorizeAndLoad({
    http.Client? client,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw const AnalyticsOverviewException(
        'Votre session a expiré.',
        code: 'unauthenticated',
      );
    }
    String? accessToken;
    try {
      accessToken = await authorizeGoogleAnalyticsAccess();
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'popup-closed-by-user'
          ? 'L’autorisation Google Analytics a été annulée.'
          : 'Impossible d’obtenir l’autorisation Google Analytics.';
      throw AnalyticsOverviewException(
        message,
        code: 'authorization-required',
      );
    }
    if (accessToken == null || accessToken.isEmpty) {
      throw const AnalyticsOverviewException(
        'L’autorisation Google Analytics a été annulée.',
        code: 'authorization-required',
      );
    }
    return load(
      client: client,
      forceRefresh: true,
      accessToken: accessToken,
    );
  }

  static void clearCache() {
    _cachedOverview = null;
    _cacheExpiresAt = null;
    _cachedUserId = null;
  }
}

Future<Map<String, dynamic>> _postAnalytics({
  required http.Client client,
  required String path,
  required String accessToken,
  required Map<String, dynamic> body,
}) async {
  final response = await client.post(
    Uri.https(_analyticsApiHost, path),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  final payload = _decodeJsonObject(response.body);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    if (response.statusCode == 401) {
      clearGoogleAnalyticsAccessToken();
    }
    throw _analyticsException(response.statusCode);
  }
  return payload;
}

Map<String, dynamic> _decodeJsonObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('Expected a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

AnalyticsOverviewException _analyticsException(int statusCode) {
  return switch (statusCode) {
    401 => const AnalyticsOverviewException(
        'Votre autorisation Google Analytics doit être renouvelée.',
        code: 'authorization-required',
      ),
    403 => const AnalyticsOverviewException(
        'Ce compte Google n’a pas accès à la propriété Analytics CHOLOTO.',
        code: 'permission-denied',
      ),
    404 => const AnalyticsOverviewException(
        'La propriété Google Analytics CHOLOTO est introuvable.',
        code: '404',
      ),
    429 => const AnalyticsOverviewException(
        'Le quota Google Analytics est temporairement atteint.',
        code: 'resource-exhausted',
      ),
    _ => const AnalyticsOverviewException(
        'Impossible de charger Google Analytics.',
        code: 'network-error',
      ),
  };
}

Map<String, dynamic> _analyticsReportRequests() {
  return {
    'requests': [
      {
        'dateRanges': [
          {'startDate': 'today', 'endDate': 'today'},
        ],
        'metrics': [
          {'name': 'activeUsers'},
          {'name': 'newUsers'},
          {'name': 'averageSessionDuration'},
        ],
      },
      {
        'dateRanges': [
          {'startDate': '6daysAgo', 'endDate': 'today'},
        ],
        'metrics': [
          {'name': 'activeUsers'},
        ],
      },
      {
        'dateRanges': [
          {'startDate': '29daysAgo', 'endDate': 'today'},
        ],
        'metrics': [
          {'name': 'activeUsers'},
        ],
      },
      {
        'dateRanges': [
          {'startDate': '29daysAgo', 'endDate': 'today'},
        ],
        'dimensions': [
          {'name': 'date'},
        ],
        'metrics': [
          {'name': 'activeUsers'},
        ],
        'orderBys': [
          {
            'dimension': {'dimensionName': 'date'},
          },
        ],
      },
      {
        'dateRanges': [
          {'startDate': '29daysAgo', 'endDate': 'today'},
        ],
        'dimensions': [
          {'name': 'unifiedScreenName'},
        ],
        'metrics': [
          {'name': 'screenPageViews'},
          {'name': 'activeUsers'},
        ],
        'orderBys': [
          {
            'metric': {'metricName': 'screenPageViews'},
            'desc': true,
          },
        ],
        'limit': '5',
      },
    ],
  };
}

AnalyticsOverview _buildAnalyticsOverview(
  Map<String, dynamic> batchPayload,
  Map<String, dynamic> realtimePayload,
) {
  final reports = _mapList(batchPayload['reports']);
  final today = _reportAt(reports, 0);
  final last7Days = _reportAt(reports, 1);
  final last30Days = _reportAt(reports, 2);
  final trend = _reportAt(reports, 3);
  final screens = _reportAt(reports, 4);

  return AnalyticsOverview(
    generatedAt: DateTime.now().toUtc(),
    realtimeActiveUsers: _reportMetric(realtimePayload, 0).round(),
    todayActiveUsers: _reportMetric(today, 0).round(),
    todayNewUsers: _reportMetric(today, 1).round(),
    averageSessionDurationSeconds: _reportMetric(today, 2),
    activeUsers7Days: _reportMetric(last7Days, 0).round(),
    activeUsers30Days: _reportMetric(last30Days, 0).round(),
    dailyActiveUsers: _reportRows(trend)
        .map((row) {
          final date = _analyticsDate(_dimensionValue(row));
          if (date == null) return null;
          return AnalyticsDailyActiveUsers(
            date: date,
            activeUsers: _metricValue(row, 0).round(),
          );
        })
        .whereType<AnalyticsDailyActiveUsers>()
        .toList(growable: false),
    topScreens: _reportRows(screens)
        .map(
          (row) => AnalyticsTopScreen(
            name: _screenName(_dimensionValue(row)),
            views: _metricValue(row, 0).round(),
            activeUsers: _metricValue(row, 1).round(),
          ),
        )
        .toList(growable: false),
  );
}

Map<String, dynamic>? _reportAt(
  List<Map<String, dynamic>> reports,
  int index,
) =>
    index >= 0 && index < reports.length ? reports[index] : null;

List<Map<String, dynamic>> _reportRows(Map<String, dynamic>? report) =>
    _mapList(report?['rows']);

double _reportMetric(Map<String, dynamic>? report, int index) {
  final rows = _reportRows(report);
  return rows.isEmpty ? 0 : _metricValue(rows.first, index);
}

double _metricValue(Map<String, dynamic> row, int index) {
  final values = _mapList(row['metricValues']);
  if (index < 0 || index >= values.length) return 0;
  return double.tryParse(values[index]['value']?.toString() ?? '') ?? 0;
}

String _dimensionValue(Map<String, dynamic> row) {
  final values = _mapList(row['dimensionValues']);
  return values.isEmpty ? '' : values.first['value']?.toString().trim() ?? '';
}

DateTime? _analyticsDate(String value) {
  if (!RegExp(r'^\d{8}$').hasMatch(value)) return null;
  return DateTime.tryParse(
    '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}',
  );
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}

int _intValue(dynamic value) {
  if (value is num) return value.round();
  return num.tryParse(value?.toString() ?? '')?.round() ?? 0;
}

double _doubleValue(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _screenName(dynamic value) {
  final name = value?.toString().trim() ?? '';
  return name.isEmpty ? 'Écran non identifié' : name;
}
