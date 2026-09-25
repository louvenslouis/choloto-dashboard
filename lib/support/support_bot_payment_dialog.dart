import 'dart:math';
import 'package:flutter/material.dart';
import 'support_bot.dart';

class SupportBotPaymentDialog extends StatefulWidget {
  const SupportBotPaymentDialog({super.key, this.payment});
  final SupportBotPayment? payment;
  @override
  State<SupportBotPaymentDialog> createState() =>
      _SupportBotPaymentDialogState();
}

class _SupportBotPaymentDialogState extends State<SupportBotPaymentDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.payment?.name);
  late final _currency =
      TextEditingController(text: widget.payment?.currency ?? 'HTG');
  late final _account = TextEditingController(text: widget.payment?.account);
  late final _recipient =
      TextEditingController(text: widget.payment?.recipient);
  late bool _enabled = widget.payment?.enabled ?? false;
  @override
  void dispose() {
    for (final c in [_name, _currency, _account, _recipient]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final method = SupportBotPayment(
        id: widget.payment?.id ??
            List.generate(
                16,
                (_) => Random.secure()
                    .nextInt(256)
                    .toRadixString(16)
                    .padLeft(2, '0')).join(),
        name: _name.text.trim(),
        amountMinor: widget.payment?.amountMinor ?? 0,
        currency: _currency.text.trim().toUpperCase(),
        months: widget.payment?.months ?? 1,
        account: _account.text.trim(),
        recipient: _recipient.text.trim(),
        enabled: _enabled);
    Navigator.pop(context, method);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.payment == null
            ? 'Ajouter un moyen de paiement'
            : 'Modifier le moyen de paiement'),
        content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          key: const ValueKey('payment-name'),
                          controller: _name,
                          maxLength: 60,
                          decoration: const InputDecoration(
                              labelText: 'Moyen de paiement'),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Champ requis' : null),
                      TextFormField(
                          key: const ValueKey('payment-currency'),
                          controller: _currency,
                          maxLength: 3,
                          textCapitalization: TextCapitalization.characters,
                          decoration:
                              const InputDecoration(labelText: 'Devise'),
                          validator: (v) => RegExp(r'^[A-Z]{3}$')
                                  .hasMatch(v!.trim().toUpperCase())
                              ? null
                              : 'Code à 3 lettres : HTG, USD…'),
                      TextFormField(
                          key: const ValueKey('payment-account'),
                          controller: _account,
                          maxLength: 180,
                          decoration: const InputDecoration(
                              labelText: 'Numéro / compte / e-mail'),
                          validator: (v) => _enabled && v!.trim().isEmpty
                              ? 'Champ requis'
                              : null),
                      TextFormField(
                          key: const ValueKey('payment-recipient'),
                          controller: _recipient,
                          maxLength: 120,
                          decoration:
                              const InputDecoration(labelText: 'Bénéficiaire'),
                          validator: (v) => _enabled && v!.trim().isEmpty
                              ? 'Champ requis'
                              : null),
                      SwitchListTile(
                          key: const ValueKey('payment-enabled'),
                          title: const Text('Actif'),
                          value: _enabled,
                          onChanged: (value) =>
                              setState(() => _enabled = value)),
                    ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(onPressed: _save, child: const Text('Enregistrer'))
        ],
      );
}
