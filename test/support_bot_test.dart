import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot.dart';

void main() {
  test('payment amounts are exact and incomplete active profiles are rejected',
      () {
    expect(SupportBotPayment.parseAmount('2500,50'), 250050);
    expect(SupportBotPayment.parseAmount('60'), 6000);
    expect(SupportBotPayment.parseAmount('-1'), isNull);
    expect(SupportBotPayment.parseAmount('1.234'), isNull);
    expect(
        () => const SupportBotPayment(
                id: 'moncash', name: 'MonCash', currency: 'HTG', enabled: true)
            .validate(),
        throwsFormatException);
    expect(
        () => const SupportBotPlan(
                id: 'monthly',
                name: 'Mensuel',
                amountHtgMinor: 250000,
                months: 1)
            .validate(),
        throwsFormatException);
  });
  test('shared plans update legacy prices without exposing payment details',
      () {
    final config = SupportBotConfig(
      enabled: true,
      greeting: 'Hello',
      nodes: const [
        SupportBotNode(id: 'a', parent: '', label: 'A', answer: 'B')
      ],
      plans: const [
        SupportBotPlan(
            id: 'monthly',
            name: 'Mensuel',
            amountHtgMinor: 250000,
            amountUsdMinor: 6000,
            months: 1),
        SupportBotPlan(
            id: 'quarterly',
            name: 'Trimestriel',
            amountHtgMinor: 700000,
            amountUsdMinor: 17000,
            months: 3),
      ],
      paymentMethods: const [
        SupportBotPayment(
            id: 'moncash',
            name: 'MonCash',
            currency: 'HTG',
            account: '111',
            recipient: 'A',
            enabled: true),
        SupportBotPayment(
            id: 'natcash',
            name: 'NatCash',
            currency: 'USD',
            account: '222',
            recipient: 'B',
            enabled: true),
      ],
    ).synchronizedForPublication();
    config.validate();
    expect(config.paymentMethods.map((p) => p.amountMinor), [250000, 6000]);
    expect(config.availablePlans.length, 2);
    expect(SupportBotConfig.fromJson(config.toJson()).plans.length, 2);
  });
  test('legacy prices become shared plans and conflicting defaults are blocked',
      () {
    final legacy = SupportBotConfig(
      enabled: true,
      greeting: 'Hello',
      nodes: const [
        SupportBotNode(id: 'a', parent: '', label: 'A', answer: 'B')
      ],
      paymentMethods: const [
        SupportBotPayment(
            id: 'moncash',
            name: 'MonCash',
            currency: 'HTG',
            amountMinor: 250000,
            account: '111',
            recipient: 'A',
            enabled: true),
        SupportBotPayment(
            id: 'natcash',
            name: 'NatCash',
            currency: 'HTG',
            amountMinor: 250000,
            account: '222',
            recipient: 'B',
            enabled: true),
      ],
    );
    expect(legacy.availablePlans.length, 1);
    expect(legacy.availablePlans.single.amountHtgMinor, 250000);
    expect(legacy.availablePlans.single.amountUsdMinor, 0);
    final conflicting = SupportBotConfig(
      enabled: legacy.enabled,
      greeting: legacy.greeting,
      nodes: legacy.nodes,
      paymentMethods: legacy.paymentMethods,
      plans: const [
        SupportBotPlan(
            id: 'a',
            name: 'A',
            amountHtgMinor: 250000,
            amountUsdMinor: 6000,
            months: 1),
        SupportBotPlan(
            id: 'b',
            name: 'B',
            amountHtgMinor: 300000,
            amountUsdMinor: 6000,
            months: 1),
      ],
    );
    expect(conflicting.synchronizedForPublication, throwsFormatException);
  });
  test('legacy trees load without payment configuration', () {
    final legacy = {
      'enabled': true,
      'greeting': 'Hello',
      'revision': 1,
      'nodes': [
        {'id': 'a', 'parent': '', 'label': 'A', 'answer': 'B'}
      ]
    };
    final config = SupportBotConfig.fromJson(legacy);
    expect(config.paymentMethods, isEmpty);
    expect(config.nodes.single.paymentMethodId, isEmpty);
  });
  test('payment references survive storage and dangling links are rejected',
      () {
    final config = SupportBotConfig.fromJson(SupportBotConfig.initial.toJson());
    expect(config.node('renew_mon')!.paymentMethodId, 'moncash');
    expect(config.payment('moncash')!.enabled, false);
    expect(
        () => SupportBotConfig(
                enabled: true, greeting: 'Hello', nodes: config.nodes)
            .validate(),
        throwsFormatException);
  });

  test('initial tree is valid and survives storage roundtrip', () {
    SupportBotConfig.initial.validate();
    final config = SupportBotConfig.fromJson(SupportBotConfig.initial.toJson());
    expect(config.children('').length, 5);
    expect(config.node('paid')!.requiresAuth, isTrue);
    expect(config.node('paid')!.requestImage, isTrue);
    expect(config.node('renew')!.requiresAuth, isTrue);
    expect(config.children('renew').map((n) => n.label),
        ['MonCash', 'NatCash', 'Zelle']);
  });
  test('rejects orphan, duplicate and cyclic branches', () {
    for (final nodes in [
      [
        const SupportBotNode(
            id: 'a', parent: 'missing', label: 'A', answer: 'B')
      ],
      [const SupportBotNode(id: 'a', parent: 'a', label: 'A', answer: 'B')],
      [
        const SupportBotNode(id: 'a', parent: '', label: 'A', answer: 'B'),
        const SupportBotNode(id: 'a', parent: '', label: 'A', answer: 'B')
      ],
    ]) {
      expect(
          () => SupportBotConfig(enabled: true, greeting: 'Hello', nodes: nodes)
              .validate(),
          throwsFormatException);
    }
  });
  test('rejects empty response and excessive depth', () {
    expect(
        () => SupportBotConfig(enabled: true, greeting: 'Hello', nodes: [
              const SupportBotNode(id: 'a', parent: '', label: 'A', answer: '')
            ]).validate(),
        throwsFormatException);
    expect(
        () => SupportBotConfig(
            enabled: true,
            greeting: 'Hello',
            nodes: List.generate(
                7,
                (i) => SupportBotNode(
                    id: 'n$i',
                    parent: i == 0 ? '' : 'n${i - 1}',
                    label: 'A',
                    answer: 'B'))).validate(),
        throwsFormatException);
  });
}
