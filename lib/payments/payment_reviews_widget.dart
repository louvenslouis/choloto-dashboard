import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import '/transactions/payment_receipt_exporter.dart';
import 'payment_request.dart';
import 'payment_review_service.dart';
import 'payment_text.dart';
import 'payment_widgets.dart';

class PaymentReviewsWidget extends StatefulWidget {
  const PaymentReviewsWidget({super.key});
  static const routeName = 'PaymentReviews';
  static const routePath = '/payment-reviews';
  @override
  State<PaymentReviewsWidget> createState() => _PaymentReviewsWidgetState();
}

class _PaymentReviewsWidgetState extends State<PaymentReviewsWidget> {
  final _repository = PaymentRequestRepository();
  final _scaffold = GlobalKey<ScaffoldState>();
  String? _status = 'pending';
  late Stream<List<PaymentRequest>> _stream;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _stream = _repository.watch(status: _status);
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final s = t.designToken.spacing;
    final desktop = MediaQuery.sizeOf(context).width >= 992;
    return Scaffold(
        key: _scaffold,
        backgroundColor: t.primaryBackground,
        drawer: desktop
            ? null
            : const Drawer(child: SidenavWidget(forceVisible: true)),
        appBar: desktop
            ? null
            : AdminMobileAppBar(title: paymentText(context, 'adminTitle')),
        bottomNavigationBar: desktop
            ? null
            : AdminMobileBottomBar(
                activeDestination: AdminMobileDestination.more,
                onOpenMenu: () => _scaffold.currentState?.openDrawer()),
        body: SafeArea(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SidenavWidget(),
          Expanded(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: ListView(padding: EdgeInsets.all(s.md), children: [
                        Text(paymentText(context, 'adminTitle'),
                            style: t.headlineMedium),
                        SizedBox(height: s.md),
                        DropdownButtonFormField<String>(
                            initialValue: _status ?? 'all',
                            isExpanded: true,
                            style: t.bodyLarge,
                            dropdownColor: t.secondaryBackground,
                            items: [
                              for (final value in [
                                'pending',
                                'approved',
                                'rejected',
                                'all'
                              ])
                                DropdownMenuItem(
                                    value: value,
                                    child: Text(paymentText(context, value)))
                            ],
                            onChanged: (v) => setState(() {
                                  _status = v == 'all' ? null : v;
                                  _refresh();
                                })),
                        SizedBox(height: s.lg),
                        StreamBuilder<List<PaymentRequest>>(
                            stream: _stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return PaymentSurface(
                                    child: Column(children: [
                                  Text(paymentText(context, 'error'),
                                      style: t.bodyLarge),
                                  TextButton(
                                      onPressed: () => setState(_refresh),
                                      child:
                                          Text(paymentText(context, 'retry'))),
                                ]));
                              }
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator(
                                        color: t.primary));
                              }
                              if (snapshot.data!.isEmpty) {
                                return PaymentSurface(
                                    child: Text(paymentText(context, 'empty'),
                                        style: t.bodyLarge));
                              }
                              return Column(children: [
                                for (final request in snapshot.data!)
                                  Padding(
                                      padding: EdgeInsets.only(bottom: s.md),
                                      child: PaymentRequestCard(
                                          request: request,
                                          admin: true,
                                          onOpen: () => Navigator.of(context)
                                              .push(MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      PaymentReviewPage(
                                                          request: request))))),
                              ]);
                            }),
                      ])))),
        ])));
  }
}

/// Live entry on the dashboard; the query downloads metadata, never images.
class PendingPaymentRequestsTile extends StatefulWidget {
  const PendingPaymentRequestsTile({super.key});
  @override
  State<PendingPaymentRequestsTile> createState() =>
      _PendingPaymentRequestsTileState();
}

class _PendingPaymentRequestsTileState
    extends State<PendingPaymentRequestsTile> {
  late final _stream = PaymentRequestRepository().watch(status: 'pending');
  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Padding(
        padding: EdgeInsets.only(bottom: t.designToken.spacing.md),
        child: AdminSurface(
            child: StreamBuilder<List<PaymentRequest>>(
                stream: _stream,
                builder: (context, snapshot) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const AdminIconTile(
                          icon: Icons.receipt_long_outlined),
                      title: Text(paymentText(context, 'adminTitle'),
                          style: t.titleLarge),
                      subtitle: Text(
                          snapshot.hasError
                              ? paymentText(context, 'error')
                              : '${paymentText(context, 'pending')}${snapshot.hasData ? ' · ${snapshot.data!.length}' : ''}',
                          style: t.bodyMedium),
                      trailing: Icon(Icons.chevron_right, color: t.primary),
                      onTap: () =>
                          context.pushNamed(PaymentReviewsWidget.routeName),
                    ))));
  }
}

class PaymentReviewPage extends StatefulWidget {
  const PaymentReviewPage(
      {super.key,
      required this.request,
      this.loadReview,
      this.approveReview,
      this.rejectReview});
  final Future<PaymentReviewData> Function()? loadReview;
  final Future<String> Function(DateTime, double, String, String)?
      approveReview;
  final Future<void> Function(String)? rejectReview;
  final PaymentRequest request;
  @override
  State<PaymentReviewPage> createState() => _PaymentReviewPageState();
}

class _PaymentReviewPageState extends State<PaymentReviewPage> {
  late Future<PaymentReviewData> _future;
  final _reason = TextEditingController();
  final _amount = TextEditingController();
  String _currency = 'GDS';
  String _method = 'moncash';
  DateTime? _end;
  bool _busy = false;
  String? _error;
  String? _receiptId;
  bool _rejected = false;
  @override
  void initState() {
    super.initState();
    _amount.text = widget.request.amount?.toStringAsFixed(2) ?? '';
    if (paymentCurrencies.contains(widget.request.currency)) {
      _currency = widget.request.currency;
    }
    if (paymentMethods.contains(widget.request.method)) {
      _method = widget.request.method;
    }
    _receiptId = widget.request.transactionId.isEmpty
        ? null
        : widget.request.transactionId;
    _future = _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<PaymentReviewData> _load() async {
    if (widget.loadReview != null) {
      final data = await widget.loadReview!();
      _end ??= suggestedPaymentEnd(
          paymentDate(data.profile?['end_sub']), DateTime.now());
      return data;
    }
    final profile = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.request.userUid)
        .get();
    // A missing or corrupt image must never enable approval. Rejection remains
    // available so an invalid submission cannot get stuck in the queue.
    Uint8List? proof;
    try {
      final bytes =
          await PaymentRequestRepository().loadProof(widget.request.id);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      proof = bytes;
    } catch (_) {
      proof = null;
    }
    final data = profile.data();
    _end ??= suggestedPaymentEnd(paymentDate(data?['end_sub']), DateTime.now());
    return PaymentReviewData(data, proof);
  }

  Future<void> _decide({required bool approve}) async {
    if (_busy) return;
    final amount = parsePaymentAmount(_amount.text);
    if (approve && amount == null) {
      setState(() => _error = 'amountError');
      return;
    }
    if (!approve && _reason.text.trim().isEmpty) {
      setState(() => _error = 'required');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (approve) {
        final id = widget.approveReview != null
            ? await widget.approveReview!(_end!, amount!, _currency, _method)
            : await PaymentReviewService().approve(
                requestId: widget.request.id,
                adminUid: currentUserUid,
                adminEmail: currentUserEmail,
                amount: amount!,
                currency: _currency,
                method: _method,
                endSub: _end!);
        if (mounted) setState(() => _receiptId = id);
      } else {
        if (widget.rejectReview != null) {
          await widget.rejectReview!(_reason.text);
        } else {
          await PaymentReviewService().reject(
              requestId: widget.request.id,
              adminUid: currentUserUid,
              reason: _reason.text);
        }
        if (mounted) setState(() => _rejected = true);
      }
    } on PaymentReviewException catch (e) {
      if (mounted) setState(() => _error = e.key);
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await PaymentTransactionRecord.getDocumentOnce(
          PaymentTransactionRecord.collection.doc(_receiptId!));
      await PaymentReceiptExporter.export(receipt);
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final s = t.designToken.spacing;
    final pending =
        widget.request.status == 'pending' && _receiptId == null && !_rejected;
    return Scaffold(
        backgroundColor: t.primaryBackground,
        appBar: AppBar(
            backgroundColor: t.secondaryBackground,
            foregroundColor: t.primaryText,
            title: Text(paymentText(context, 'review'), style: t.titleLarge)),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(padding: EdgeInsets.all(s.md), children: [
                      PaymentSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            if (widget.request.amount != null)
                              Text(
                                  '${widget.request.amount!.toStringAsFixed(2)} ${widget.request.currency} · ${paymentMethodLabel(context, widget.request.method)}',
                                  style: t.headlineSmall),
                            if (widget.request.reference.isNotEmpty)
                              Text(
                                  '${paymentText(context, 'reference')} : ${widget.request.reference}',
                                  style: t.bodyLarge),
                            if (widget.request.createdAt != null)
                              Text(
                                  paymentDateLabel(
                                      context, widget.request.createdAt!),
                                  style: t.bodyMedium),
                            if (widget.request.note.isNotEmpty)
                              Text(widget.request.note, style: t.bodyMedium),
                            SelectableText(widget.request.userUid,
                                style: t.bodySmall),
                          ])),
                      SizedBox(height: s.md),
                      FutureBuilder<PaymentReviewData>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Column(children: [
                                Text(paymentText(context, 'error'),
                                    style: t.bodyLarge),
                                TextButton(
                                    onPressed: () =>
                                        setState(() => _future = _load()),
                                    child: Text(paymentText(context, 'retry')))
                              ]);
                            }
                            if (!snapshot.hasData) {
                              return Center(
                                  child: CircularProgressIndicator(
                                      color: t.primary));
                            }
                            final data = snapshot.data!;
                            final previousEnd =
                                paymentDate(data.profile?['end_sub']);
                            return PaymentSurface(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                  Text(
                                      data.profile?['display_name']
                                              as String? ??
                                          widget.request.userUid,
                                      style: t.titleLarge),
                                  Text(data.profile?['email'] as String? ?? '',
                                      style: t.bodyLarge),
                                  Text(
                                      data.profile?['phone_number']
                                              as String? ??
                                          '',
                                      style: t.bodyMedium),
                                  Text(
                                      '${paymentText(context, 'currentEnd')} : ${previousEnd == null ? paymentText(context, 'noPlan') : paymentDateLabel(context, previousEnd)}',
                                      style: t.bodyMedium),
                                  if (data.proof != null)
                                    PaymentProofImage(bytes: data.proof!)
                                  else
                                    Text(paymentText(context, 'imageError'),
                                        style: t.bodyLarge
                                            .override(color: t.error)),
                                  if (data.profile == null)
                                    Text(paymentText(context, 'missingProfile'),
                                        style: t.bodyLarge
                                            .override(color: t.error)),
                                  if (pending) ...[
                                    SizedBox(height: s.md),
                                    Text(paymentText(context, 'endHelp'),
                                        style: t.bodyMedium),
                                    SizedBox(height: s.md),
                                    TextField(
                                        key: const ValueKey('review-amount'),
                                        controller: _amount,
                                        enabled: !_busy,
                                        style: t.bodyLarge,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                            labelText:
                                                paymentText(context, 'amount'),
                                            labelStyle: t.bodyMedium,
                                            border:
                                                const OutlineInputBorder())),
                                    SizedBox(height: s.md),
                                    DropdownButtonFormField<String>(
                                        initialValue: _currency,
                                        isExpanded: true,
                                        style: t.bodyLarge,
                                        dropdownColor: t.secondaryBackground,
                                        decoration: InputDecoration(
                                            labelText: paymentText(
                                                context, 'currency'),
                                            labelStyle: t.bodyMedium,
                                            border: const OutlineInputBorder()),
                                        items: [
                                          for (final value in paymentCurrencies)
                                            DropdownMenuItem(
                                                value: value,
                                                child: Text(value))
                                        ],
                                        onChanged: _busy
                                            ? null
                                            : (value) => setState(
                                                () => _currency = value!)),
                                    SizedBox(height: s.md),
                                    DropdownButtonFormField<String>(
                                        initialValue: _method,
                                        isExpanded: true,
                                        style: t.bodyLarge,
                                        dropdownColor: t.secondaryBackground,
                                        decoration: InputDecoration(
                                            labelText:
                                                paymentText(context, 'method'),
                                            labelStyle: t.bodyMedium,
                                            border: const OutlineInputBorder()),
                                        items: [
                                          for (final value in paymentMethods)
                                            DropdownMenuItem(
                                                value: value,
                                                child: Text(paymentMethodLabel(
                                                    context, value)))
                                        ],
                                        onChanged: _busy
                                            ? null
                                            : (value) => setState(
                                                () => _method = value!)),
                                    TextButton.icon(
                                        onPressed: _busy
                                            ? null
                                            : () async {
                                                final now = DateTime.now();
                                                final date =
                                                    await showDatePicker(
                                                        context: context,
                                                        initialDate: _end!,
                                                        firstDate: DateTime(
                                                            now.year,
                                                            now.month,
                                                            now.day),
                                                        lastDate: DateTime(
                                                            _end!.year + 10));
                                                if (date != null && mounted) {
                                                  setState(() => _end =
                                                      DateTime(
                                                          date.year,
                                                          date.month,
                                                          date.day,
                                                          23,
                                                          59,
                                                          59));
                                                }
                                              },
                                        icon: Icon(
                                            Icons.calendar_month_outlined,
                                            color: t.primary),
                                        label: Text(
                                            '${paymentText(context, 'end')} : ${paymentDateLabel(context, _end!)}',
                                            style: t.labelLarge
                                                .override(color: t.primary))),
                                    PaymentAction(
                                        key: const ValueKey('approve-payment'),
                                        label: paymentText(context, 'approve'),
                                        onPressed: _busy ||
                                                data.profile == null ||
                                                data.proof == null
                                            ? null
                                            : () => _decide(approve: true)),
                                    SizedBox(height: s.lg),
                                    TextField(
                                        key: const ValueKey('rejection-reason'),
                                        controller: _reason,
                                        enabled: !_busy,
                                        maxLength: 500,
                                        minLines: 2,
                                        maxLines: 4,
                                        style: t.bodyLarge,
                                        decoration: InputDecoration(
                                            labelText:
                                                paymentText(context, 'reason'),
                                            helperText: paymentText(
                                                context, 'reasonHelp'),
                                            helperMaxLines: 2,
                                            helperStyle: t.bodySmall,
                                            counterStyle: t.bodySmall,
                                            labelStyle: t.bodyMedium.override(
                                                color: t.secondaryText),
                                            border:
                                                const OutlineInputBorder())),
                                    OutlinedButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _decide(approve: false),
                                        child: Text(
                                            paymentText(context, 'reject'),
                                            style: t.labelLarge
                                                .override(color: t.error))),
                                  ],
                                ]));
                          }),
                      if (_busy)
                        Padding(
                            padding: EdgeInsets.all(s.md),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: t.primary))),
                      if (_receiptId != null) ...[
                        SizedBox(height: s.md),
                        Text(paymentText(context, 'approved'),
                            style: t.titleLarge.override(color: t.success)),
                        SelectableText('CH-$_receiptId', style: t.bodyMedium),
                        PaymentAction(
                            label: paymentText(context, 'download'),
                            onPressed: _busy ? null : _download),
                      ],
                      if (_rejected || widget.request.status == 'rejected')
                        Text(
                            '${paymentText(context, 'rejected')}\n${_rejected ? _reason.text.trim() : widget.request.reason}',
                            style: t.bodyLarge),
                      if (_error != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(paymentText(context, _error!),
                                style: t.bodyLarge.override(color: t.error))),
                    ])))));
  }
}

class PaymentReviewData {
  const PaymentReviewData(this.profile, this.proof);
  final Map<String, dynamic>? profile;
  final Uint8List? proof;
}
