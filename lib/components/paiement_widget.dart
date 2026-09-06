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
    this.currentEndSub,
    this.currentPaymentMethod,
    this.currentMemberTime = 0,
  });

  final DocumentReference? refUser;
  final DateTime? currentEndSub;
  final PaimentMethod? currentPaymentMethod;
  final int currentMemberTime;

  @override
  State<PaiementWidget> createState() => _PaiementWidgetState();
}

enum _MembershipAction { subscription, renewal, adjustment }

class _PaiementWidgetState extends State<PaiementWidget> {
  late PaiementModel _model;
  late final TextEditingController _amountController;
  late final bool _hasActiveMembership;
  late _MembershipAction _action;
  late bool _showEditor;
  bool _saving = false;
  bool _downloadingReceipt = false;
  bool _cancelling = false;
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
    _hasActiveMembership = widget.currentEndSub != null &&
        !widget.currentEndSub!.isBefore(DateTime.now());
    _action = _hasActiveMembership
        ? _MembershipAction.renewal
        : _MembershipAction.subscription;
    _showEditor = !_hasActiveMembership;
    if (_hasActiveMembership) {
      _setSelectedDate(widget.currentEndSub!);
      _model.dropDownValue = widget.currentPaymentMethod?.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  void _setSelectedDate(DateTime date) {
    _model.calendarSelectedDay = DateTimeRange(
      start: date.startOfDay,
      end: date.endOfDay,
    );
  }

  void _openRenewal() {
    final currentDeadline = widget.currentEndSub ?? DateTime.now();
    _setSelectedDate(_addOneMonth(currentDeadline));
    _model.dropDownValue = widget.currentPaymentMethod?.name;
    _amountController.clear();
    setState(() {
      _action = _MembershipAction.renewal;
      _showEditor = true;
    });
  }

  void _openAdjustment() {
    _setSelectedDate(widget.currentEndSub ?? DateTime.now());
    _model.dropDownValue = widget.currentPaymentMethod?.name;
    _amountController.clear();
    setState(() {
      _action = _MembershipAction.adjustment;
      _showEditor = true;
    });
  }

  void _showCurrentPlan() {
    setState(() => _showEditor = false);
  }

  Future<void> _redownloadLatestReceipt() async {
    if (_downloadingReceipt || widget.refUser == null) return;

    setState(() => _downloadingReceipt = true);
    try {
      final transactions = await queryPaymentTransactionRecordOnce(
        queryBuilder: (query) =>
            query.where('user_ref', isEqualTo: widget.refUser),
      );
      if (!mounted) return;

      final receiptTransactions = transactions
          .where((transaction) => !transaction.isCancellation)
          .toList();
      if (receiptTransactions.isEmpty) {
        _showMessage(
          'Aucune facture n’est encore enregistrée pour ce membre.',
        );
        return;
      }

      final sortedTransactions = [...receiptTransactions]
        ..sort(_compareTransactionsByMostRecent);
      await PaymentReceiptExporter.export(sortedTransactions.first);
      if (!mounted) return;

      _showMessage('La facture PDF a été téléchargée.');
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'La facture n’a pas pu être téléchargée. Vérifiez la connexion et réessayez.',
      );
    } finally {
      if (mounted) setState(() => _downloadingReceipt = false);
    }
  }

  int _compareTransactionsByMostRecent(
    PaymentTransactionRecord first,
    PaymentTransactionRecord second,
  ) {
    final firstDate = first.createdAt;
    final secondDate = second.createdAt;
    if (firstDate != null && secondDate != null) {
      final dateOrder = secondDate.compareTo(firstDate);
      if (dateOrder != 0) return dateOrder;
    } else if (firstDate != null) {
      return -1;
    } else if (secondDate != null) {
      return 1;
    }

    return second.reference.id.compareTo(first.reference.id);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _addOneMonth(DateTime value) {
    final firstOfNextMonth = value.month == 12
        ? DateTime(value.year + 1, 1)
        : DateTime(value.year, value.month + 1);
    final firstOfFollowingMonth = firstOfNextMonth.month == 12
        ? DateTime(firstOfNextMonth.year + 1, 1)
        : DateTime(firstOfNextMonth.year, firstOfNextMonth.month + 1);
    final lastDayOfNextMonth =
        firstOfFollowingMonth.subtract(const Duration(days: 1)).day;

    return DateTime(
      firstOfNextMonth.year,
      firstOfNextMonth.month,
      value.day.clamp(1, lastDayOfNextMonth).toInt(),
      value.hour,
      value.minute,
    );
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

        final memberTimeAfter = _action == _MembershipAction.adjustment
            ? memberTimeBefore
            : memberTimeBefore + 1;
        final userUpdate = <String, dynamic>{
          ...createUserRecordData(
            endSub: selectedEndSub,
            method: selectedMethod,
          ),
          ...mapToFirestore({
            'member_time': memberTimeAfter,
            'updated_time': FieldValue.serverTimestamp(),
          }),
        };
        if (selectedMethod == null) {
          userUpdate['method'] = FieldValue.delete();
        }

        transaction.update(widget.refUser!, userUpdate);

        transaction.set(transactionReference, {
          ...createPaymentTransactionRecordData(
            userRef: widget.refUser,
            userUid: widget.refUser!.id,
            userEmail: userData['email'] as String?,
            userDisplayName: userData['display_name'] as String?,
            userCode: userData['code_personnel'] as String?,
            receiptCode: receiptCode,
            transactionType: _action.name,
            previousEndSub: previousEndSub,
            newEndSub: selectedEndSub,
            paymentMethod: selectedMethod,
            amount: amount,
            currency: amount == null ? null : _currency,
            memberTimeBefore: memberTimeBefore,
            memberTimeAfter: memberTimeAfter,
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

  Future<void> _cancelMembership() async {
    if (_cancelling || widget.refUser == null) return;

    setState(() => _cancelling = true);
    try {
      final transactions = await queryPaymentTransactionRecordOnce(
        queryBuilder: (query) =>
            query.where('user_ref', isEqualTo: widget.refUser),
      );
      if (!mounted) return;

      final cancelledPaymentPaths = transactions
          .where(
            (transaction) =>
                transaction.isCancellation &&
                transaction.paymentCancelled &&
                transaction.relatedTransactionRef != null,
          )
          .map((transaction) => transaction.relatedTransactionRef!.path)
          .toSet();
      final recordedPayments = transactions
          .where(
            (transaction) =>
                !transaction.isCancellation &&
                !cancelledPaymentPaths.contains(transaction.reference.path),
          )
          .toList()
        ..sort(_compareTransactionsByMostRecent);
      final latestPayment =
          recordedPayments.isEmpty ? null : recordedPayments.first;
      final recordedCurrency = latestPayment?.currency.trim().toUpperCase();
      final refundCurrency = recordedCurrency == 'USD' ? 'USD' : 'GDS';

      final cancellationInput = await showDialog<_MembershipCancellationInput>(
        context: context,
        builder: (_) => _MembershipCancellationDialog(
          hasPayment: latestPayment != null,
          refundCurrency: refundCurrency,
        ),
      );
      if (!mounted || cancellationInput == null) return;

      if (currentUserUid.isEmpty) {
        _showMessage(
          'Votre session a expiré. Reconnectez-vous puis réessayez.',
        );
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final cancellationReference = PaymentTransactionRecord.collection.doc();
      final cancellationCode = PaymentReceiptData.receiptNumberFor(
        cancellationReference.id,
      );

      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(widget.refUser!);
        if (!userSnapshot.exists) {
          throw StateError('The user document no longer exists.');
        }

        final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
        final previousEndSub = _readFirestoreDate(userData['end_sub']);
        final memberTime = (userData['member_time'] as num?)?.toInt() ?? 0;

        transaction.update(widget.refUser!, {
          'end_sub': FieldValue.delete(),
          'method': FieldValue.delete(),
          'updated_time': FieldValue.serverTimestamp(),
        });
        transaction.set(cancellationReference, {
          ...createPaymentTransactionRecordData(
            userRef: widget.refUser,
            userUid: widget.refUser!.id,
            userEmail: userData['email'] as String?,
            userDisplayName: userData['display_name'] as String?,
            userCode: userData['code_personnel'] as String?,
            receiptCode: cancellationCode,
            transactionType: 'cancellation',
            previousEndSub: previousEndSub,
            paymentMethod: widget.currentPaymentMethod,
            memberTimeBefore: memberTime,
            memberTimeAfter: memberTime,
            createdBy: currentUserUid,
            createdByEmail: currentUserEmail.isEmpty ? null : currentUserEmail,
            relatedTransactionRef: latestPayment?.reference,
            paymentCancelled: latestPayment != null,
            cancellationReason: cancellationInput.reason,
            refundedAmount: cancellationInput.refundedAmount,
            refundCurrency: cancellationInput.refundedAmount == null
                ? null
                : cancellationInput.refundCurrency,
          ),
          'created_at': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      final returnedAmountLabel = cancellationInput.refundedAmount == null
          ? null
          : '${NumberFormat('#,##0.00', 'fr').format(cancellationInput.refundedAmount)} '
              '${cancellationInput.refundCurrency}';
      final cancellationMessage = latestPayment == null
          ? 'Abonnement annulé.'
          : 'Dernier paiement et abonnement annulés.';
      _showMessage(
        returnedAmountLabel == null
            ? cancellationMessage
            : '$cancellationMessage Montant retourné : $returnedAmountLabel.',
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'L’annulation a échoué. Vérifiez la connexion et réessayez.',
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
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
          final editorBody = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasActiveMembership) ...[
                _buildEditorContext(theme),
                SizedBox(height: gap),
              ],
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminDialogHeader(
                title: _dialogTitle,
                subtitle: _dialogSubtitle,
                icon: Icons.workspace_premium_rounded,
                iconColor: theme.secondary,
                onClose: () => Navigator.pop(context),
              ),
              SizedBox(height: compactHeight ? 12 : 18),
              if (_hasActiveMembership && !_showEditor)
                _buildCurrentPlan(theme, compact: compactWidth)
              else if (_hasActiveMembership && compactHeight)
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: editorBody,
                  ),
                )
              else
                editorBody,
            ],
          );
        },
      ),
    );
  }

  String get _dialogTitle {
    if (!_hasActiveMembership) return 'Abonnement VIP';
    if (!_showEditor) return 'Plan VIP actuel';
    return _action == _MembershipAction.adjustment
        ? 'Modifier le plan VIP'
        : 'Prolonger le plan VIP';
  }

  String get _dialogSubtitle {
    if (!_hasActiveMembership) {
      return 'Enregistrer un paiement et activer l’accès';
    }
    if (!_showEditor) {
      return 'Consulter, prolonger ou modifier l’abonnement en cours';
    }
    return _action == _MembershipAction.adjustment
        ? 'Corriger les informations sans ajouter un nouveau mois'
        : 'Enregistrer le renouvellement et la nouvelle échéance';
  }

  Widget _buildCurrentPlan(
    FlutterFlowTheme theme, {
    required bool compact,
  }) {
    final deadline = DateFormat(
      'd MMMM yyyy',
      'fr',
    ).format(widget.currentEndSub!);
    final method = widget.currentPaymentMethod == null
        ? 'Non renseignée'
        : _paymentLabel(widget.currentPaymentMethod!);

    final renewButton = FilledButton.icon(
      onPressed: _openRenewal,
      icon: const Icon(Icons.autorenew_rounded),
      label: Text(compact ? 'Prolonger' : 'Prolonger l’abonnement'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: theme.primary,
        foregroundColor: theme.info,
      ),
    );
    final editButton = OutlinedButton.icon(
      onPressed: _openAdjustment,
      icon: const Icon(Icons.edit_calendar_outlined),
      label: Text(compact ? 'Modifier' : 'Modifier le plan actuel'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: theme.primaryText,
        side: BorderSide(color: theme.alternate),
      ),
    );
    final receiptButton = TextButton.icon(
      onPressed: _downloadingReceipt || widget.refUser == null
          ? null
          : _redownloadLatestReceipt,
      icon: _downloadingReceipt
          ? SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary,
              ),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(
        _downloadingReceipt
            ? 'Préparation de la facture…'
            : compact
                ? 'Facture PDF'
                : 'Retélécharger la facture PDF',
      ),
      style: TextButton.styleFrom(
        minimumSize: Size.fromHeight(compact ? 40 : 44),
        foregroundColor: theme.primary,
      ),
    );
    final cancellationButton = TextButton.icon(
      onPressed:
          _cancelling || widget.refUser == null ? null : _cancelMembership,
      icon: _cancelling
          ? SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.error,
              ),
            )
          : const Icon(Icons.cancel_outlined),
      label: Text(
        _cancelling
            ? 'Annulation…'
            : compact
                ? 'Annuler'
                : 'Annuler paiement / abonnement',
      ),
      style: TextButton.styleFrom(
        minimumSize: Size.fromHeight(compact ? 40 : 44),
        foregroundColor: theme.error,
      ),
    );

    return AdminSurface(
      padding: EdgeInsets.all(compact ? 12 : 20),
      color: theme.primaryBackground,
      borderColor: theme.secondary.withValues(alpha: .25),
      radius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminIconTile(
                icon: Icons.workspace_premium_rounded,
                color: theme.secondary,
                size: compact ? 42 : 48,
                iconSize: compact ? 21 : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abonnement VIP CHOLOTO',
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AdminStatusPill(
                      label: 'PLAN ACTIF',
                      color: theme.success,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 20),
          AdminSurface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: theme.secondaryBackground,
            radius: 16,
            child: compact
                ? Column(
                    children: [
                      _buildCompactPlanMetric(
                        theme,
                        icon: Icons.event_available_rounded,
                        label: 'Échéance actuelle',
                        value: deadline,
                      ),
                      const SizedBox(height: 8),
                      _buildCompactPlanMetric(
                        theme,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Méthode actuelle',
                        value: method,
                      ),
                      const SizedBox(height: 8),
                      _buildCompactPlanMetric(
                        theme,
                        icon: Icons.history_rounded,
                        label: 'Ancienneté VIP',
                        value: '${widget.currentMemberTime} mois actifs',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildPlanMetric(
                          theme,
                          icon: Icons.event_available_rounded,
                          label: 'Échéance actuelle',
                          value: deadline,
                        ),
                      ),
                      Expanded(
                        child: _buildPlanMetric(
                          theme,
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Méthode actuelle',
                          value: method,
                        ),
                      ),
                      Expanded(
                        child: _buildPlanMetric(
                          theme,
                          icon: Icons.history_rounded,
                          label: 'Ancienneté VIP',
                          value: '${widget.currentMemberTime} mois actifs',
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: compact ? 12 : 20),
          Row(
            children: [
              Expanded(child: renewButton),
              const SizedBox(width: 10),
              Expanded(child: editButton),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Row(
            children: [
              Expanded(child: receiptButton),
              const SizedBox(width: 8),
              Expanded(child: cancellationButton),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              'La prolongation ajoute un nouveau mois. Une modification corrige le plan actuel sans augmenter l’ancienneté.',
              textAlign: TextAlign.center,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanMetric(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 19, color: theme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelSmall.copyWith(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPlanMetric(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.copyWith(
              color: theme.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorContext(FlutterFlowTheme theme) {
    final isAdjustment = _action == _MembershipAction.adjustment;
    return AdminSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      color: theme.accent1,
      borderColor: theme.secondary.withValues(alpha: .22),
      radius: 14,
      child: Row(
        children: [
          Icon(
            isAdjustment
                ? Icons.edit_calendar_outlined
                : Icons.autorenew_rounded,
            size: 20,
            color: theme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isAdjustment
                  ? 'Modification du plan actif'
                  : 'Renouvellement du plan actif',
              style: theme.bodySmall.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _showCurrentPlan,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Plan actuel'),
          ),
        ],
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
      key: ValueKey('payment-method-${_action.name}-${_model.dropDownValue}'),
      initialValue: _model.dropDownValue ?? '',
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
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Aucune méthode'),
        ),
        ...PaimentMethod.values.map(
          (method) => DropdownMenuItem(
            value: method.name,
            child: Text(_paymentLabel(method)),
          ),
        ),
      ],
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
            key: ValueKey(
              'membership-calendar-${_action.name}',
            ),
            color: theme.secondary,
            initialDate: _model.calendarSelectedDay?.start,
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
                  _action == _MembershipAction.adjustment
                      ? 'Échéance modifiée'
                      : 'Nouvelle échéance',
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
        _saving ? 'Enregistrement…' : _saveButtonLabel,
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

  String get _saveButtonLabel {
    switch (_action) {
      case _MembershipAction.subscription:
        return 'Enregistrer et générer le reçu';
      case _MembershipAction.renewal:
        return 'Prolonger et générer le reçu';
      case _MembershipAction.adjustment:
        return 'Modifier et générer le reçu';
    }
  }

  String _paymentLabel(PaimentMethod method) {
    switch (method) {
      case PaimentMethod.moncash:
        return 'MonCash';
      case PaimentMethod.cash:
        return 'Espèces';
      case PaimentMethod.stripe:
        return 'Carte / Stripe';
      case PaimentMethod.natcash:
        return 'Natcash';
      case PaimentMethod.zelle:
        return 'Zelle';
      case PaimentMethod.cashapp:
        return 'CashApp';
      case PaimentMethod.virement:
        return 'Virement';
    }
  }
}

class _MembershipCancellationDialog extends StatefulWidget {
  const _MembershipCancellationDialog({
    required this.hasPayment,
    required this.refundCurrency,
  });

  final bool hasPayment;
  final String refundCurrency;

  @override
  State<_MembershipCancellationDialog> createState() =>
      _MembershipCancellationDialogState();
}

class _MembershipCancellationDialogState
    extends State<_MembershipCancellationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _refundedAmountController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _refundedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final title = widget.hasPayment
        ? 'Annuler le paiement et l’abonnement ?'
        : 'Annuler l’abonnement ?';

    return AdminDialogFrame(
      maxWidth: 500,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminDialogHeader(
                title: title,
                icon: Icons.cancel_outlined,
                iconColor: theme.error,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 18),
              AdminSurface(
                padding: const EdgeInsets.all(14),
                color: theme.error.withValues(alpha: .08),
                borderColor: theme.error.withValues(alpha: .22),
                radius: 14,
                child: Text(
                  _explanation(),
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _refundedAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final validAmount = RegExp(
                      r'^\d{0,9}([.,]\d{0,2})?$',
                    ).hasMatch(newValue.text);
                    return validAmount ? newValue : oldValue;
                  }),
                ],
                decoration: InputDecoration(
                  labelText: 'Montant retourné (optionnel)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_exchange_rounded),
                  suffixText: widget.refundCurrency,
                  helperText: 'Laissez vide si aucun montant n’a été remis',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final amount = _parseRefundedAmount(value);
                  if (amount == null) {
                    return 'Saisissez un montant valide, égal ou supérieur à zéro.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reasonController,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Motif de l’annulation',
                  hintText: 'Ex. : demande du client',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indiquez le motif de l’annulation.'
                    : null,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 340;
                  final cancel = OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Retour'),
                  );
                  final confirm = FilledButton.icon(
                    onPressed: () {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      Navigator.pop(
                        context,
                        _MembershipCancellationInput(
                          reason: _reasonController.text.trim(),
                          refundedAmount: _parseRefundedAmount(
                            _refundedAmountController.text,
                          ),
                          refundCurrency: widget.refundCurrency,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      widget.hasPayment
                          ? 'Annuler les deux'
                          : 'Annuler l’abonnement',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.error,
                      foregroundColor: Colors.white,
                    ),
                  );

                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        confirm,
                        const SizedBox(height: 10),
                        cancel,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: 12),
                      Expanded(child: confirm),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _explanation() {
    if (!widget.hasPayment) {
      return 'Aucun paiement associé n’a été trouvé. L’accès VIP sera retiré immédiatement.';
    }
    return 'Seul le dernier paiement sera marqué comme annulé et retiré des '
        'totaux. Les paiements précédents resteront comptabilisés. L’accès VIP '
        'sera retiré immédiatement et aucun remboursement monétaire '
        'automatique ne sera déclenché.';
  }

  double? _parseRefundedAmount(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    if (parsed > 999999999.99) return null;
    return double.parse(parsed.toStringAsFixed(2));
  }
}

class _MembershipCancellationInput {
  const _MembershipCancellationInput({
    required this.reason,
    required this.refundedAmount,
    required this.refundCurrency,
  });

  final String reason;
  final double? refundedAmount;
  final String refundCurrency;
}
