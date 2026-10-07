import 'package:flutter/material.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/support/support_bot.dart';
import '/support/support_bot_repository.dart';
import '/support/support_bot_payment_dialog.dart';
import '/support/support_bot_plan_dialog.dart';

class PaymentSettingsWidget extends StatefulWidget {
  const PaymentSettingsWidget({super.key, this.repository});
  static const routeName = 'paymentSettings';
  static const routePath = '/settings/payments';
  final SupportBotRepository? repository;

  @override
  State<PaymentSettingsWidget> createState() => _PaymentSettingsWidgetState();
}

class _PaymentSettingsWidgetState extends State<PaymentSettingsWidget> {
  late final _repository = widget.repository ?? SupportBotRepository();
  SupportBotConfig? _config;
  List<SupportBotPlan> _plans = [];
  List<SupportBotPayment> _payments = [];
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  FlutterFlowTheme get _theme => FlutterFlowTheme.of(context);
  Color get _text => _theme.primaryText;
  Color get _muted => _theme.secondaryText;
  Widget _badge(IconData icon) => AdminIconTile(icon: icon, size: 40);
  Widget _panel({required Widget child, EdgeInsetsGeometry? padding}) =>
      AdminSurface(padding: padding ?? const EdgeInsets.all(20), child: child);
  Future<T?> _showEditorDialog<T>(WidgetBuilder builder) =>
      showDialog<T>(context: context, builder: builder);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _repository.load();
      if (!mounted) return;
      setState(() {
        _config = config;
        _plans = List.of(config.availablePlans);
        _payments = List.of(config.paymentMethods);
        _dirty = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les paramètres.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final original = _config;
    if (original == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final config = SupportBotConfig(
        enabled: original.enabled,
        greeting: original.greeting,
        nodes: original.nodes,
        revision: original.revision,
        plans: _plans,
        paymentMethods: _payments,
      ).synchronizedForPublication();
      await _repository.publish(config);
      if (!mounted) return;
      setState(() {
        _config = SupportBotConfig(
          enabled: config.enabled,
          greeting: config.greeting,
          nodes: config.nodes,
          revision: config.revision + 1,
          plans: config.plans,
          paymentMethods: config.paymentMethods,
        );
        _payments = List.of(config.paymentMethods);
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres enregistrés')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : error is StateError
                ? error.message.toString()
                : 'Enregistrement impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter sans enregistrer ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Rester')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitter')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _editPayment([SupportBotPayment? payment]) async {
    final result = await _showEditorDialog<SupportBotPayment>(
        (_) => SupportBotPaymentDialog(payment: payment));
    if (result == null || !mounted) return;
    setState(() {
      if (payment == null) {
        _payments.add(result);
      } else {
        _payments[_payments.indexOf(payment)] = result;
      }
      _dirty = true;
    });
  }

  Future<void> _editPlan([SupportBotPlan? plan]) async {
    final result = await _showEditorDialog<SupportBotPlan>(
        (_) => SupportBotPlanDialog(plan: plan));
    if (result == null || !mounted) return;
    setState(() {
      if (plan == null) {
        _plans.add(result);
      } else {
        _plans[_plans.indexOf(plan)] = result;
      }
      _dirty = true;
    });
  }

  Widget _plansSection() => _panel(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: const ValueKey('bot-plans-section'),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: _badge(Icons.workspace_premium_outlined),
          title: Text('Plans',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ..._plans.map((p) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(Icons.circle,
                      size: 10, color: p.enabled ? _theme.success : _muted),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p.enabled
                      ? '${(p.amountHtgMinor / 100).toStringAsFixed(2)} HTG · ${(p.amountUsdMinor / 100).toStringAsFixed(2)} USD · ${p.months} mois'
                      : 'Inactif'),
                  trailing: IconButton(
                      tooltip: 'Modifier le plan ${p.name}',
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      onPressed: () => _editPlan(p)),
                  onTap: () => _editPlan(p),
                )),
            TextButton.icon(
                onPressed: _plans.length >= 30 ? null : () => _editPlan(),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Ajouter un plan')),
          ],
        ),
      );

  Widget _paymentSection() => _panel(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: const ValueKey('bot-payment-section'),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: _badge(Icons.account_balance_wallet_outlined),
          title: Text('Informations de paiement',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ..._payments.map((p) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(Icons.circle,
                      size: 10, color: p.enabled ? _theme.success : _muted),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p.enabled ? p.currency : 'Inactif'),
                  trailing: IconButton(
                      tooltip: 'Modifier ${p.name}',
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      onPressed: () => _editPayment(p)),
                  onTap: () => _editPayment(p),
                )),
            TextButton.icon(
                onPressed: _payments.length >= 20 ? null : () => _editPayment(),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Ajouter un moyen de paiement')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_saving) _confirmExit();
        },
        child: Scaffold(
          backgroundColor: _theme.primaryBackground,
          appBar: AppBar(
            title: const Text('Plans et paiements'),
            backgroundColor: _theme.secondaryBackground,
            foregroundColor: _theme.primaryText,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          bottomNavigationBar: AdminActionBar(
            child: Align(
              heightFactor: 1,
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _loading || _saving || !_dirty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
              ),
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : AbsorbPointer(
                  absorbing: _saving,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_error != null) ...[
                              _panel(
                                  child: Column(children: [
                                Text(_error!,
                                    style: TextStyle(color: _theme.error)),
                                if (_config == null)
                                  TextButton(
                                      onPressed: _load,
                                      child: const Text('Réessayer')),
                              ])),
                              const SizedBox(height: 18),
                            ],
                            if (_config != null) ...[
                              _plansSection(),
                              const SizedBox(height: 18),
                              _paymentSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      );
}
