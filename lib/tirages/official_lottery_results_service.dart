import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum OfficialLottery {
  newYork,
  florida,
  texas,
  maryland,
  georgia,
  tennessee,
  pennsylvania,
  newJersey,
}

enum OfficialDrawPeriod { morning, midday, day, evening, night }

class OfficialLotteryProposal {
  const OfficialLotteryProposal({
    required this.lottery,
    required this.period,
    required this.drawDate,
    required this.numbers,
    required this.sourceName,
    required this.sourceUrl,
  });

  final OfficialLottery lottery;
  final OfficialDrawPeriod period;
  final DateTime drawDate;
  final List<String> numbers;
  final String sourceName;
  final String sourceUrl;

  String get lotteryCode => switch (lottery) {
        OfficialLottery.newYork => 'ny',
        OfficialLottery.florida => 'fl',
        OfficialLottery.texas => 'tx',
        OfficialLottery.maryland => 'md',
        OfficialLottery.georgia => 'ga',
        OfficialLottery.tennessee => 'tn',
        OfficialLottery.pennsylvania => 'pa',
        OfficialLottery.newJersey => 'nj',
      };

  String get lotteryLabel => switch (lottery) {
        OfficialLottery.newYork => 'New York',
        OfficialLottery.florida => 'Floride',
        OfficialLottery.texas => 'Texas',
        OfficialLottery.maryland => 'Maryland',
        OfficialLottery.georgia => 'Georgia',
        OfficialLottery.tennessee => 'Tennessee',
        OfficialLottery.pennsylvania => 'Pennsylvania',
        OfficialLottery.newJersey => 'New Jersey',
      };

  String get periodLabel => switch ((lottery, period)) {
        (OfficialLottery.newYork, OfficialDrawPeriod.midday) => '02:30 PM',
        (OfficialLottery.newYork, OfficialDrawPeriod.evening) => '10:30 PM',
        (OfficialLottery.florida, OfficialDrawPeriod.midday) => '01:34 PM',
        (OfficialLottery.florida, OfficialDrawPeriod.evening) => '09:49 PM',
        (OfficialLottery.texas, OfficialDrawPeriod.morning) => 'MORNING',
        (OfficialLottery.texas, OfficialDrawPeriod.day) => 'DAY',
        (OfficialLottery.texas, OfficialDrawPeriod.evening) => 'EVENING',
        (OfficialLottery.texas, OfficialDrawPeriod.night) => 'NIGHT',
        (OfficialLottery.maryland, OfficialDrawPeriod.midday) => 'MIDDAY',
        (OfficialLottery.maryland, OfficialDrawPeriod.evening) => 'EVENING',
        (OfficialLottery.georgia, OfficialDrawPeriod.midday) => 'MIDDAY',
        (OfficialLottery.georgia, OfficialDrawPeriod.evening) => 'EVENING',
        (OfficialLottery.georgia, OfficialDrawPeriod.night) => 'NIGHT',
        (OfficialLottery.tennessee, OfficialDrawPeriod.morning) => 'MORNING',
        (OfficialLottery.tennessee, OfficialDrawPeriod.midday) => 'MIDDAY',
        (OfficialLottery.tennessee, OfficialDrawPeriod.evening) => 'EVENING',
        (OfficialLottery.pennsylvania, OfficialDrawPeriod.day) => 'DAY',
        (OfficialLottery.pennsylvania, OfficialDrawPeriod.evening) => 'EVENING',
        (OfficialLottery.newJersey, OfficialDrawPeriod.midday) => 'MIDDAY',
        (OfficialLottery.newJersey, OfficialDrawPeriod.evening) => 'EVENING',
        _ => period.name.toUpperCase(),
      };

  String get periodSourceLabel => switch (period) {
        OfficialDrawPeriod.midday => 'MIDDAY',
        OfficialDrawPeriod.evening => 'EVENING',
        OfficialDrawPeriod.morning => 'MORNING',
        OfficialDrawPeriod.day => 'DAY',
        OfficialDrawPeriod.night => 'NIGHT',
      };

  List<String> get fieldLabels => switch (lottery) {
        OfficialLottery.newYork => const ['3CF', '2LO', '3LO'],
        OfficialLottery.florida => const [
            'PK2',
            'PK3',
            'PK4 · 1–2',
            'PK4 · 3–4',
          ],
        _ => const ['3CF', '2LO', '3LO'],
      };

  List<int> get expectedLengths => switch (lottery) {
        OfficialLottery.newYork => const [3, 2, 2],
        OfficialLottery.florida => const [2, 3, 2, 2],
        _ => const [3, 2, 2],
      };

  List<OfficialDrawPeriod> get availablePeriods => switch (lottery) {
        OfficialLottery.newYork ||
        OfficialLottery.florida ||
        OfficialLottery.maryland ||
        OfficialLottery.newJersey =>
          const [
            OfficialDrawPeriod.midday,
            OfficialDrawPeriod.evening,
          ],
        OfficialLottery.texas => const [
            OfficialDrawPeriod.morning,
            OfficialDrawPeriod.day,
            OfficialDrawPeriod.evening,
            OfficialDrawPeriod.night,
          ],
        OfficialLottery.georgia => const [
            OfficialDrawPeriod.midday,
            OfficialDrawPeriod.evening,
            OfficialDrawPeriod.night,
          ],
        OfficialLottery.tennessee => const [
            OfficialDrawPeriod.morning,
            OfficialDrawPeriod.midday,
            OfficialDrawPeriod.evening,
          ],
        OfficialLottery.pennsylvania => const [
            OfficialDrawPeriod.day,
            OfficialDrawPeriod.evening,
          ],
      };

  DateTime get drawDateTime {
    final (hour, minute) = switch ((lottery, period)) {
      (OfficialLottery.newYork, OfficialDrawPeriod.midday) => (14, 30),
      (OfficialLottery.newYork, OfficialDrawPeriod.evening) => (22, 30),
      (OfficialLottery.florida, OfficialDrawPeriod.midday) => (13, 34),
      (OfficialLottery.florida, OfficialDrawPeriod.evening) => (21, 49),
      (OfficialLottery.texas, OfficialDrawPeriod.morning) => (10, 0),
      (OfficialLottery.texas, OfficialDrawPeriod.day) => (12, 27),
      (OfficialLottery.texas, OfficialDrawPeriod.evening) => (18, 0),
      (OfficialLottery.texas, OfficialDrawPeriod.night) => (22, 12),
      (OfficialLottery.maryland, OfficialDrawPeriod.midday) => (12, 30),
      (OfficialLottery.maryland, OfficialDrawPeriod.evening) => (19, 56),
      (OfficialLottery.georgia, OfficialDrawPeriod.midday) => (12, 29),
      (OfficialLottery.georgia, OfficialDrawPeriod.evening) => (18, 59),
      (OfficialLottery.georgia, OfficialDrawPeriod.night) => (23, 34),
      (OfficialLottery.tennessee, OfficialDrawPeriod.morning) => (10, 28),
      (OfficialLottery.tennessee, OfficialDrawPeriod.midday) => (13, 28),
      (OfficialLottery.tennessee, OfficialDrawPeriod.evening) => (18, 28),
      (OfficialLottery.pennsylvania, OfficialDrawPeriod.day) => (13, 35),
      (OfficialLottery.pennsylvania, OfficialDrawPeriod.evening) => (18, 59),
      (OfficialLottery.newJersey, OfficialDrawPeriod.midday) => (12, 59),
      (OfficialLottery.newJersey, OfficialDrawPeriod.evening) => (22, 57),
      _ => (12, 0),
    };
    return DateTime(
      drawDate.year,
      drawDate.month,
      drawDate.day,
      hour,
      minute,
    );
  }

  String get documentId {
    final date = '${drawDate.year.toString().padLeft(4, '0')}'
        '${drawDate.month.toString().padLeft(2, '0')}'
        '${drawDate.day.toString().padLeft(2, '0')}';
    return 'official_${lotteryCode}_${date}_${period.name}';
  }

  String? validateNumbers(List<String> values) {
    if (values.length != expectedLengths.length) {
      return 'Le nombre de résultats est incorrect.';
    }
    for (var index = 0; index < values.length; index++) {
      final value = values[index].trim();
      if (!RegExp(r'^\d+$').hasMatch(value) ||
          value.length != expectedLengths[index]) {
        return '${fieldLabels[index]} doit contenir exactement '
            '${expectedLengths[index]} chiffre${expectedLengths[index] > 1 ? 's' : ''}.';
      }
    }
    return null;
  }

  OfficialLotteryProposal copyWithNumbers(List<String> values) =>
      OfficialLotteryProposal(
        lottery: lottery,
        period: period,
        drawDate: drawDate,
        numbers: List<String>.unmodifiable(
          values.map((value) => value.trim()),
        ),
        sourceName: sourceName,
        sourceUrl: sourceUrl,
      );
}

class OfficialLotteryFetchResult {
  const OfficialLotteryFetchResult({
    required this.proposals,
    required this.warnings,
  });

  final List<OfficialLotteryProposal> proposals;
  final List<String> warnings;
}

class OfficialLotteryResultsService {
  OfficialLotteryResultsService({
    http.Client? client,
    this.includeAdditionalLotteries = true,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const newYorkSourceUrl = 'https://data.ny.gov/d/hsys-3def';
  static const floridaSourceUrl =
      'https://floridalottery.com/games/winning-numbers/history';
  static const additionalLotteriesSourceUrl =
      'data/official-additional-lottery-results.json';

  static final Uri _newYorkApiUrl = Uri.https(
    'data.ny.gov',
    '/resource/hsys-3def.json',
    const {
      r'$limit': '7',
      r'$order': 'draw_date DESC',
    },
  );

  static final Uri _newYorkRelayUrl = Uri.https(
    'us-central1-choloto-6aa5b.cloudfunctions.net',
    '/officialNewYorkResults',
  );

  static Uri get _newYorkStaticSnapshotUrl =>
      Uri.base.resolve('data/official-new-york-results.json');

  static final Uri _newYorkScheduledSnapshotUrl = Uri.https(
    'louvenslouis.github.io',
    '/choloto-dashboard/data/official-new-york-results.json',
  );

  static Uri get _additionalStaticSnapshotUrl =>
      Uri.base.resolve(additionalLotteriesSourceUrl);

  static final Uri _additionalScheduledSnapshotUrl = Uri.https(
    'louvenslouis.github.io',
    '/choloto-dashboard/data/official-additional-lottery-results.json',
  );

  static Uri _floridaApiUrl(String gameId) => Uri.https(
        'apim-website-prod-eastus.azure-api.net',
        '/drawgamesapp/getLatestDrawGames',
        {'id': gameId},
      );

  final http.Client _client;
  final bool _ownsClient;
  final bool includeAdditionalLotteries;

  Future<OfficialLotteryFetchResult> fetchLatest() async {
    final sourceLoads = <Future<_SourceLoad>>[
      _loadSource('New York', _fetchNewYork),
      _loadSource('Floride', _fetchFlorida),
      if (includeAdditionalLotteries)
        _loadSource('Autres loteries', _fetchAdditionalLotteries),
    ];
    final loads = await Future.wait(sourceLoads);

    final warnings = <String>[];
    final proposals = <OfficialLotteryProposal>[];
    for (final load in loads) {
      proposals.addAll(load.proposals);
      if (load.warning != null) warnings.add(load.warning!);
    }

    final latestBySlot = <String, OfficialLotteryProposal>{};
    for (final proposal in proposals) {
      final slot = '${proposal.lotteryCode}_${proposal.period.name}';
      final previous = latestBySlot[slot];
      if (previous == null || proposal.drawDate.isAfter(previous.drawDate)) {
        latestBySlot[slot] = proposal;
      }
    }

    final ordered = <OfficialLotteryProposal>[];
    for (final lottery in OfficialLottery.values) {
      final template = OfficialLotteryProposal(
        lottery: lottery,
        period: OfficialDrawPeriod.midday,
        drawDate: DateTime(2000),
        numbers: const [],
        sourceName: '',
        sourceUrl: '',
      );
      for (final period in template.availablePeriods) {
        final slot = '${template.lotteryCode}_${period.name}';
        final proposal = latestBySlot[slot];
        if (proposal != null) ordered.add(proposal);
      }
    }

    return OfficialLotteryFetchResult(
      proposals: List.unmodifiable(ordered),
      warnings: List.unmodifiable(warnings),
    );
  }

  Future<_SourceLoad> _loadSource(
    String sourceLabel,
    Future<List<OfficialLotteryProposal>> Function() loader,
  ) async {
    try {
      return _SourceLoad(proposals: await loader());
    } catch (error) {
      return _SourceLoad(
        proposals: const [],
        warning: '$sourceLabel : ${_readableError(error)}',
      );
    }
  }

  Future<List<OfficialLotteryProposal>> _fetchNewYork() async {
    final rows = await _fetchNewYorkRows();
    final proposals = <OfficialLotteryProposal>[];

    for (final value in rows) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final drawDate = _parseIsoDate(row['draw_date']);
      if (drawDate == null) continue;

      _appendNewYorkProposal(
        proposals,
        row: row,
        drawDate: drawDate,
        period: OfficialDrawPeriod.midday,
        dailyField: 'midday_daily',
        win4Field: 'midday_win_4',
      );
      _appendNewYorkProposal(
        proposals,
        row: row,
        drawDate: drawDate,
        period: OfficialDrawPeriod.evening,
        dailyField: 'evening_daily',
        win4Field: 'evening_win_4',
      );
    }

    if (proposals.isEmpty) {
      throw const FormatException(
        'aucun résultat complet Daily Numbers + Win 4 reçu',
      );
    }
    return proposals;
  }

  Future<List<dynamic>> _fetchNewYorkRows() async {
    Object? snapshotError;
    try {
      return await _requestFreshNewYorkSnapshot(_newYorkStaticSnapshotUrl);
    } catch (error) {
      snapshotError = error;
    }

    Object? scheduledSnapshotError;
    try {
      return await _requestFreshNewYorkSnapshot(
        _newYorkScheduledSnapshotUrl,
      );
    } catch (error) {
      scheduledSnapshotError = error;
    }

    Object? relayError;
    try {
      return await _requestJsonList(
        _newYorkRelayUrl,
        headers: const {'Accept': 'application/json'},
      );
    } catch (error) {
      relayError = error;
    }

    try {
      return await _requestJsonList(
        _newYorkApiUrl,
        headers: const {'Accept': 'application/json'},
      );
    } catch (directError) {
      throw HttpException(
        'copie web indisponible (${_readableError(snapshotError)}), '
        'miroir planifié indisponible '
        '(${_readableError(scheduledSnapshotError)}), '
        'relais indisponible (${_readableError(relayError)}), '
        'puis source directe indisponible (${_readableError(directError)})',
      );
    }
  }

  Future<List<dynamic>> _requestFreshNewYorkSnapshot(Uri url) async {
    final rows = await _requestJsonList(
      url,
      headers: const {'Accept': 'application/json'},
    );

    DateTime? latestDate;
    for (final value in rows) {
      if (value is! Map) continue;
      final date = _parseIsoDate(value['draw_date']);
      if (date != null && (latestDate == null || date.isAfter(latestDate))) {
        latestDate = date;
      }
    }
    if (latestDate == null) {
      throw const FormatException('copie web NY sans date valide');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.difference(latestDate).inDays > 2) {
      throw const FormatException('copie web NY trop ancienne');
    }
    return rows;
  }

  void _appendNewYorkProposal(
    List<OfficialLotteryProposal> target, {
    required Map<String, dynamic> row,
    required DateTime drawDate,
    required OfficialDrawPeriod period,
    required String dailyField,
    required String win4Field,
  }) {
    final daily = _digits(row[dailyField]);
    final win4 = _digits(row[win4Field]);
    if (daily.length != 3 || win4.length != 4) return;

    final sourceName = row['_choloto_source_name']?.toString().trim();
    final sourceUrl = row['_choloto_source_url']?.toString().trim();

    target.add(
      OfficialLotteryProposal(
        lottery: OfficialLottery.newYork,
        period: period,
        drawDate: drawDate,
        numbers: List.unmodifiable([
          daily,
          win4.substring(0, 2),
          win4.substring(2, 4),
        ]),
        sourceName: sourceName?.isNotEmpty == true
            ? sourceName!
            : 'NY Open Data · Gaming Commission',
        sourceUrl:
            sourceUrl?.isNotEmpty == true ? sourceUrl! : newYorkSourceUrl,
      ),
    );
  }

  Future<List<OfficialLotteryProposal>> _fetchFlorida() async {
    final responses = await Future.wait([
      _requestJsonList(
        _floridaApiUrl('127'),
        headers: const {'Accept': 'application/json', 'x-partner': 'web'},
      ),
      _requestJsonList(
        _floridaApiUrl('104'),
        headers: const {'Accept': 'application/json', 'x-partner': 'web'},
      ),
      _requestJsonList(
        _floridaApiUrl('108'),
        headers: const {'Accept': 'application/json', 'x-partner': 'web'},
      ),
    ]);

    final gamesByDraw = <String, _FloridaGames>{};
    for (var gameIndex = 0; gameIndex < responses.length; gameIndex++) {
      final expectedDigits = gameIndex + 2;
      for (final value in responses[gameIndex]) {
        if (value is! Map) continue;
        final row = Map<String, dynamic>.from(value);
        final drawDate = _parseFloridaDate(row['DrawDate']);
        final period = _parseFloridaPeriod(row['DrawType']);
        final winningNumber = _parseFloridaWinningNumber(
          row['DrawNumbers'],
          expectedDigits,
        );
        if (drawDate == null || period == null || winningNumber == null) {
          continue;
        }

        final key = '${drawDate.year}-${drawDate.month}-${drawDate.day}'
            '-${period.name}';
        final games = gamesByDraw.putIfAbsent(
          key,
          () => _FloridaGames(drawDate: drawDate, period: period),
        );
        switch (expectedDigits) {
          case 2:
            games.pick2 = winningNumber;
          case 3:
            games.pick3 = winningNumber;
          case 4:
            games.pick4 = winningNumber;
        }
      }
    }

    final proposals = <OfficialLotteryProposal>[];
    for (final games in gamesByDraw.values) {
      if (!games.isComplete) continue;
      proposals.add(
        OfficialLotteryProposal(
          lottery: OfficialLottery.florida,
          period: games.period,
          drawDate: games.drawDate,
          numbers: List.unmodifiable([
            games.pick2!,
            games.pick3!,
            games.pick4!.substring(0, 2),
            games.pick4!.substring(2, 4),
          ]),
          sourceName: 'Florida Lottery',
          sourceUrl: floridaSourceUrl,
        ),
      );
    }

    if (proposals.isEmpty) {
      throw const FormatException(
        'aucun tirage complet Pick 2 + Pick 3 + Pick 4 reçu',
      );
    }
    return proposals;
  }

  Future<List<OfficialLotteryProposal>> _fetchAdditionalLotteries() async {
    Object? staticError;
    List<dynamic>? rows;
    try {
      rows = await _requestJsonList(
        _additionalStaticSnapshotUrl,
        headers: const {'Accept': 'application/json'},
      );
    } catch (error) {
      staticError = error;
    }

    if (rows == null) {
      try {
        rows = await _requestJsonList(
          _additionalScheduledSnapshotUrl,
          headers: const {'Accept': 'application/json'},
        );
      } catch (scheduledError) {
        throw HttpException(
          'copie web indisponible '
          '(${_readableError(staticError ?? const HttpException('inconnue'))}), '
          'puis miroir planifié indisponible '
          '(${_readableError(scheduledError)})',
        );
      }
    }

    final proposals = <OfficialLotteryProposal>[];
    for (final value in rows) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final lottery = _parseAdditionalLottery(row['lottery']);
      final period = _parseAdditionalPeriod(row['period']);
      final drawDate = _parseIsoDate(row['draw_date']);
      final pick3 = _digits(row['pick3']);
      final pick4 = _digits(row['pick4']);
      if (lottery == null ||
          period == null ||
          drawDate == null ||
          pick3.length != 3 ||
          pick4.length != 4 ||
          !_supportsPeriod(lottery, period)) {
        continue;
      }

      proposals.add(
        OfficialLotteryProposal(
          lottery: lottery,
          period: period,
          drawDate: drawDate,
          numbers: List.unmodifiable([
            pick3,
            pick4.substring(0, 2),
            pick4.substring(2, 4),
          ]),
          sourceName: row['source_name']?.toString().trim().isNotEmpty == true
              ? row['source_name'].toString().trim()
              : '${_lotteryLabel(lottery)} Lottery',
          sourceUrl: row['source_url']?.toString().trim() ?? '',
        ),
      );
    }

    if (proposals.isEmpty) {
      throw const FormatException(
        'aucun résultat complet Pick 3 + Pick 4 reçu',
      );
    }
    return proposals;
  }

  Future<List<dynamic>> _requestJsonList(
    Uri url, {
    required Map<String, String> headers,
  }) async {
    final response = await _client
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('réponse HTTP ${response.statusCode}');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const FormatException('réponse non JSON');
    }
    if (decoded is! List) {
      throw const FormatException('format de réponse inattendu');
    }
    return decoded;
  }

  static String _digits(dynamic value) =>
      value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

  static DateTime? _parseIsoDate(dynamic value) {
    final match =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value?.toString() ?? '');
    if (match == null) return null;
    return _safeDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static DateTime? _parseFloridaDate(dynamic value) {
    final match =
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(value?.toString() ?? '');
    if (match == null) return null;
    return _safeDate(
      int.parse(match.group(3)!),
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  static DateTime? _safeDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static OfficialDrawPeriod? _parseFloridaPeriod(dynamic value) {
    return switch (value?.toString().toUpperCase()) {
      'MIDDAY' => OfficialDrawPeriod.midday,
      'EVENING' => OfficialDrawPeriod.evening,
      _ => null,
    };
  }

  static OfficialLottery? _parseAdditionalLottery(dynamic value) {
    return switch (value?.toString().toLowerCase()) {
      'tx' || 'texas' => OfficialLottery.texas,
      'md' || 'maryland' => OfficialLottery.maryland,
      'ga' || 'georgia' => OfficialLottery.georgia,
      'tn' || 'tennessee' => OfficialLottery.tennessee,
      'pa' || 'pennsylvania' => OfficialLottery.pennsylvania,
      'nj' || 'new_jersey' || 'new-jersey' => OfficialLottery.newJersey,
      _ => null,
    };
  }

  static OfficialDrawPeriod? _parseAdditionalPeriod(dynamic value) {
    return switch (value?.toString().toLowerCase()) {
      'morning' => OfficialDrawPeriod.morning,
      'midday' => OfficialDrawPeriod.midday,
      'day' => OfficialDrawPeriod.day,
      'evening' => OfficialDrawPeriod.evening,
      'night' => OfficialDrawPeriod.night,
      _ => null,
    };
  }

  static bool _supportsPeriod(
    OfficialLottery lottery,
    OfficialDrawPeriod period,
  ) {
    final template = OfficialLotteryProposal(
      lottery: lottery,
      period: period,
      drawDate: DateTime(2000),
      numbers: const [],
      sourceName: '',
      sourceUrl: '',
    );
    return template.availablePeriods.contains(period);
  }

  static String _lotteryLabel(OfficialLottery lottery) {
    return OfficialLotteryProposal(
      lottery: lottery,
      period: OfficialDrawPeriod.midday,
      drawDate: DateTime(2000),
      numbers: const [],
      sourceName: '',
      sourceUrl: '',
    ).lotteryLabel;
  }

  static String? _parseFloridaWinningNumber(
    dynamic value,
    int expectedDigits,
  ) {
    if (value is! List) return null;
    final winningDigits = <int, String>{};
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final type = map['NumberType']?.toString().toLowerCase() ?? '';
      final match = RegExp(r'^wn(\d+)$').firstMatch(type);
      if (match == null) continue; // Fireball and metadata are excluded.
      final position = int.parse(match.group(1)!);
      final digit = _digits(map['NumberPick']);
      if (digit.length == 1) winningDigits[position] = digit;
    }

    if (winningDigits.length != expectedDigits) return null;
    final result = StringBuffer();
    for (var position = 1; position <= expectedDigits; position++) {
      final digit = winningDigits[position];
      if (digit == null) return null;
      result.write(digit);
    }
    return result.toString();
  }

  static String _readableError(Object error) {
    if (error is TimeoutException) return 'délai de connexion dépassé';
    if (error is HttpException || error is FormatException) {
      return error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    }
    return 'source temporairement indisponible';
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class HttpException implements Exception {
  const HttpException(this.message);

  final String message;

  @override
  String toString() => 'HttpException: $message';
}

class _SourceLoad {
  const _SourceLoad({required this.proposals, this.warning});

  final List<OfficialLotteryProposal> proposals;
  final String? warning;
}

class _FloridaGames {
  _FloridaGames({required this.drawDate, required this.period});

  final DateTime drawDate;
  final OfficialDrawPeriod period;
  String? pick2;
  String? pick3;
  String? pick4;

  bool get isComplete => pick2 != null && pick3 != null && pick4 != null;
}
