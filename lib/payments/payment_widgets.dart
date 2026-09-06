import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'payment_request.dart';
import 'payment_text.dart';

class PaymentAction extends StatelessWidget {
  const PaymentAction(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return FFButtonWidget(
        onPressed: onPressed,
        text: label,
        options: FFButtonOptions(
            width: double.infinity,
            height: 56,
            color: t.primary,
            disabledColor: t.primary.withValues(alpha: 0.16),
            disabledTextColor: t.primaryText.withValues(alpha: 0.6),
            textStyle: t.titleSmall.override(
                color: Theme.of(context).brightness == Brightness.dark
                    ? t.primaryBackground
                    : t.info),
            elevation: 0,
            borderRadius: BorderRadius.circular(t.designToken.radius.md)));
  }
}

class PaymentSurface extends StatelessWidget {
  const PaymentSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Container(
        padding: EdgeInsets.all(t.designToken.spacing.md),
        decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: BorderRadius.circular(t.designToken.radius.md)),
        child: child);
  }
}

String paymentDateLabel(BuildContext context, DateTime date) =>
    dateTimeFormat('yMMMd', date,
        locale: FFLocalizations.of(context).languageCode == 'en' ? 'en' : 'fr');

class PaymentRequestCard extends StatelessWidget {
  const PaymentRequestCard(
      {super.key,
      required this.request,
      required this.onOpen,
      this.admin = false});
  final PaymentRequest request;
  final VoidCallback onOpen;
  final bool admin;
  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final s = t.designToken.spacing;
    final color = switch (request.status) {
      'approved' => t.success,
      'rejected' => t.error,
      _ => t.warning
    };
    return PaymentSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.circle, size: 12, color: color),
        SizedBox(width: s.sm),
        Expanded(
            child: Text(paymentText(context, request.status),
                style: t.titleMedium))
      ]),
      SizedBox(height: s.sm),
      if (request.amount != null)
        Text(
            '${request.amount!.toStringAsFixed(2)} ${request.currency} · ${paymentMethodLabel(context, request.method)}',
            style: t.titleLarge),
      if (admin)
        SelectableText(request.userUid,
            style: t.bodySmall.override(color: t.secondaryText)),
      if (request.createdAt != null)
        Text(paymentDateLabel(context, request.createdAt!),
            style: t.bodyMedium),
      if (request.reference.isNotEmpty)
        Text('${paymentText(context, 'reference')} : ${request.reference}',
            style: t.bodyMedium),
      if (request.reason.isNotEmpty) Text(request.reason, style: t.bodyMedium),
      if (request.newEndSub != null)
        Text(
            '${paymentText(context, 'until')} ${paymentDateLabel(context, request.newEndSub!)}',
            style: t.bodyMedium),
      if (request.transactionId.isNotEmpty)
        SelectableText(
            '${paymentText(context, 'receipt')} : CH-${request.transactionId}',
            style: t.bodySmall),
      SizedBox(height: s.sm),
      TextButton.icon(
          onPressed: onOpen,
          icon: Icon(Icons.receipt_long_outlined, color: t.primary),
          label: Text(paymentText(context, admin ? 'review' : 'proof'),
              style: t.labelLarge.override(color: t.primaryText))),
    ]));
  }
}

class PaymentProofImage extends StatelessWidget {
  const PaymentProofImage({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 280,
      child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.memory(bytes,
              fit: BoxFit.contain,
              semanticLabel: paymentText(context, 'title'),
              errorBuilder: (_, __, ___) => Text(
                  paymentText(context, 'imageError'),
                  style: FlutterFlowTheme.of(context).bodyMedium))));
}

Future<void> showPaymentProof(BuildContext context, Future<Uint8List> proof) =>
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              title: Text(paymentText(context, 'title'),
                  style: FlutterFlowTheme.of(context).titleLarge),
              content: SizedBox(
                  width: 760,
                  child: FutureBuilder<Uint8List>(
                      future: proof,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(paymentText(context, 'error'),
                              style: FlutterFlowTheme.of(context).bodyMedium);
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox(
                              height: 80,
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        return PaymentProofImage(bytes: snapshot.data!);
                      })),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(paymentText(context, 'close')))
              ],
            ));
