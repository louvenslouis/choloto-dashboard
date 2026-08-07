import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'paiement_model.dart';
export 'paiement_model.dart';

class PaiementWidget extends StatefulWidget {
  const PaiementWidget({
    super.key,
    required this.refUser,
  });

  final DocumentReference? refUser;

  @override
  State<PaiementWidget> createState() => _PaiementWidgetState();
}

class _PaiementWidgetState extends State<PaiementWidget> {
  late PaiementModel _model;
  bool _saving = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaiementModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _saveMembership() async {
    if (_saving || widget.refUser == null) return;
    setState(() => _saving = true);

    try {
      await widget.refUser!.update({
        ...createUserRecordData(
          endSub: _model.calendarSelectedDay?.end,
          method: deserializeEnum<PaimentMethod>(_model.dropDownValue),
        ),
        ...mapToFirestore({
          'member_time': FieldValue.increment(1),
        }),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'La mise à jour a échoué. Vérifiez la connexion et réessayez.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 390;
    final selectedDate = _model.calendarSelectedDay?.end;

    return Padding(
      padding: EdgeInsets.all(compact ? 18 : 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDialogHeader(
            title: 'Abonnement VIP',
            subtitle: 'Enregistrer un paiement et prolonger l’accès',
            icon: Icons.workspace_premium_rounded,
            iconColor: theme.secondary,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: _model.dropDownValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Méthode de paiement',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: PaimentMethod.values
                .map(
                  (method) => DropdownMenuItem(
                    value: method.name,
                    child: Text(_paymentLabel(method)),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _model.dropDownValue = value),
          ),
          const SizedBox(height: 16),
          AdminSurface(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
            color: theme.primaryBackground,
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? theme.secondary
                            : theme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Date de fin de l’abonnement',
                          style: theme.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FlutterFlowCalendar(
                  color: theme.secondary,
                  iconColor: theme.secondaryText,
                  weekFormat: false,
                  weekStartsMonday: true,
                  rowHeight: compact ? 34 : 38,
                  onChange: (DateTimeRange? range) {
                    setState(() => _model.calendarSelectedDay = range);
                  },
                  titleStyle: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  dayOfWeekStyle: theme.labelMedium.copyWith(
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  dateStyle: theme.bodyMedium,
                  selectedDateStyle: theme.titleSmall.copyWith(
                    color: const Color(0xFF10243A),
                    fontWeight: FontWeight.w800,
                  ),
                  inactiveDateStyle: theme.labelMedium.copyWith(
                    color: theme.secondaryText.withValues(alpha: .5),
                  ),
                  locale: FFLocalizations.of(context).languageCode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AdminSurface(
            padding: const EdgeInsets.all(14),
            color: theme.accent1,
            borderColor: theme.secondary.withValues(alpha: .26),
            radius: 16,
            child: Row(
              children: [
                AdminIconTile(
                  icon: Icons.add_task_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? theme.secondary
                      : theme.primary,
                  size: 40,
                  iconSize: 21,
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle échéance',
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDate == null
                            ? 'Sélectionnez une date'
                            : DateFormat('d MMMM yyyy', 'fr')
                                .format(selectedDate),
                        style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _saveMembership,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF10243A),
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: const Color(0xFF10243A),
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Le compteur de mois actifs sera augmenté de 1.',
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(PaimentMethod method) {
    switch (method) {
      case PaimentMethod.moncash:
        return 'MonCash';
      case PaimentMethod.cash:
        return 'Espèces';
      case PaimentMethod.stripe:
        return 'Carte / Stripe';
    }
  }
}
