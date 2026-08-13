import 'dart:convert';

import 'package:c_h_o_l_o_t_o_dashboard/tirages/official_lottery_results_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('arranges official NY and Florida games in the CHOLOTO format',
      () async {
    final service = OfficialLotteryResultsService(
      client: MockClient((request) async {
        if (_isStaticSnapshot(request)) {
          return http.Response('not generated', 404);
        }
        if (request.url.host.contains('cloudfunctions.net')) {
          return http.Response('not deployed', 404);
        }
        if (request.url.host == 'data.ny.gov') {
          return _jsonResponse([
            {
              'draw_date': '2026-08-12T00:00:00.000',
              'midday_daily': '004',
              'midday_win_4': '0102',
              'evening_daily': '536',
              'evening_win_4': '7606',
            },
          ]);
        }
        return _floridaResponse(request.url.queryParameters['id']!);
      }),
    );

    final result = await service.fetchLatest();

    expect(result.warnings, isEmpty);
    expect(result.proposals, hasLength(4));
    expect(result.proposals[0].numbers, ['004', '01', '02']);
    expect(result.proposals[1].numbers, ['536', '76', '06']);
    expect(result.proposals[2].numbers, ['05', '006', '01', '02']);
    expect(result.proposals[3].numbers, ['68', '539', '55', '91']);
    expect(
      result.proposals[2].documentId,
      'official_fl_20260812_midday',
    );
    expect(result.proposals[2].periodLabel, '01:34 PM');
    expect(result.proposals[1].periodLabel, '10:30 PM');
  });

  test('keeps the available source when the other source fails', () async {
    final service = OfficialLotteryResultsService(
      client: MockClient((request) async {
        if (_isStaticSnapshot(request)) {
          return http.Response('not generated', 404);
        }
        if (request.url.host == 'data.ny.gov') {
          return http.Response('unavailable', 503);
        }
        if (request.url.host.contains('cloudfunctions.net')) {
          return http.Response('unavailable', 502);
        }
        return _floridaResponse(request.url.queryParameters['id']!);
      }),
    );

    final result = await service.fetchLatest();

    expect(result.proposals, hasLength(2));
    expect(
      result.proposals.every(
        (proposal) => proposal.lottery == OfficialLottery.florida,
      ),
      isTrue,
    );
    expect(result.warnings.single, contains('New York'));
    expect(result.warnings.single, contains('503'));
  });

  test('uses the Firebase relay when it is available', () async {
    final service = OfficialLotteryResultsService(
      client: MockClient((request) async {
        if (_isStaticSnapshot(request)) {
          return http.Response('not generated', 404);
        }
        if (request.url.host.contains('cloudfunctions.net')) {
          return _jsonResponse([
            {
              'draw_date': '2026-08-13T00:00:00.000',
              'midday_daily': '007',
              'midday_win_4': '0123',
              'evening_daily': '890',
              'evening_win_4': '0042',
              '_choloto_source_name': 'New York Lottery',
              '_choloto_source_url':
                  'https://nylottery.ny.gov/all-winning-numbers/',
            },
          ]);
        }
        if (request.url.host == 'data.ny.gov') {
          fail('NY Open Data should not be called after a successful relay');
        }
        return _floridaResponse(request.url.queryParameters['id']!);
      }),
    );

    final result = await service.fetchLatest();

    expect(result.warnings, isEmpty);
    expect(result.proposals, hasLength(4));
    expect(result.proposals[0].numbers, ['007', '01', '23']);
    expect(result.proposals[1].numbers, ['890', '00', '42']);
    expect(result.proposals[0].sourceName, 'New York Lottery');
  });

  test('falls back to NY Open Data when the relay is unavailable', () async {
    final service = OfficialLotteryResultsService(
      client: MockClient((request) async {
        if (_isStaticSnapshot(request)) {
          return http.Response('not generated', 404);
        }
        if (request.url.host.contains('cloudfunctions.net')) {
          return http.Response('not deployed', 404);
        }
        if (request.url.host == 'data.ny.gov') {
          return _jsonResponse([
            {
              'draw_date': '2026-08-13T00:00:00.000',
              'midday_daily': '123',
              'midday_win_4': '4567',
              'evening_daily': '890',
              'evening_win_4': '0012',
            },
          ]);
        }
        return _floridaResponse(request.url.queryParameters['id']!);
      }),
    );

    final result = await service.fetchLatest();

    expect(result.warnings, isEmpty);
    expect(result.proposals[0].numbers, ['123', '45', '67']);
    expect(result.proposals[1].numbers, ['890', '00', '12']);
    expect(
      result.proposals[0].sourceName,
      'NY Open Data · Gaming Commission',
    );
  });

  test('uses the same-origin NY snapshot before remote fallbacks', () async {
    final now = DateTime.now();
    final drawDate = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T00:00:00.000';
    final service = OfficialLotteryResultsService(
      client: MockClient((request) async {
        if (_isStaticSnapshot(request)) {
          return _jsonResponse([
            {
              'draw_date': drawDate,
              'midday_daily': '128',
              'midday_win_4': '3466',
              'evening_daily': '901',
              'evening_win_4': '0075',
              '_choloto_source_name': 'New York Lottery',
              '_choloto_source_url':
                  'https://nylottery.ny.gov/all-winning-numbers/',
            },
          ]);
        }
        if (request.url.host.contains('cloudfunctions.net') ||
            request.url.host == 'data.ny.gov') {
          fail('Remote NY fallbacks should not be called after the snapshot');
        }
        return _floridaResponse(request.url.queryParameters['id']!);
      }),
    );

    final result = await service.fetchLatest();

    expect(result.warnings, isEmpty);
    expect(result.proposals, hasLength(4));
    expect(result.proposals[0].numbers, ['128', '34', '66']);
    expect(result.proposals[1].numbers, ['901', '00', '75']);
  });

  test('rejects malformed values before publication', () {
    final proposal = OfficialLotteryProposal(
      lottery: OfficialLottery.florida,
      period: OfficialDrawPeriod.midday,
      drawDate: DateTime(2026, 8, 12),
      numbers: const ['05', '006', '01', '02'],
      sourceName: 'Florida Lottery',
      sourceUrl: OfficialLotteryResultsService.floridaSourceUrl,
    );

    expect(proposal.validateNumbers(proposal.numbers), isNull);
    expect(
      proposal.validateNumbers(const ['5', '006', '01', '02']),
      contains('PK2'),
    );
    expect(
      proposal.validateNumbers(const ['05', '00A', '01', '02']),
      contains('PK3'),
    );
  });
}

http.Response _jsonResponse(Object body) => http.Response(
      jsonEncode(body),
      200,
      headers: const {'content-type': 'application/json'},
    );

bool _isStaticSnapshot(http.Request request) =>
    request.url.path.endsWith('/data/official-new-york-results.json');

http.Response _floridaResponse(String gameId) {
  final game = switch (gameId) {
    '127' => (
        name: 'PICK 2',
        midday: const [0, 5],
        evening: const [6, 8],
      ),
    '104' => (
        name: 'PICK 3',
        midday: const [0, 0, 6],
        evening: const [5, 3, 9],
      ),
    '108' => (
        name: 'PICK 4',
        midday: const [0, 1, 0, 2],
        evening: const [5, 5, 9, 1],
      ),
    _ => throw StateError('Unknown Florida game id $gameId'),
  };

  Map<String, dynamic> draw(String type, List<int> digits) => {
        'Id': gameId,
        'GameName': game.name,
        'DrawDate': '08/12/2026 12:00:00 AM',
        'DrawType': type,
        'DrawNumbers': [
          for (var index = 0; index < digits.length; index++)
            {
              'NumberPick': digits[index],
              'NumberType': 'wn${index + 1}',
            },
          // Fireball must never be included in the CHOLOTO value.
          {'NumberPick': 9, 'NumberType': 'fb'},
        ],
      };

  return _jsonResponse([
    draw('MIDDAY', game.midday),
    draw('EVENING', game.evening),
  ]);
}
