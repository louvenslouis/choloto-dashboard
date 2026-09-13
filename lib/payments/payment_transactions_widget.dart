import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import '/transactions/payment_receipt_exporter.dart';
import 'package:flutter/material.dart';

enum PaymentTransactionStatusFilter { all, active, cancelled }

class PaymentTransactionsWidget extends StatefulWidget {
  const PaymentTransactionsWidget({super.key});

  static const routeName = 'PaymentTransactions';
  static const routePath = '/payments';

  @override
  State<PaymentTransactionsWidget> createState() =>
      _PaymentTransactionsWidgetState();
}

class _PaymentTransactionsWidgetState extends State<PaymentTransactionsWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  late Stream<List<PaymentTransactionRecord>> _transactionsStream;
  PaymentTransactionStatusFilter _statusFilter =
      PaymentTransactionStatusFilter.all;
  String _methodFilter = 'all';
  String? _downloadingTransactionId;

  @override
  void initState() {
    super.initState();
    _transactionsStream = queryPaymentTransactionRecord();
    logFirebaseEvent(
      'screen_view',
      parameters: {'screen_name': 'PaymentTransactions'},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _transactionsStream = queryPaymentTransactionRecord();
    });
  }

  Future<void> _downloadReceipt(PaymentTransactionRecord transaction) async {
    if (_downloadingTransactionId != null) return;

    setState(() => _downloadingTransactionId = transaction.reference.id);
    try {
      await PaymentReceiptExporter.export(transaction);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Le reçu PDF a été téléchargé.')),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Le reçu n’a pas pu être téléchargé. Veuillez réessayer.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _downloadingTransactionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compactNavigation = MediaQuery.sizeOf(context).width < 992;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: compactNavigation
            ? const AdminMobileAppBar(title: 'Paiements clients')
            : null,
        drawer: compactNavigation
            ? const Drawer(
                width: 264,
                child: SidenavWidget(forceVisible: true),
              )
            : null,
        bottomNavigationBar: compactNavigation
            ? AdminMobileBottomBar(
                activeDestination: AdminMobileDestination.more,
                onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compactNavigation) const SidenavWidget(),
              Expanded(
                child: StreamBuilder<List<PaymentTransactionRecord>>(
                  stream: _transactionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _PaymentTransactionsError(onRetry: _retry);
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final ledger = PaymentTransactionLedger.fromRecords(
                      snapshot.data!,
                    );
                    final visiblePayments = ledger.filtered(
                      query: _searchController.text,
                      status: _statusFilter,
                      method: _methodFilter,
                    );

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactNavigation ? 16 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminSectionHeader(
                                title: 'Paiements clients',
                                icon: Icons.payments_rounded,
                                eyebrow: 'SUIVI FINANCIER',
                                trailing: IconButton(
                                  tooltip: 'Actualiser',
                                  onPressed: _retry,
                                  icon: const Icon(Icons.refresh_rounded),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    backgroundColor: theme.secondaryBackground,
                                    foregroundColor: theme.primary,
                                    side: BorderSide(color: theme.alternate),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              _PaymentSummary(ledger: ledger),
                              const SizedBox(height: 16),
                              _PaymentToolbar(
                                searchController: _searchController,
                                statusFilter: _statusFilter,
                                methodFilter: _methodFilter,
                                resultCount: visiblePayments.length,
                                onSearchChanged: (_) => setState(() {}),
                                onClearSearch: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                onStatusChanged: (status) {
                                  setState(() => _statusFilter = status);
                                },
                                onMethodChanged: (method) {
                                  setState(() => _methodFilter = method);
                                },
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: visiblePayments.isEmpty
                                    ? _PaymentTransactionsEmpty(
                                        filtered: ledger.payments.isNotEmpty,
                                        onReset: () {
                                          _searchController.clear();
                                          setState(() {
                                            _statusFilter =
                                                PaymentTransactionStatusFilter
                                                    .all;
                                            _methodFilter = 'all';
                                          });
                                        },
                                      )
                                    : _PaymentList(
                                        payments: visiblePayments,
                                        downloadingTransactionId:
                                            _downloadingTransactionId,
                                        onDownload: _downloadReceipt,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientPaymentEntry {
  const ClientPaymentEntry({
    required this.transaction,
    required this.cancelled,
    this.cancellation,
  });

  final PaymentTransactionRecord transaction;
  final bool cancelled;
  final PaymentTransactionRecord? cancellation;
}

class PaymentTransactionLedger {
  const PaymentTransactionLedger(this.payments);

  final List<ClientPaymentEntry> payments;

  factory PaymentTransactionLedger.fromRecords(
    List<PaymentTransactionRecord> records,
  ) {
    final cancellationsByPaymentPath = <String, PaymentTransactionRecord>{};
    for (final transaction in records) {
      final related = transaction.relatedTransactionRef;
      if (transaction.isCancellation &&
          transaction.paymentCancelled &&
          related != null) {
        cancellationsByPaymentPath[related.path] = transaction;
      }
    }

    final payments = records
        .where((transaction) => !transaction.isCancellation)
        .map((transaction) {
      final cancellation =
          cancellationsByPaymentPath[transaction.reference.path];
      return ClientPaymentEntry(
        transaction: transaction,
        cancelled: cancellation != null,
        cancellation: cancellation,
      );
    }).toList()
      ..sort(_comparePaymentEntriesByMostRecent);

    return PaymentTransactionLedger(payments);
  }

  int get activeCount => payments.where((payment) => !payment.cancelled).length;

  int get cancelledCount =>
      payments.where((payment) => payment.cancelled).length;

  Map<String, double> get activeTotals {
    final totals = <String, double>{};
    for (final payment in payments) {
      final transaction = payment.transaction;
      final currency = transaction.currency.trim().toUpperCase();
      if (payment.cancelled || !transaction.hasAmount() || currency.isEmpty) {
        continue;
      }
      totals.update(
        currency,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  List<ClientPaymentEntry> filtered({
    required String query,
    required PaymentTransactionStatusFilter status,
    required String method,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return payments.where((entry) {
      if (status == PaymentTransactionStatusFilter.active && entry.cancelled) {
        return false;
      }
      if (status == PaymentTransactionStatusFilter.cancelled &&
          !entry.cancelled) {
        return false;
      }

      final transaction = entry.transaction;
      final paymentMethod = transaction.paymentMethod?.name ?? '';
      if (method != 'all' && paymentMethod != method) return false;
      if (normalizedQuery.isEmpty) return true;

      return [
        transaction.userDisplayName,
        transaction.userEmail,
        transaction.userCode,
        transaction.userUid,
        transaction.receiptCode,
        transaction.reference.id,
        paymentMethod,
      ].any((value) => value.toLowerCase().contains(normalizedQuery));
    }).toList();
  }
}

int _comparePaymentEntriesByMostRecent(
  ClientPaymentEntry first,
  ClientPaymentEntry second,
) {
  final firstDate = first.transaction.createdAt;
  final secondDate = second.transaction.createdAt;
  if (firstDate != null && secondDate != null) {
    final dateOrder = secondDate.compareTo(firstDate);
    if (dateOrder != 0) return dateOrder;
  } else if (firstDate != null) {
    return -1;
  } else if (secondDate != null) {
    return 1;
  }
  return second.transaction.reference.id
      .compareTo(first.transaction.reference.id);
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.ledger});

  final PaymentTransactionLedger ledger;

  @override
  Widget build(BuildContext context) {
    final totals = ledger.activeTotals;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 700
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 32) / 3;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                label: 'Paiements encaissés',
                value: '${ledger.activeCount}',
                icon: Icons.check_circle_outline_rounded,
                color: FlutterFlowTheme.of(context).success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                label: 'Montants actifs',
                value: _formatTotals(totals),
                icon: Icons.account_balance_wallet_outlined,
                color: FlutterFlowTheme.of(context).primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                label: 'Paiements annulés',
                value: '${ledger.cancelledCount}',
                icon: Icons.cancel_outlined,
                color: FlutterFlowTheme.of(context).error,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminSurface(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Row(
        children: [
          AdminIconTile(icon: icon, color: color, size: 42, iconSize: 21),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentToolbar extends StatelessWidget {
  const _PaymentToolbar({
    required this.searchController,
    required this.statusFilter,
    required this.methodFilter,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onMethodChanged,
  });

  final TextEditingController searchController;
  final PaymentTransactionStatusFilter statusFilter;
  final String methodFilter;
  final int resultCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<PaymentTransactionStatusFilter> onStatusChanged;
  final ValueChanged<String> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Rechercher un paiement',
        hintText: 'Client, e-mail, code ou reçu',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer la recherche',
                onPressed: onClearSearch,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: theme.primaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.alternate),
        ),
      ),
    );

    final status = DropdownButtonFormField<PaymentTransactionStatusFilter>(
      key: ValueKey(statusFilter),
      initialValue: statusFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Statut',
        prefixIcon: Icon(Icons.tune_rounded),
      ),
      items: const [
        DropdownMenuItem(
          value: PaymentTransactionStatusFilter.all,
          child: Text('Tous'),
        ),
        DropdownMenuItem(
          value: PaymentTransactionStatusFilter.active,
          child: Text('Encaissés'),
        ),
        DropdownMenuItem(
          value: PaymentTransactionStatusFilter.cancelled,
          child: Text('Annulés'),
        ),
      ],
      onChanged: (value) {
        if (value != null) onStatusChanged(value);
      },
    );

    final method = DropdownButtonFormField<String>(
      key: ValueKey(methodFilter),
      initialValue: methodFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Moyen',
        prefixIcon: Icon(Icons.credit_card_rounded),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tous les moyens')),
        DropdownMenuItem(value: 'moncash', child: Text('MonCash')),
        DropdownMenuItem(value: 'natcash', child: Text('NatCash')),
        DropdownMenuItem(value: 'zelle', child: Text('Zelle')),
        DropdownMenuItem(value: 'cashapp', child: Text('Cash App')),
        DropdownMenuItem(value: 'virement', child: Text('Virement')),
        DropdownMenuItem(value: 'cash', child: Text('Espèces')),
        DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
      ],
      onChanged: (value) {
        if (value != null) onMethodChanged(value);
      },
    );

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 10),
                    Expanded(child: method),
                  ],
                ),
                const SizedBox(height: 12),
                _ResultCount(count: resultCount),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 4, child: search),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: status),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: method),
              const SizedBox(width: 16),
              _ResultCount(count: resultCount),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      '$count ${count > 1 ? 'paiements' : 'paiement'}',
      style: theme.labelMedium.copyWith(
        color: theme.secondaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({
    required this.payments,
    required this.downloadingTransactionId,
    required this.onDownload,
  });

  final List<ClientPaymentEntry> payments;
  final String? downloadingTransactionId;
  final ValueChanged<PaymentTransactionRecord> onDownload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopTable = constraints.maxWidth >= 900;
        return Column(
          children: [
            if (desktopTable) const _PaymentTableHeader(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 28),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = payments[index];
                  final downloading = downloadingTransactionId ==
                      entry.transaction.reference.id;
                  return desktopTable
                      ? _PaymentTableRow(
                          entry: entry,
                          downloading: downloading,
                          onDownload: () => onDownload(entry.transaction),
                        )
                      : _PaymentCard(
                          entry: entry,
                          downloading: downloading,
                          onDownload: () => onDownload(entry.transaction),
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentTableHeader extends StatelessWidget {
  const _PaymentTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final style = theme.labelSmall.copyWith(
      color: theme.secondaryText,
      fontWeight: FontWeight.w800,
      letterSpacing: .7,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 12, 9),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('CLIENT', style: style)),
          Expanded(flex: 2, child: Text('PAIEMENT', style: style)),
          Expanded(flex: 2, child: Text('DATE', style: style)),
          Expanded(flex: 2, child: Text('STATUT', style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PaymentTableRow extends StatelessWidget {
  const _PaymentTableRow({
    required this.entry,
    required this.downloading,
    required this.onDownload,
  });

  final ClientPaymentEntry entry;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final transaction = entry.transaction;
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      radius: 16,
      child: Row(
        children: [
          Expanded(flex: 3, child: _ClientIdentity(transaction: transaction)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _amountLabel(transaction),
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_methodLabel(transaction)} · ${_typeLabel(transaction.transactionType)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(transaction.createdAt),
                    style: theme.bodyMedium),
                const SizedBox(height: 3),
                Text(
                  _expirationLabel(transaction.newEndSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _PaymentStatus(entry: entry)),
          SizedBox(
            width: 48,
            child: _ReceiptButton(
              downloading: downloading,
              onPressed: onDownload,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.entry,
    required this.downloading,
    required this.onDownload,
  });

  final ClientPaymentEntry entry;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final transaction = entry.transaction;
    return AdminSurface(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ClientIdentity(transaction: transaction)),
              const SizedBox(width: 10),
              _PaymentStatus(entry: entry),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.alternate),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _PaymentDetail(
                label: 'Montant',
                value: _amountLabel(transaction),
              ),
              _PaymentDetail(
                label: 'Moyen',
                value: _methodLabel(transaction),
              ),
              _PaymentDetail(
                label: 'Type',
                value: _typeLabel(transaction.transactionType),
              ),
              _PaymentDetail(
                label: 'Enregistré le',
                value: _dateLabel(transaction.createdAt),
              ),
              _PaymentDetail(
                label: 'Échéance',
                value: transaction.newEndSub == null
                    ? 'Non renseignée'
                    : DateFormat('dd/MM/yyyy', 'fr')
                        .format(transaction.newEndSub!),
              ),
            ],
          ),
          if (entry.cancelled &&
              entry.cancellation!.cancellationReason.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Motif : ${entry.cancellation!.cancellationReason}',
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: downloading ? null : onDownload,
              icon: downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Télécharger le reçu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientIdentity extends StatelessWidget {
  const _ClientIdentity({required this.transaction});

  final PaymentTransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = transaction.userDisplayName.trim().isNotEmpty
        ? transaction.userDisplayName.trim()
        : transaction.userEmail.trim().isNotEmpty
            ? transaction.userEmail.trim()
            : 'Client sans nom';
    final details = [
      if (transaction.userEmail.trim().isNotEmpty &&
          transaction.userEmail.trim() != name)
        transaction.userEmail.trim(),
      if (transaction.userCode.trim().isNotEmpty) transaction.userCode.trim(),
      if (transaction.receiptCode.trim().isNotEmpty)
        transaction.receiptCode.trim(),
    ].join(' · ');

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.primary.withValues(alpha: .10),
          foregroundColor: theme.primary,
          child: Text(
            name.characters.first.toUpperCase(),
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentStatus extends StatelessWidget {
  const _PaymentStatus({required this.entry});

  final ClientPaymentEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminStatusPill(
      label: entry.cancelled ? 'Annulé' : 'Encaissé',
      color: entry.cancelled ? theme.error : theme.success,
      compact: true,
      leading: Icon(
        entry.cancelled ? Icons.close_rounded : Icons.check_rounded,
        size: 13,
        color: entry.cancelled ? theme.error : theme.success,
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.labelSmall.copyWith(color: theme.secondaryText),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({required this.downloading, required this.onPressed});

  final bool downloading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Télécharger le reçu PDF',
      onPressed: downloading ? null : onPressed,
      icon: downloading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
    );
  }
}

class _PaymentTransactionsEmpty extends StatelessWidget {
  const _PaymentTransactionsEmpty({
    required this.filtered,
    required this.onReset,
  });

  final bool filtered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: AdminSurface(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminIconTile(
                icon: filtered
                    ? Icons.search_off_rounded
                    : Icons.payments_outlined,
                size: 52,
                iconSize: 25,
              ),
              const SizedBox(height: 14),
              Text(
                filtered
                    ? 'Aucun paiement ne correspond aux filtres.'
                    : 'Aucun paiement n’est encore enregistré.',
                textAlign: TextAlign.center,
                style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              if (filtered) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Réinitialiser les filtres'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentTransactionsError extends StatelessWidget {
  const _PaymentTransactionsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: AdminSurface(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminIconTile(
              icon: Icons.cloud_off_rounded,
              color: theme.error,
              size: 52,
              iconSize: 25,
            ),
            const SizedBox(height: 14),
            Text(
              'Impossible de charger les paiements.',
              style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTotals(Map<String, double> totals) {
  if (totals.isEmpty) return '—';
  final currencies = totals.keys.toList()
    ..sort((first, second) {
      if (first == 'GDS') return -1;
      if (second == 'GDS') return 1;
      return first.compareTo(second);
    });
  return currencies
      .map((currency) =>
          '${NumberFormat('#,##0.##', 'fr').format(totals[currency])} $currency')
      .join(' · ');
}

String _amountLabel(PaymentTransactionRecord transaction) {
  if (!transaction.hasAmount()) return 'Non renseigné';
  final currency = transaction.currency.trim().toUpperCase();
  final amount = NumberFormat('#,##0.00', 'fr').format(transaction.amount);
  return currency.isEmpty ? amount : '$amount $currency';
}

String _dateLabel(DateTime? date) => date == null
    ? 'Date inconnue'
    : DateFormat('dd MMM yyyy · HH:mm', 'fr').format(date);

String _expirationLabel(DateTime? date) => date == null
    ? 'Échéance non renseignée'
    : 'Échéance ${DateFormat('dd/MM/yyyy', 'fr').format(date)}';

String _methodLabel(PaymentTransactionRecord transaction) {
  return switch (transaction.paymentMethod?.name) {
    'moncash' => 'MonCash',
    'natcash' => 'NatCash',
    'zelle' => 'Zelle',
    'cashapp' => 'Cash App',
    'virement' => 'Virement',
    'cash' => 'Espèces',
    'stripe' => 'Stripe',
    _ => 'Non renseigné',
  };
}

String _typeLabel(String type) {
  return switch (type) {
    'renewal' => 'Renouvellement',
    'adjustment' => 'Ajustement',
    _ => 'Abonnement',
  };
}
