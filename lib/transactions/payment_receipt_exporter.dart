import 'dart:typed_data';

import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PaymentReceiptData {
  const PaymentReceiptData({
    required this.receiptNumber,
    required this.transactionId,
    required this.customerName,
    required this.customerEmail,
    required this.personalCode,
    required this.issuedAt,
    required this.expiresAt,
    this.transactionType = 'subscription',
    required this.paymentMethod,
    required this.amount,
    required this.currency,
  });

  factory PaymentReceiptData.fromRecord(PaymentTransactionRecord record) {
    final transactionId = record.reference.id;
    final customerName = record.userDisplayName.trim();

    return PaymentReceiptData(
      receiptNumber: record.receiptCode.trim().isEmpty
          ? receiptNumberFor(transactionId)
          : record.receiptCode.trim(),
      transactionId: transactionId,
      customerName: customerName.isEmpty ? 'Membre CHOLOTO' : customerName,
      customerEmail: record.userEmail.trim(),
      personalCode: record.userCode.trim(),
      issuedAt: record.createdAt ?? DateTime.now(),
      expiresAt: record.newEndSub,
      transactionType: record.transactionType,
      paymentMethod: record.paymentMethod,
      amount: record.hasAmount() ? record.amount : null,
      currency: record.hasCurrency() ? record.currency : null,
    );
  }

  final String receiptNumber;
  final String transactionId;
  final String customerName;
  final String customerEmail;
  final String personalCode;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String transactionType;
  final PaimentMethod? paymentMethod;
  final double? amount;
  final String? currency;

  bool get hasAmount => amount != null && currency != null;

  static String receiptNumberFor(String transactionId) {
    return 'CH-${transactionId.isEmpty ? 'TRANSACTION' : transactionId}';
  }
}

class PaymentReceiptExporter {
  const PaymentReceiptExporter._();

  static final _purple = PdfColor.fromHex('#65208D');
  static final _deepPurple = PdfColor.fromHex('#3E0B5E');
  static final _magenta = PdfColor.fromHex('#ED4FA5');
  static final _blue = PdfColor.fromHex('#2468E8');
  static final _red = PdfColor.fromHex('#D92F45');
  static final _ink = PdfColor.fromHex('#17131C');
  static final _muted = PdfColor.fromHex('#655F69');
  static final _line = PdfColor.fromHex('#DDD8E1');
  static final _softPurple = PdfColor.fromHex('#F5EFF9');

  static Future<String> export(PaymentTransactionRecord transaction) async {
    final data = PaymentReceiptData.fromRecord(transaction);
    final logoData = await rootBundle.load(
      'assets/images/Logo_Choloto_509.png',
    );
    final regularFontData = await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/Roboto-Bold.ttf',
    );
    final bytes = await buildPdf(
      data,
      logoBytes: logoData.buffer.asUint8List(),
      regularFontBytes: regularFontData.buffer.asUint8List(),
      boldFontBytes: boldFontData.buffer.asUint8List(),
    );
    final safeReceiptNumber = data.receiptNumber
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toLowerCase();
    final name = 'recu_choloto_$safeReceiptNumber';

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );

    return '$name.pdf';
  }

  static Future<Uint8List> buildPdf(
    PaymentReceiptData data, {
    required Uint8List logoBytes,
    required Uint8List regularFontBytes,
    required Uint8List boldFontBytes,
  }) async {
    final document = pw.Document(
      title: 'Reçu ${data.receiptNumber}',
      author: 'CHOLOTO.COM',
      creator: 'CHOLOTO Dashboard',
      subject: "Reçu d'abonnement CHOLOTO",
    );
    final logo = pw.MemoryImage(logoBytes);
    final regularFont = pw.Font.ttf(ByteData.sublistView(regularFontBytes));
    final boldFont = pw.Font.ttf(ByteData.sublistView(boldFontBytes));
    final amountLabel = _amountLabel(data);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (_) => pw.Stack(
          children: [
            _pageDecorations(),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(42, 42, 42, 34),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _header(data, logo),
                  pw.SizedBox(height: 35),
                  _purchaseTable(data, amountLabel),
                  pw.SizedBox(height: 16),
                  _totalBanner(amountLabel),
                  pw.SizedBox(height: 28),
                  _detailRows(data),
                  pw.SizedBox(height: 22),
                  _confirmationMessage(data, amountLabel),
                  pw.Spacer(),
                  _receiptTerms(),
                  pw.SizedBox(height: 14),
                  _footer(data, logo),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _pageDecorations() {
    return pw.Stack(
      children: [
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: 30,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_deepPurple, _purple, _magenta],
              ),
            ),
          ),
        ),
        pw.Positioned(
          top: 12,
          left: -28,
          child: pw.Transform.rotate(
            angle: -0.14,
            child: pw.Container(width: 190, height: 24, color: _purple),
          ),
        ),
        pw.Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: 22,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_magenta, _purple, _deepPurple],
              ),
            ),
          ),
        ),
        pw.Positioned(
          bottom: 12,
          right: -35,
          child: pw.Transform.rotate(
            angle: -0.12,
            child: pw.Container(width: 210, height: 26, color: _purple),
          ),
        ),
      ],
    );
  }

  static pw.Widget _header(PaymentReceiptData data, pw.ImageProvider logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 158,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(logo, width: 68, height: 68),
              pw.SizedBox(height: 6),
              pw.Text(
                'choloto.com',
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              _smallText('contact@choloto.com', color: _ink, bold: true),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 18),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 9),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(9),
                    gradient: pw.LinearGradient(
                      colors: [_deepPurple, _magenta],
                    ),
                  ),
                  child: pw.Text(
                    'REÇU',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Code de la fiche',
                  style: pw.TextStyle(color: _muted, fontSize: 7.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  data.receiptNumber,
                  style: pw.TextStyle(
                    color: _purple,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(
          width: 158,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 58,
                height: 58,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: _blue,
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.white, width: 3),
                ),
                child: pw.Text(
                  'VIP',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 7),
              pw.Text(
                data.customerName.toUpperCase(),
                textAlign: pw.TextAlign.right,
                maxLines: 2,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              _smallText('Abonné CHOLOTO', color: _ink),
              if (data.personalCode.isNotEmpty)
                _smallText(
                  'Code personnel : ${data.personalCode}',
                  color: _purple,
                  bold: true,
                ),
              if (data.customerEmail.isNotEmpty)
                _smallText(data.customerEmail, color: _muted),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _purchaseTable(
    PaymentReceiptData data,
    String amountLabel,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(9),
              topRight: pw.Radius.circular(9),
            ),
            gradient: pw.LinearGradient(colors: [_purple, _magenta]),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 5, child: _tableTitle('Description')),
              pw.Expanded(child: _tableTitle('Quantité', centered: true)),
              pw.Expanded(flex: 2, child: _tableTitle('Prix', centered: true)),
              pw.Expanded(flex: 2, child: _tableTitle('Total', centered: true)),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 19),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _line, width: 0.8),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  _transactionDescription(data.transactionType),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(child: _cellText('1')),
              pw.Expanded(flex: 2, child: _cellText(amountLabel)),
              pw.Expanded(
                flex: 2,
                child: _cellText(amountLabel, color: _red, bold: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalBanner(String amountLabel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _purple,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Text(
            'Total : $amountLabel',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _detailRows(PaymentReceiptData data) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _softPurple,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: pw.Column(
        children: [
          _detailRow('Référence en ligne', data.receiptNumber),
          _detailRow(
              'Type d’opération', _transactionTypeLabel(data.transactionType)),
          _detailRow("Date d'entrée", _formatDate(data.issuedAt)),
          _detailRow(
            "Date d'expiration",
            data.expiresAt == null
                ? 'Non renseignée'
                : _formatDate(data.expiresAt!),
          ),
          _detailRow('Moyen de paiement', _paymentLabel(data.paymentMethod)),
          _detailRow(
            'Montant enregistré',
            _amountLabel(data),
            last: true,
            valueColor: data.hasAmount ? _red : _muted,
          ),
        ],
      ),
    );
  }

  static pw.Widget _confirmationMessage(
    PaymentReceiptData data,
    String amountLabel,
  ) {
    final operation = _transactionTypeLabel(data.transactionType).toLowerCase();
    final paymentSentence = data.hasAmount
        ? 'Le paiement de $amountLabel pour cette $operation a été enregistré.'
        : _transactionConfirmation(data.transactionType);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Félicitations, votre accès au groupe V.I.P CHOLOTO est maintenant enregistré.',
          style: pw.TextStyle(
            color: _ink,
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          paymentSentence,
          style: pw.TextStyle(
            color: _red,
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 9),
        pw.Text(
          'Merci pour votre confiance !',
          style: pw.TextStyle(
            color: _purple,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _receiptTerms() {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 9, 12, 8),
      decoration: pw.BoxDecoration(
        color: _softPurple,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONDITIONS IMPORTANTES',
            style: pw.TextStyle(
              color: _purple,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          _termLine(
            '1.',
            'Toute demande de remboursement doit être effectuée dans les '
                '24 heures suivant le paiement. Passé ce délai, aucun '
                'remboursement ne sera accordé.',
          ),
          _termLine(
            '2.',
            'Le client reconnaît que CHOLOTO fournit des prédictions et '
                'qu’aucun résultat ni gain n’est garanti.',
          ),
          _termLine(
            '3.',
            'Le client déclare être âgé de 18 ans ou plus.',
            last: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _termLine(
    String number,
    String text, {
    bool last = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: last ? 0 : 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 15,
            child: pw.Text(
              number,
              style: pw.TextStyle(
                color: _purple,
                fontSize: 7.2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 7.2,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(PaymentReceiptData data, pw.ImageProvider logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Text(
            _periodLabel(data.issuedAt, data.expiresAt),
            style: pw.TextStyle(
              color: _purple,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Column(
          children: [
            pw.Text(
              'Termes et conditions',
              style: pw.TextStyle(
                color: _purple,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Image(logo, width: 34, height: 34),
                pw.SizedBox(width: 5),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CHOLOTO',
                      style: pw.TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _smallText('Administration', color: _muted),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _detailRow(
    String label,
    String value, {
    bool last = false,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: last
          ? null
          : pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _line, width: 0.7),
              ),
            ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              maxLines: 2,
              style: pw.TextStyle(
                color: valueColor ?? _ink,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableTitle(String value, {bool centered = false}) {
    return pw.Text(
      value,
      textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9.5,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _cellText(
    String value, {
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Text(
      value,
      textAlign: pw.TextAlign.center,
      maxLines: 2,
      style: pw.TextStyle(
        color: color ?? _ink,
        fontSize: 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  static pw.Widget _smallText(
    String value, {
    required PdfColor color,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.right,
        maxLines: 2,
        style: pw.TextStyle(
          color: color,
          fontSize: 7.3,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _amountLabel(PaymentReceiptData data) {
    if (!data.hasAmount) return 'Non renseigné';
    final formatted = NumberFormat('#,##0.00', 'en_US').format(data.amount);
    return data.currency == 'GDS' ? '$formatted Gourdes' : '$formatted USD';
  }

  static String _transactionDescription(String type) {
    return switch (type) {
      'renewal' => 'Prolongation abonnement VIP CHOLOTO',
      'adjustment' => 'Modification abonnement VIP CHOLOTO',
      _ => 'Activation abonnement VIP CHOLOTO',
    };
  }

  static String _transactionTypeLabel(String type) {
    return switch (type) {
      'renewal' => 'Prolongation',
      'adjustment' => 'Modification',
      _ => 'Activation',
    };
  }

  static String _transactionConfirmation(String type) {
    return switch (type) {
      'renewal' =>
        'La prolongation de votre abonnement a été enregistrée avec succès.',
      'adjustment' =>
        'La modification de votre abonnement a été enregistrée avec succès.',
      _ => 'L’activation de votre abonnement a été enregistrée avec succès.',
    };
  }

  static String _paymentLabel(PaimentMethod? method) {
    return switch (method) {
      PaimentMethod.moncash => 'MonCash',
      PaimentMethod.cash => 'Espèces',
      PaimentMethod.stripe => 'Carte / Stripe',
      PaimentMethod.natcash => 'Natcash',
      PaimentMethod.zelle => 'Zelle',
      PaimentMethod.cashapp => 'CashApp',
      PaimentMethod.virement => 'Virement',
      null => 'Non renseigné',
    };
  }

  static String _formatDate(DateTime value) {
    const months = [
      'JAN',
      'FÉV',
      'MAR',
      'AVR',
      'MAI',
      'JUN',
      'JUL',
      'AOÛ',
      'SEP',
      'OCT',
      'NOV',
      'DÉC',
    ];
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')} '
        '${months[local.month - 1]} ${local.year}';
  }

  static String _periodLabel(DateTime start, DateTime? end) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    final localStart = start.toLocal();
    final localEnd = (end ?? start).toLocal();
    if (localStart.month == localEnd.month &&
        localStart.year == localEnd.year) {
      return '${months[localStart.month - 1]} ${localStart.year}';
    }
    if (localStart.year == localEnd.year) {
      return '${months[localStart.month - 1]} - '
          '${months[localEnd.month - 1]} ${localEnd.year}';
    }
    return '${months[localStart.month - 1]} ${localStart.year} - '
        '${months[localEnd.month - 1]} ${localEnd.year}';
  }
}
