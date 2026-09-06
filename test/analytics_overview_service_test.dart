import 'dart:convert';

import 'package:c_h_o_l_o_t_o_dashboard/dashboard/analytics_overview_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses the aggregated GA4 overview', () {
    final overview = parseAnalyticsOverviewPayload({
      'data': {
        'generatedAt': '2026-08-23T17:00:00.000Z',
        'realtimeActiveUsers': 4,
        'today': {
          'activeUsers': 21,
          'newUsers': 7,
          'averageSessionDurationSeconds': 132.5,
        },
        'activeUsers7Days': 83,
        'activeUsers30Days': 240,
        'dailyActiveUsers': [
          {'date': '2026-08-22', 'activeUsers': 18},
          {'date': '2026-08-23', 'activeUsers': 21},
        ],
        'topScreens': [
          {'name': 'Home', 'views': 92, 'activeUsers': 40},
          {'name': 'Tirages', 'views': 71, 'activeUsers': 32},
        ],
      },
    });

    expect(overview.realtimeActiveUsers, 4);
    expect(overview.todayActiveUsers, 21);
    expect(overview.todayNewUsers, 7);
    expect(overview.averageSessionDurationSeconds, 132.5);
    expect(overview.activeUsers7Days, 83);
    expect(overview.activeUsers30Days, 240);
    expect(overview.dailyActiveUsers.last.activeUsers, 21);
    expect(overview.topScreens.first.name, 'Home');
    expect(overview.topScreens.first.views, 92);
  });

  test('loads the overview directly from Google Analytics Data API', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-access-token');
      expect(request.method, 'POST');

      if (request.url.path.endsWith(':runRealtimeReport')) {
        return http.Response(
          jsonEncode({
            'rows': [
              {
                'metricValues': [
                  {'value': '3'},
                ],
              },
            ],
          }),
          200,
        );
      }

      expect(request.url.path, contains(':batchRunReports'));
      return http.Response(
        jsonEncode({
          'reports': [
            {
              'rows': [
                {
                  'metricValues': [
                    {'value': '12'},
                    {'value': '4'},
                    {'value': '95.5'},
                  ],
                },
              ],
            },
            {
              'rows': [
                {
                  'metricValues': [
                    {'value': '61'},
                  ],
                },
              ],
            },
            {
              'rows': [
                {
                  'metricValues': [
                    {'value': '190'},
                  ],
                },
              ],
            },
            {
              'rows': [
                {
                  'dimensionValues': [
                    {'value': '20260823'},
                  ],
                  'metricValues': [
                    {'value': '12'},
                  ],
                },
              ],
            },
            {
              'rows': [
                {
                  'dimensionValues': [
                    {'value': 'Accueil'},
                  ],
                  'metricValues': [
                    {'value': '80'},
                    {'value': '35'},
                  ],
                },
              ],
            },
          ],
        }),
        200,
      );
    });

    final overview = await AnalyticsOverviewService.load(
      client: client,
      accessToken: 'test-access-token',
      forceRefresh: true,
    );

    expect(overview.realtimeActiveUsers, 3);
    expect(overview.todayActiveUsers, 12);
    expect(overview.todayNewUsers, 4);
    expect(overview.averageSessionDurationSeconds, 95.5);
    expect(overview.activeUsers7Days, 61);
    expect(overview.activeUsers30Days, 190);
    expect(overview.dailyActiveUsers.single.date, DateTime(2026, 8, 23));
    expect(overview.topScreens.single.name, 'Accueil');
  });

  test('maps a denied Analytics request to a permission error', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'error': 'denied'}), 403),
    );

    expect(
      () => AnalyticsOverviewService.load(
        client: client,
        accessToken: 'test-access-token',
        forceRefresh: true,
      ),
      throwsA(
        isA<AnalyticsOverviewException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  test('rejects a malformed Analytics payload', () {
    expect(
      () => parseAnalyticsOverviewPayload(const {}),
      throwsA(isA<AnalyticsOverviewException>()),
    );
  });
}
