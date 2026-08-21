import 'dart:io';

import 'package:c_h_o_l_o_t_o_dashboard/backend/schema/enums/enums.dart';
import 'package:c_h_o_l_o_t_o_dashboard/transactions/payment_receipt_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt number is stable and safe for display', () {
    expect(
      PaymentReceiptData.receiptNumberFor('abc-123_xyz987'),
      'CH-abc-123_xyz987',
    );
  });

  test('builds a one-page PDF from transaction data', () async {
    final logoBytes = await File(
      'assets/images/Logo_Choloto_509.png',
    ).readAsBytes();
    final regularFontBytes =
        await File('assets/fonts/Roboto-Regular.ttf').readAsBytes();
    final boldFontBytes =
        await File('assets/fonts/Roboto-Bold.ttf').readAsBytes();
    final bytes = await PaymentReceiptExporter.buildPdf(
      PaymentReceiptData(
        receiptNumber: 'CH-AbC123xYz789MnPq456R',
        transactionId: 'AbC123xYz789MnPq456R',
        customerName: 'Ricardo Client',
        customerEmail: 'ricardo@example.com',
        personalCode: '7126-08 RP',
        issuedAt: DateTime(2026, 8, 20),
        expiresAt: DateTime(2026, 9, 20),
        paymentMethod: PaimentMethod.moncash,
        amount: 1250,
        currency: 'GDS',
      ),
      logoBytes: logoBytes,
      regularFontBytes: regularFontBytes,
      boldFontBytes: boldFontBytes,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    final outputPath = Platform.environment['CHOLOTO_RECEIPT_SAMPLE_PATH'];
    if (outputPath != null && outputPath.isNotEmpty) {
      final output = File(outputPath);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes, flush: true);
    }
  });
}
