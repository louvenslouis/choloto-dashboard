import 'package:c_h_o_l_o_t_o_dashboard/tirages/automatic_lottery_publication_controller.dart';
import 'package:c_h_o_l_o_t_o_dashboard/tirages/official_lottery_results_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'keeps checking on the global timer after the preference is restored',
      (tester) async {
    var fetchCount = 0;
    String? preferenceKey;
    final controller = AutomaticLotteryPublicationController(
      automaticRefreshInterval: const Duration(minutes: 10),
      readPreference: (key) async {
        preferenceKey = key;
        return true;
      },
      fetchLatest: () async {
        fetchCount++;
        return const OfficialLotteryFetchResult(
          proposals: [],
          warnings: [],
        );
      },
      findPublishedProposalIds: (_) async => <String>{},
    );
    addTearDown(controller.dispose);

    await controller.setAuthenticatedUser('admin-123');

    expect(preferenceKey, 'tirages_automatic_publication_admin-123');
    expect(controller.automaticPublicationEnabled, isTrue);
    expect(fetchCount, 1);

    await tester.pump(const Duration(minutes: 10));
    await tester.pump();

    expect(fetchCount, 2);
    await controller.setAuthenticatedUser(null);
  });

  testWidgets('stops the global timer when the administrator signs out',
      (tester) async {
    var fetchCount = 0;
    final writes = <(String, bool)>[];
    final controller = AutomaticLotteryPublicationController(
      automaticRefreshInterval: const Duration(minutes: 10),
      readPreference: (_) async => false,
      writePreference: (key, enabled) async {
        writes.add((key, enabled));
        return true;
      },
      fetchLatest: () async {
        fetchCount++;
        return const OfficialLotteryFetchResult(
          proposals: [],
          warnings: [],
        );
      },
      findPublishedProposalIds: (_) async => <String>{},
    );
    addTearDown(controller.dispose);

    await controller.setAuthenticatedUser('admin-456');
    expect(fetchCount, 0);

    await controller.setAutomaticPublicationEnabled(true);
    expect(
      writes,
      [('tirages_automatic_publication_admin-456', true)],
    );
    expect(fetchCount, 1);

    await controller.setAuthenticatedUser(null);
    await tester.pump(const Duration(minutes: 20));
    await tester.pump();

    expect(controller.automaticPublicationEnabled, isFalse);
    expect(fetchCount, 1);
  });

  testWidgets('publishes a new valid official result without a page mounted',
      (tester) async {
    final proposal = OfficialLotteryProposal(
      lottery: OfficialLottery.newYork,
      period: OfficialDrawPeriod.midday,
      drawDate: DateTime(2026, 9, 5),
      numbers: const ['123', '45', '67'],
      sourceName: 'Test source',
      sourceUrl: 'https://example.com',
    );
    final writtenIds = <String>[];
    String? writerUserId;
    final controller = AutomaticLotteryPublicationController(
      readPreference: (_) async => true,
      fetchLatest: () async => OfficialLotteryFetchResult(
        proposals: [proposal],
        warnings: const [],
      ),
      findPublishedProposalIds: (_) async => <String>{},
      writeProposal: (
        proposal,
        userId, {
        required checkExistingHistory,
      }) async {
        writtenIds.add(proposal.documentId);
        writerUserId = userId;
        expect(checkExistingHistory, isFalse);
        return OfficialPublicationOutcome.published;
      },
    );
    addTearDown(controller.dispose);

    await controller.setAuthenticatedUser('background-admin');

    expect(writtenIds, [proposal.documentId]);
    expect(writerUserId, 'background-admin');
    expect(controller.publishedOfficialIds, contains(proposal.documentId));
    await controller.setAuthenticatedUser(null);
  });
}
