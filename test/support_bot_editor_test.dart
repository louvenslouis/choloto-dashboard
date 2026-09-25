import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot_editor.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_firestore.dart';

class Repository extends SupportBotRepository {
  Repository() : super(firestore: MemoryFirestore());
  SupportBotConfig? saved;
  @override
  Future<SupportBotConfig> load() async =>
      const SupportBotConfig(enabled: true, greeting: 'Bienvenue', nodes: [
        SupportBotNode(
            id: 'vip', parent: '', label: 'VIP', answer: 'Réponse VIP')
      ]);
  @override
  Future<void> publish(SupportBotConfig config) async {
    config.validate();
    saved = config;
  }
}

void main() {
  testWidgets('add and edit a branch before atomic publication',
      (tester) async {
    final repository = Repository();
    await tester.pumpWidget(
        MaterialApp(home: SupportBotEditor(repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Ajouter un sous-choix'));
    await tester.tap(find.byTooltip('Ajouter un sous-choix'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'MonCash');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Contacter l’équipe');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.text('MonCash'), findsOneWidget);
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    expect(repository.saved!.children('vip').single.label, 'MonCash');
    expect(find.text('Bot publié'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Modifier').first);
    await tester.tap(find.byTooltip('Modifier').first);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Nouvelle réponse');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    expect(repository.saved!.node('vip')!.answer, 'Nouvelle réponse');
  });
}
