import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'official_lottery_results_service.dart';

enum OfficialPublicationOutcome { published, alreadyPublished, failed }

typedef OfficialResultsFetcher = Future<OfficialLotteryFetchResult> Function();
typedef PublishedProposalIdsFinder = Future<Set<String>> Function(
  List<OfficialLotteryProposal> proposals,
);
typedef OfficialProposalWriter = Future<OfficialPublicationOutcome> Function(
  OfficialLotteryProposal proposal,
  String userId, {
  required bool checkExistingHistory,
});
typedef AutomaticPreferenceReader = Future<bool> Function(String key);
typedef AutomaticPreferenceWriter = Future<bool> Function(
  String key,
  bool enabled,
);

/// Owns automatic lottery checks for the lifetime of the dashboard rather than
/// for the lifetime of the Tirages page.
class AutomaticLotteryPublicationController extends ChangeNotifier
    with WidgetsBindingObserver {
  AutomaticLotteryPublicationController({
    OfficialLotteryResultsService? officialService,
    OfficialResultsFetcher? fetchLatest,
    PublishedProposalIdsFinder? findPublishedProposalIds,
    OfficialProposalWriter? writeProposal,
    AutomaticPreferenceReader? readPreference,
    AutomaticPreferenceWriter? writePreference,
    this.automaticRefreshInterval = const Duration(minutes: 10),
  })  : _officialService = officialService ??
            (fetchLatest == null ? OfficialLotteryResultsService() : null),
        _ownsOfficialService = officialService == null && fetchLatest == null,
        _fetchLatestOverride = fetchLatest,
        _findPublishedProposalIdsOverride = findPublishedProposalIds,
        _writeProposalOverride = writeProposal,
        _readPreference = readPreference ?? _readSavedPreference,
        _writePreference = writePreference ?? _writeSavedPreference {
    WidgetsBinding.instance.addObserver(this);
  }

  final OfficialLotteryResultsService? _officialService;
  final bool _ownsOfficialService;
  final OfficialResultsFetcher? _fetchLatestOverride;
  final PublishedProposalIdsFinder? _findPublishedProposalIdsOverride;
  final OfficialProposalWriter? _writeProposalOverride;
  final AutomaticPreferenceReader _readPreference;
  final AutomaticPreferenceWriter _writePreference;
  final Duration automaticRefreshInterval;

  Timer? _automaticRefreshTimer;
  Future<void>? _preferenceLoad;
  String _userId = '';
  int _userGeneration = 0;
  bool _disposed = false;
  int? _refreshGeneration;
  bool _loadingOfficialResults = false;
  bool _loadingAutomaticPreference = false;
  bool _savingAutomaticPreference = false;
  bool _automaticPublicationEnabled = false;
  bool _automaticPublicationRunning = false;
  DateTime? _lastOfficialCheck;
  List<OfficialLotteryProposal> _officialProposals = const [];
  List<String> _officialWarnings = const [];
  Set<String> _publishedOfficialIds = const {};
  Set<String> _publishingOfficialIds = const {};

  bool get loadingOfficialResults => _loadingOfficialResults;
  bool get loadingAutomaticPreference => _loadingAutomaticPreference;
  bool get savingAutomaticPreference => _savingAutomaticPreference;
  bool get automaticPublicationEnabled => _automaticPublicationEnabled;
  bool get automaticPublicationRunning => _automaticPublicationRunning;
  DateTime? get lastOfficialCheck => _lastOfficialCheck;
  List<OfficialLotteryProposal> get officialProposals => _officialProposals;
  List<String> get officialWarnings => _officialWarnings;
  Set<String> get publishedOfficialIds => _publishedOfficialIds;
  Set<String> get publishingOfficialIds => _publishingOfficialIds;

  String get _automaticPublicationPreferenceKey =>
      'tirages_automatic_publication_$_userId';

  Future<void> setAuthenticatedUser(String? userId) {
    final normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId == _userId) {
      return _preferenceLoad ?? Future<void>.value();
    }

    _userGeneration++;
    final generation = _userGeneration;
    _automaticRefreshTimer?.cancel();
    _automaticRefreshTimer = null;
    _userId = normalizedUserId;
    _automaticPublicationEnabled = false;
    _automaticPublicationRunning = false;
    _loadingAutomaticPreference = normalizedUserId.isNotEmpty;
    _savingAutomaticPreference = false;
    _resetOfficialResults();
    _notify();

    if (normalizedUserId.isEmpty) {
      _preferenceLoad = null;
      return Future<void>.value();
    }

    final load = _loadAutomaticPublicationPreference(generation);
    _preferenceLoad = load;
    return load.whenComplete(() {
      if (generation == _userGeneration) _preferenceLoad = null;
    });
  }

  Future<void> _loadAutomaticPublicationPreference(int generation) async {
    var enabled = false;
    try {
      enabled = await _readPreference(_automaticPublicationPreferenceKey);
    } catch (_) {
      enabled = false;
    }
    if (_disposed || generation != _userGeneration) return;
    _automaticPublicationEnabled = enabled;
    _loadingAutomaticPreference = false;
    _syncAutomaticRefreshTimer();
    _notify();

    if (enabled && generation == _userGeneration) {
      await refreshOfficialResults();
    }
  }

  Future<void> setAutomaticPublicationEnabled(bool enabled) async {
    if (_userId.isEmpty ||
        _savingAutomaticPreference ||
        _automaticPublicationRunning) {
      return;
    }

    final previousValue = _automaticPublicationEnabled;
    final generation = _userGeneration;
    _savingAutomaticPreference = true;
    _automaticPublicationEnabled = enabled;
    _notify();

    try {
      final saved = await _writePreference(
        _automaticPublicationPreferenceKey,
        enabled,
      );
      if (!saved) throw StateError('Preference not saved');
      if (_disposed || generation != _userGeneration) return;
      _syncAutomaticRefreshTimer();
    } catch (_) {
      if (!_disposed && generation == _userGeneration) {
        _automaticPublicationEnabled = previousValue;
        _syncAutomaticRefreshTimer();
      }
      rethrow;
    } finally {
      if (!_disposed && generation == _userGeneration) {
        _savingAutomaticPreference = false;
        _notify();
      }
    }

    if (enabled && generation == _userGeneration) {
      await refreshOfficialResults();
    }
  }

  void _syncAutomaticRefreshTimer() {
    _automaticRefreshTimer?.cancel();
    _automaticRefreshTimer = null;
    if (_disposed || !_automaticPublicationEnabled || _userId.isEmpty) return;

    _automaticRefreshTimer = Timer.periodic(
      automaticRefreshInterval,
      (_) => unawaited(refreshOfficialResults()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _automaticPublicationEnabled &&
        _userId.isNotEmpty) {
      unawaited(refreshOfficialResults());
    }
  }

  Future<void> refreshOfficialResults() async {
    if (_disposed || _userId.isEmpty || _refreshGeneration == _userGeneration) {
      return;
    }

    final generation = _userGeneration;
    _refreshGeneration = generation;
    _loadingOfficialResults = true;
    _notify();
    try {
      logFirebaseEvent('TIRAGES_FETCH_OFFICIAL_RESULTS');
    } catch (_) {
      // Analytics must never prevent a scheduled publication check.
    }

    try {
      final result = await (_fetchLatestOverride?.call() ??
          _officialService!.fetchLatest());
      if (_disposed || generation != _userGeneration) return;

      final warnings = [...result.warnings];
      Set<String> publishedIds;
      var historyVerified = true;
      try {
        publishedIds =
            await (_findPublishedProposalIdsOverride?.call(result.proposals) ??
                _findPublishedProposalIds(result.proposals));
      } catch (_) {
        historyVerified = false;
        publishedIds = <String>{};
        warnings.add(
          'Les résultats ont été reçus, mais la vérification de l’historique '
          'Firebase a échoué.',
        );
        if (_automaticPublicationEnabled) {
          warnings.add(
            'Publication automatique suspendue pour éviter un doublon.',
          );
        }
      }
      if (_disposed || generation != _userGeneration) return;

      _officialProposals = result.proposals;
      _officialWarnings = List.unmodifiable(warnings);
      _publishedOfficialIds = publishedIds;
      _lastOfficialCheck = DateTime.now();
      _loadingOfficialResults = false;
      _notify();

      if (_automaticPublicationEnabled && historyVerified) {
        await _publishOfficialProposalsAutomatically(
          result.proposals,
          publishedIds,
          generation,
        );
      }
    } catch (_) {
      if (_disposed || generation != _userGeneration) return;
      _officialWarnings = const [
        'Les sources officielles sont temporairement indisponibles.',
      ];
      _lastOfficialCheck = DateTime.now();
      _loadingOfficialResults = false;
      _notify();
    } finally {
      if (_refreshGeneration == generation) _refreshGeneration = null;
    }
  }

  Future<Set<String>> _findPublishedProposalIds(
    List<OfficialLotteryProposal> proposals,
  ) async {
    if (proposals.isEmpty) return <String>{};

    final oldestDraw = proposals
        .map((proposal) => proposal.drawDateTime)
        .reduce((first, second) => first.isBefore(second) ? first : second);
    final documentSnapshots = await Future.wait(
      proposals.map(
        (proposal) => ResultatsRecord.collection.doc(proposal.documentId).get(),
      ),
    );
    final recentHistory = await queryResultatsRecordOnce(
      queryBuilder: (query) => query.where(
        'date',
        isGreaterThanOrEqualTo: oldestDraw.subtract(const Duration(hours: 18)),
      ),
    );

    final published = <String>{};
    for (var index = 0; index < proposals.length; index++) {
      final proposal = proposals[index];
      if (documentSnapshots[index].exists ||
          recentHistory.any((record) => _matchesProposal(record, proposal))) {
        published.add(proposal.documentId);
      }
    }
    return published;
  }

  bool _matchesProposal(
    ResultatsRecord record,
    OfficialLotteryProposal proposal,
  ) {
    if (record.tirage != proposal.lotteryCode ||
        record.periode != proposal.periodLabel ||
        !listEquals(record.numeros, proposal.numbers)) {
      return false;
    }
    final recordedAt = record.date;
    if (recordedAt == null) return false;
    final difference = recordedAt.difference(proposal.drawDateTime).abs();
    return difference <= const Duration(hours: 18) ||
        (recordedAt.year == proposal.drawDate.year &&
            recordedAt.month == proposal.drawDate.month &&
            recordedAt.day == proposal.drawDate.day);
  }

  Future<void> _publishOfficialProposalsAutomatically(
    List<OfficialLotteryProposal> proposals,
    Set<String> publishedIds,
    int generation,
  ) async {
    if (_automaticPublicationRunning || _userId.isEmpty) return;

    final candidates = proposals
        .where((proposal) => !publishedIds.contains(proposal.documentId))
        .where((proposal) => proposal.validateNumbers(proposal.numbers) == null)
        .toList();
    if (candidates.isEmpty) return;

    _automaticPublicationRunning = true;
    _notify();
    var failureCount = 0;
    try {
      for (final proposal in candidates) {
        if (_disposed ||
            generation != _userGeneration ||
            !_automaticPublicationEnabled) {
          break;
        }
        final outcome = await storeOfficialProposal(
          proposal,
          checkExistingHistory: false,
        );
        if (outcome == OfficialPublicationOutcome.failed) failureCount++;
      }
    } finally {
      if (!_disposed && generation == _userGeneration) {
        _automaticPublicationRunning = false;
        if (failureCount > 0) {
          _officialWarnings = List.unmodifiable([
            ..._officialWarnings,
            '$failureCount publication${failureCount > 1 ? 's' : ''} '
                'automatique${failureCount > 1 ? 's' : ''} a échoué.',
          ]);
        }
        _notify();
      }
    }
  }

  Future<OfficialPublicationOutcome> storeOfficialProposal(
    OfficialLotteryProposal proposal, {
    required bool checkExistingHistory,
  }) async {
    if (_disposed || _userId.isEmpty) {
      return OfficialPublicationOutcome.failed;
    }

    final generation = _userGeneration;
    final userId = _userId;
    final id = proposal.documentId;
    _publishingOfficialIds = {..._publishingOfficialIds, id};
    _notify();

    try {
      final outcome = await (_writeProposalOverride?.call(
            proposal,
            userId,
            checkExistingHistory: checkExistingHistory,
          ) ??
          _writeOfficialProposal(
            proposal,
            userId,
            checkExistingHistory: checkExistingHistory,
          ));
      if (!_disposed && generation == _userGeneration) {
        if (outcome != OfficialPublicationOutcome.failed) {
          _publishedOfficialIds = {..._publishedOfficialIds, id};
        }
      }
      return outcome;
    } finally {
      if (!_disposed && generation == _userGeneration) {
        _publishingOfficialIds = {..._publishingOfficialIds}..remove(id);
        _notify();
      }
    }
  }

  Future<OfficialPublicationOutcome> _writeOfficialProposal(
    OfficialLotteryProposal proposal,
    String userId, {
    required bool checkExistingHistory,
  }) async {
    try {
      if (checkExistingHistory) {
        final existingHistory = await queryResultatsRecordOnce(
          queryBuilder: (query) => query.where(
            'date',
            isGreaterThanOrEqualTo:
                proposal.drawDateTime.subtract(const Duration(hours: 18)),
          ),
        );
        if (existingHistory
            .any((record) => _matchesProposal(record, proposal))) {
          return OfficialPublicationOutcome.alreadyPublished;
        }
      }

      final reference = ResultatsRecord.collection.doc(proposal.documentId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        if (existing.exists) throw const _AlreadyPublishedException();
        transaction.set(reference, {
          ...createResultatsRecordData(
            date: proposal.drawDateTime,
            periode: proposal.periodLabel,
            tirage: proposal.lotteryCode,
            createdBy: userId,
          ),
          ...mapToFirestore({'numeros': proposal.numbers}),
        });
      });
      return OfficialPublicationOutcome.published;
    } on _AlreadyPublishedException {
      return OfficialPublicationOutcome.alreadyPublished;
    } catch (_) {
      return OfficialPublicationOutcome.failed;
    }
  }

  void _resetOfficialResults() {
    _refreshGeneration = null;
    _loadingOfficialResults = false;
    _lastOfficialCheck = null;
    _officialProposals = const [];
    _officialWarnings = const [];
    _publishedOfficialIds = const {};
    _publishingOfficialIds = const {};
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _automaticRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsOfficialService) _officialService?.dispose();
    super.dispose();
  }

  static Future<bool> _readSavedPreference(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(key) ?? false;
  }

  static Future<bool> _writeSavedPreference(String key, bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setBool(key, enabled);
  }
}

class _AlreadyPublishedException implements Exception {
  const _AlreadyPublishedException();
}
