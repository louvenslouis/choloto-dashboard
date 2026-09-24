import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot.dart';

void main() {
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
