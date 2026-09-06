import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_inbox_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('support inbox list fits a narrow ${brightness.name} viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SupportConversation? opened;
      final conversation = SupportConversation('member', {
        'user_uid': 'member',
        'user_display_name': 'Marie Exemple',
        'user_email': 'marie@example.test',
        'last_message': 'Je souhaite payer mon abonnement avec MonCash.',
        'last_sender_role': 'user',
        'updated_at': DateTime(2026, 9, 6, 10, 30),
      });
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SupportConversationList(
              conversations: [conversation],
              onOpen: (value) => opened = value,
            ),
          ),
        ),
      ));

      expect(find.text('Marie Exemple'), findsOneWidget);
      expect(find.text('À répondre'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester
          .tap(find.byKey(const ValueKey('support-conversation-member')));
      expect(opened, same(conversation));
    });
  }

  testWidgets('support inbox has an explicit empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SupportConversationList(
          conversations: const [],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('Aucune conversation pour le moment.'), findsOneWidget);
  });
}
