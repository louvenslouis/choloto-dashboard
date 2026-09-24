import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_firestore.dart';

void main() {
  test('publication increments revision and rejects concurrent stale edits',
      () async {
    final db = MemoryFirestore();
    final repository = SupportBotRepository(firestore: db);
    await repository.publish(SupportBotConfig.initial);
    expect(db.rows['support_bot/config']!['revision'], 1);
    await expectLater(
        repository.publish(SupportBotConfig.initial), throwsStateError);
    final latest = SupportBotConfig.fromJson(db.rows['support_bot/config']!);
    await repository.publish(SupportBotConfig(
        enabled: false,
        greeting: latest.greeting,
        nodes: latest.nodes,
        revision: latest.revision));
    expect(db.rows['support_bot/config']!['revision'], 2);
    expect(db.rows['support_bot/config']!['enabled'], false);
  });
}
