import 'package:c_h_o_l_o_t_o_dashboard/support/support_bot_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support_bot_editor_test.dart' show Repository;

void main() {
  testWidgets('add payment details, link a branch and publish together',
      (tester) async {
    final repo = Repository();
    await tester
        .pumpWidget(MaterialApp(home: SupportBotEditor(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un plan'));
    await tester.pumpAndSettle();
    for (final entry in {
      'plan-name': 'Mensuel',
      'plan-amount-htg': '2500,50',
      'plan-amount-usd': '60',
      'plan-months': '1',
    }.entries) {
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informations de paiement'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ajouter un moyen de paiement'));
    await tester.tap(find.text('Ajouter un moyen de paiement'));
    await tester.pumpAndSettle();
    for (final entry in {
      'payment-name': 'MonCash',
      'payment-currency': 'HTG',
      'payment-account': 'test-account',
      'payment-recipient': 'Test beneficiary'
    }.entries) {
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('payment-enabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-enabled')));
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(repo.saved, isNull);
    await tester.ensureVisible(find.byTooltip('Modifier'));
    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MonCash').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    final saved = repo.saved!;
    final payment = saved.paymentMethods.single;
    expect(payment.amountMinor, 250050);
    expect(payment.account, 'test-account');
    expect(payment.enabled, true);
    expect(saved.plans.single.amountHtgMinor, 250050);
    expect(saved.plans.single.amountUsdMinor, 6000);
    expect(saved.node('vip')!.paymentMethodId, payment.id);
    expect(saved.node('vip')!.requiresAuth, true);
    await tester.ensureVisible(find.byTooltip('Modifier le plan Mensuel'));
    await tester.tap(find.byTooltip('Modifier le plan Mensuel'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('plan-amount-htg')), '3000');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    expect(repo.saved!.paymentMethods.single.amountMinor, 300000);
    expect(repo.saved!.plans.single.amountHtgMinor, 300000);
    expect(repo.saved!.node('vip')!.paymentMethodId, payment.id);
  });
}
