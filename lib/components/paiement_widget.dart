import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/transactions/payment_receipt_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _amountController;
  bool _saving = false;
  String _currency = 'GDS';

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaiementModel());
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _saveMembership() async {
    if (_saving || widget.refUser == null) return;

    final selectedEndSub = _model.calendarSelectedDay?.end;
    final selectedMethod = deserializeEnum<PaimentMethod>(_model.dropDownValue);
    final amountInput = _amountController.text.trim();
    final amount = amountInput.isEmpty ? null : _parseAmount(amountInput);
    if (selectedEndSub == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sélectionnez une date d’échéance.'),
          ),
        );
      return;
    }
    if (amountInput.isNotEmpty && amount == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Saisissez un montant valide supérieur à zéro.'),
          ),
        );
      return;
    }
    if (currentUserUid.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Votre session a expiré. Reconnectez-vous puis réessayez.',
            ),
          ),
        );
      return;
    }

    setState(() => _saving = true);

    var membershipSaved = false;
    try {
      final firestore = FirebaseFirestore.instance;
      final transactionReference = PaymentTransactionRecord.collection.doc();
      final receiptCode = PaymentReceiptData.receiptNumberFor(
        transactionReference.id,
      );

      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(widget.refUser!);
        if (!userSnapshot.exists) {
          throw StateError('The user document no longer exists.');
        }

        final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
        final previousEndSub = _readFirestoreDate(userData['end_sub']);
        final memberTimeBefore =
            (userData['member_time'] as num?)?.toInt() ?? 0;

        transaction.update(widget.refUser!, {
          ...createUserRecordData(
            endSub: selectedEndSub,
            method: selectedMethod,
          ),
          ...mapToFirestore({
            'member_time': memberTimeBefore + 1,
            'updated_time': FieldValue.serverTimestamp(),
          }),
        });

        transaction.set(transactionReference, {
          ...createPaymentTransactionRecordData(
            userRef: widget.refUser,
            userUid: widget.refUser!.id,
            userEmail: userData['email'] as String?,
            userDisplayName: userData['display_name'] as String?,
            userCode: userData['code_personnel'] as String?,
            receiptCode: receiptCode,
            previousEndSub: previousEndSub,
            newEndSub: selectedEndSub,
            paymentMethod: selectedMethod,
            amount: amount,
            currency: amount == null ? null : _currency,
            memberTimeBefore: memberTimeBefore,
            memberTimeAfter: memberTimeBefore + 1,
            createdBy: currentUserUid,
            createdByEmail: currentUserEmail.isEmpty ? null : currentUserEmail,
          ),
          'created_at': FieldValue.serverTimestamp(),
        });
      });
      membershipSaved = true;

      final savedTransaction =
          await PaymentTransactionRecord.getDocumentOnce(transactionReference);
      await PaymentReceiptExporter.export(savedTransaction);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      if (membershipSaved) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Abonnement enregistré, mais le reçu PDF n’a pas pu être généré.',
              ),
            ),
          );
        Navigator.pop(context, true);
        return;
      }
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

  DateTime? _readFirestoreDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  double? _parseAmount(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
    return double.parse(parsed.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final compactWidth = viewport.width < 390;
    final compactHeight = viewport.height < 760;
    final selectedDate = _model.calendarSelectedDay?.end;

    return Padding(
      padding: EdgeInsets.all(compactWidth ? 14 : (compactHeight ? 16 : 20)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final splitLayout = constraints.maxWidth >= 620;
          final weekView = !splitLayout && viewport.height < 800;
          final gap = compactHeight ? 10.0 : 14.0;
          final calendar = _buildCalendar(
            context,
            theme,
            rowHeight: splitLayout ? 34 : (compactHeight ? 29 : 32),
            weekView: weekView,
          );
          final paymentControls = _buildPaymentControls(
            context,
            theme,
            selectedDate: selectedDate,
            compact: compactHeight,
          );

          return Column(
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
              SizedBox(height: compactHeight ? 12 : 18),
              if (splitLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: calendar),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: paymentControls),
                  ],
                )
              else ...[
                _buildPaymentMethod(theme),
                SizedBox(height: gap),
                _buildAmountAndCurrency(theme),
                SizedBox(height: gap),
                calendar,
                if (!compactHeight) ...[
                  SizedBox(height: gap),
                  _buildDeadlineSummary(theme, selectedDate, compactHeight),
                ],
                SizedBox(height: gap),
                _buildSaveButton(theme, compactHeight),
                SizedBox(height: compactHeight ? 5 : 8),
                _buildCounterNote(theme),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentControls(
    BuildContext context,
    FlutterFlowTheme theme, {
    required DateTime? selectedDate,
    required bool compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPaymentMethod(theme),
        const SizedBox(height: 14),
        _buildAmountAndCurrency(theme),
        const SizedBox(height: 14),
        _buildDeadlineSummary(theme, selectedDate, compact),
        const SizedBox(height: 16),
        _buildSaveButton(theme, compact),
        const SizedBox(height: 8),
        _buildCounterNote(theme),
      ],
    );
  }

  Widget _buildPaymentMethod(FlutterFlowTheme theme) {
    return DropdownButtonFormField<String>(
      initialValue: _model.dropDownValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Méthode de paiement (optionnelle)',
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: theme.primaryBackground,
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
    );
  }

  Widget _buildAmountAndCurrency(FlutterFlowTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _amountController,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final validAmount = RegExp(
                  r'^\d{0,9}([.,]\d{0,2})?$',
                ).hasMatch(newValue.text);
                return validAmount ? newValue : oldValue;
              }),
            ],
            decoration: InputDecoration(
              labelText: 'Montant (optionnel)',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.payments_outlined),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              filled: true,
              fillColor: theme.primaryBackground,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          label: 'Devise du paiement',
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'GDS', label: Text('GDS')),
              ButtonSegment(value: 'USD', label: Text('USD')),
            ],
            selected: {_currency},
            onSelectionChanged: _saving
                ? null
                : (selection) {
                    setState(() => _currency = selection.first);
                  },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    FlutterFlowTheme theme, {
    required double rowHeight,
    required bool weekView,
  }) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 7),
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
                  size: 19,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? theme.secondary
                      : theme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weekView
                        ? 'Choisir la semaine d’échéance'
                        : 'Date de fin de l’abonnement',
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          FlutterFlowCalendar(
            color: theme.secondary,
            iconColor: theme.secondaryText,
            weekFormat: weekView,
            weekStartsMonday: true,
            rowHeight: rowHeight,
            onChange: (DateTimeRange? range) {
              setState(() => _model.calendarSelectedDay = range);
            },
            titleStyle: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
            dayOfWeekStyle: theme.labelSmall.copyWith(
              color: theme.secondaryText,
              fontWeight: FontWeight.w700,
            ),
            dateStyle: theme.bodySmall,
            selectedDateStyle: theme.bodyMedium.copyWith(
              color: const Color(0xFF10243A),
              fontWeight: FontWeight.w800,
            ),
            inactiveDateStyle: theme.labelSmall.copyWith(
              color: theme.secondaryText.withValues(alpha: .5),
            ),
            locale: FFLocalizations.of(context).languageCode,
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineSummary(
    FlutterFlowTheme theme,
    DateTime? selectedDate,
    bool compact,
  ) {
    return AdminSurface(
      padding: EdgeInsets.all(compact ? 11 : 14),
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
            size: compact ? 36 : 40,
            iconSize: compact ? 19 : 21,
            radius: 12,
          ),
          const SizedBox(width: 11),
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
                      : DateFormat('d MMMM yyyy', 'fr').format(selectedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(FlutterFlowTheme theme, bool compact) {
    return FilledButton.icon(
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
      label: Text(
        _saving ? 'Enregistrement…' : 'Enregistrer et générer le reçu',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: theme.secondary,
        foregroundColor: const Color(0xFF10243A),
        minimumSize: Size.fromHeight(compact ? 48 : 52),
      ),
    );
  }

  Widget _buildCounterNote(FlutterFlowTheme theme) {
    return Text(
      'La transaction sera archivée et son reçu PDF téléchargé.',
      textAlign: TextAlign.center,
      style: theme.bodySmall.copyWith(color: theme.secondaryText),
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
