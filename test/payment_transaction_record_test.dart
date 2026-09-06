import 'package:c_h_o_l_o_t_o_dashboard/backend/schema/enums/enums.dart';
import 'package:c_h_o_l_o_t_o_dashboard/backend/schema/payment_transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment transaction data preserves the membership audit fields', () {
    final previousEndSub = DateTime.utc(2026, 8, 20);
    final newEndSub = DateTime.utc(2026, 9, 20);

    final data = createPaymentTransactionRecordData(
      userUid: 'user-123',
      userEmail: 'client@example.com',
      userDisplayName: 'Client Test',
      userCode: '7126-08 RP',
      receiptCode: 'CH-firestoreDoc123',
      transactionType: 'renewal',
      previousEndSub: previousEndSub,
      newEndSub: newEndSub,
      paymentMethod: PaimentMethod.moncash,
      amount: 1250.50,
      currency: 'GDS',
      memberTimeBefore: 2,
      memberTimeAfter: 3,
      createdBy: 'admin-456',
      createdByEmail: 'admin@example.com',
    );

    expect(data['user_uid'], 'user-123');
    expect(data['user_email'], 'client@example.com');
    expect(data['user_display_name'], 'Client Test');
    expect(data['user_code'], '7126-08 RP');
    expect(data['receipt_code'], 'CH-firestoreDoc123');
    expect(data['transaction_type'], 'renewal');
    expect(data['previous_end_sub'], previousEndSub);
    expect(data['new_end_sub'], newEndSub);
    expect(data['payment_method'], 'moncash');
    expect(data['amount'], 1250.50);
    expect(data['currency'], 'GDS');
    expect(data['member_time_before'], 2);
    expect(data['member_time_after'], 3);
    expect(data['created_by'], 'admin-456');
    expect(data['created_by_email'], 'admin@example.com');
    expect(data.containsKey('created_at'), isFalse);
  });

  test('payment transaction data omits optional user snapshot fields', () {
    final data = createPaymentTransactionRecordData(
      userUid: 'user-123',
      receiptCode: 'CH-firestoreDoc456',
      transactionType: 'subscription',
      newEndSub: DateTime.utc(2026, 9, 20),
      memberTimeBefore: 0,
      memberTimeAfter: 1,
      createdBy: 'admin-456',
    );

    expect(data.containsKey('user_email'), isFalse);
    expect(data.containsKey('user_display_name'), isFalse);
    expect(data.containsKey('user_code'), isFalse);
    expect(data.containsKey('previous_end_sub'), isFalse);
    expect(data.containsKey('payment_method'), isFalse);
    expect(data.containsKey('amount'), isFalse);
    expect(data.containsKey('currency'), isFalse);
  });

  test('plan adjustments preserve the membership counter', () {
    final data = createPaymentTransactionRecordData(
      userUid: 'user-123',
      receiptCode: 'CH-firestoreDoc789',
      transactionType: 'adjustment',
      newEndSub: DateTime.utc(2026, 10, 20),
      memberTimeBefore: 4,
      memberTimeAfter: 4,
      createdBy: 'admin-456',
    );

    expect(data['transaction_type'], 'adjustment');
    expect(data['member_time_before'], 4);
    expect(data['member_time_after'], 4);
  });

  test('cancellations preserve a complete audit trail', () {
    final previousEndSub = DateTime.utc(2026, 9, 20);
    final data = createPaymentTransactionRecordData(
      userUid: 'user-123',
      receiptCode: 'CH-firestoreCancel123',
      transactionType: 'cancellation',
      previousEndSub: previousEndSub,
      memberTimeBefore: 4,
      memberTimeAfter: 4,
      createdBy: 'admin-456',
      paymentCancelled: true,
      cancellationReason: 'Demande du client',
      refundedAmount: 750,
      refundCurrency: 'GDS',
    );

    expect(data['transaction_type'], 'cancellation');
    expect(data['previous_end_sub'], previousEndSub);
    expect(data.containsKey('new_end_sub'), isFalse);
    expect(data['member_time_before'], 4);
    expect(data['member_time_after'], 4);
    expect(data['payment_cancelled'], isTrue);
    expect(data['cancellation_reason'], 'Demande du client');
    expect(data['refunded_amount'], 750);
    expect(data['refund_currency'], 'GDS');

    final withoutRefund = createPaymentTransactionRecordData(
      transactionType: 'cancellation',
      cancellationReason: 'Annulation sans remboursement',
    );
    expect(withoutRefund.containsKey('refunded_amount'), isFalse);
    expect(withoutRefund.containsKey('refund_currency'), isFalse);
  });
}
