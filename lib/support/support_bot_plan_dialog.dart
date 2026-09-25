import 'dart:math';
import 'package:flutter/material.dart';
import 'support_bot.dart';

class SupportBotPlanDialog extends StatefulWidget {
  const SupportBotPlanDialog({super.key, this.plan});
  final SupportBotPlan? plan;

  @override
  State<SupportBotPlanDialog> createState() => _SupportBotPlanDialogState();
}

class _SupportBotPlanDialogState extends State<SupportBotPlanDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name);
  late final _amountHtg = TextEditingController(
      text: widget.plan == null || widget.plan!.amountHtgMinor == 0
          ? ''
          : (widget.plan!.amountHtgMinor / 100).toStringAsFixed(2));
  late final _amountUsd = TextEditingController(
      text: widget.plan == null || widget.plan!.amountUsdMinor == 0
          ? ''
          : (widget.plan!.amountUsdMinor / 100).toStringAsFixed(2));
  late final _months =
      TextEditingController(text: '${widget.plan?.months ?? 1}');
  late bool _enabled = widget.plan?.enabled ?? true;

  @override
  void dispose() {
    for (final controller in [_name, _amountHtg, _amountUsd, _months]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
        context,
        SupportBotPlan(
          id: widget.plan?.id ??
              List.generate(
                  16,
                  (_) => Random.secure()
                      .nextInt(256)
                      .toRadixString(16)
                      .padLeft(2, '0')).join(),
          name: _name.text.trim(),
          amountHtgMinor: SupportBotPayment.parseAmount(_amountHtg.text) ?? 0,
          amountUsdMinor: SupportBotPayment.parseAmount(_amountUsd.text) ?? 0,
          months: int.parse(_months.text.trim()),
          enabled: _enabled,
        ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.plan == null ? 'Ajouter un plan' : 'Modifier le plan'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  key: const ValueKey('plan-name'),
                  controller: _name,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
                TextFormField(
                  key: const ValueKey('plan-amount-htg'),
                  controller: _amountHtg,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Prix HTG'),
                  validator: (value) {
                    final amount = SupportBotPayment.parseAmount(value ?? '');
                    return (amount == null &&
                                (_enabled ||
                                    (value?.trim().isNotEmpty ?? false))) ||
                            (amount != null &&
                                (amount == 0 || amount > 100000000))
                        ? 'Prix invalide (2 décimales maximum)'
                        : null;
                  },
                ),
                TextFormField(
                  key: const ValueKey('plan-amount-usd'),
                  controller: _amountUsd,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Prix USD'),
                  validator: (value) {
                    final amount = SupportBotPayment.parseAmount(value ?? '');
                    return (amount == null &&
                                (_enabled ||
                                    (value?.trim().isNotEmpty ?? false))) ||
                            (amount != null &&
                                (amount == 0 || amount > 100000000))
                        ? 'Prix invalide (2 décimales maximum)'
                        : null;
                  },
                ),
                TextFormField(
                  key: const ValueKey('plan-months'),
                  controller: _months,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Durée (mois)'),
                  validator: (value) {
                    final months = int.tryParse((value ?? '').trim());
                    return months == null || months < 1 || months > 36
                        ? 'Entre 1 et 36 mois'
                        : null;
                  },
                ),
                SwitchListTile(
                  key: const ValueKey('plan-enabled'),
                  title: const Text('Actif'),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
        ],
      );
}
