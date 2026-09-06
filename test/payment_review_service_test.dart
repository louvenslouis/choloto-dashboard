import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_h_o_l_o_t_o_dashboard/payments/payment_review_service.dart';
import 'package:c_h_o_l_o_t_o_dashboard/payments/payment_request.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_firestore.dart';

void main() {
  late MemoryFirestore db;
  late PaymentReviewService service;
  setUp(() {
    db = MemoryFirestore();
    service = PaymentReviewService(firestore: db);
    db.rows['payment_requests/r1'] = {
      'user_uid': 'member',
      'status': 'pending',
    };
    db.rows['user/member'] = {
      'email': 'client@example.test'
    }; // historical uid/count absent
  });
  Future<String> approve({DateTime? end, double amount = 2000}) =>
      service.approve(
          requestId: 'r1',
          adminUid: 'admin',
          adminEmail: 'admin@example.test',
          amount: amount,
          currency: 'GDS',
          method: 'moncash',
          endSub: end ?? DateTime(2090, 10, 1));
  test(
      'approval rereads request then current profile and records a compatible receipt',
      () async {
    await approve();
    expect(db.reads, ['payment_requests/r1', 'user/member']);
    expect(db.rows['user/member']!['member_time'], 1);
    expect(db.rows['payment_requests/r1']!['status'], 'approved');
    final receipt = db.rows['payment_transactions/proof_r1']!;
    expect(receipt['amount'], 2000);
    expect(receipt['currency'], 'GDS');
    expect(receipt['receipt_code'], 'CH-proof_r1');
    expect(receipt['transaction_type'], 'subscription');
    expect(receipt['member_time_before'], 0);
    expect(receipt['member_time_after'], 1);
    expect(receipt['created_at'], isA<FieldValue>());
    await approve(); // lost acknowledgement / second administrator
    expect(db.rows['user/member']!['member_time'], 1);
    expect(
        db.rows.keys.where((p) => p.startsWith('payment_transactions/')).length,
        1);
  });
  test(
      'renewal reads the latest deadline and rejects a stale date without partial writes',
      () async {
    db.rows['user/member']!.addAll({
      'end_sub': Timestamp.fromDate(DateTime(2090, 9, 1)),
      'member_time': 4
    });
    await expectLater(approve(end: DateTime(2090, 8, 1)),
        throwsA(isA<PaymentReviewException>()));
    expect(db.rows['payment_requests/r1']!['status'], 'pending');
    expect(db.rows.containsKey('payment_transactions/proof_r1'), isFalse);
    await approve();
    expect(db.rows['user/member']!['member_time'], 5);
    expect(db.rows['payment_transactions/proof_r1']!['transaction_type'],
        'renewal');
  });
  test(
      'invalid admin amount leaves the photo request pending without a payment',
      () async {
    for (final amount in [double.nan, 0.0, -1.0, 1.001]) {
      await expectLater(
          approve(amount: amount), throwsA(isA<PaymentReviewException>()));
    }
    expect(db.rows['payment_requests/r1']!['status'], 'pending');
    expect(db.rows.containsKey('payment_transactions/proof_r1'), isFalse);
  });
  test('missing user blocks approval but allows reasoned rejection', () async {
    db.rows.remove('user/member');
    await expectLater(approve(), throwsA(isA<PaymentReviewException>()));
    await expectLater(
        service.reject(requestId: 'r1', adminUid: 'admin', reason: ' '),
        throwsA(isA<PaymentReviewException>()));
    await service.reject(
        requestId: 'r1', adminUid: 'admin', reason: ' Reçu illisible ');
    expect(
        db.rows['payment_requests/r1']!['rejection_reason'], 'Reçu illisible');
    expect(db.rows.containsKey('payment_transactions/proof_r1'), isFalse);
    await expectLater(approve(), throwsA(isA<PaymentReviewException>()));
  });
  test('suggested deadline preserves remaining days and clamps calendar month',
      () {
    expect(suggestedPaymentEnd(DateTime(2028, 1, 31), DateTime(2027)),
        DateTime(2028, 2, 29, 23, 59, 59));
    expect(suggestedPaymentEnd(DateTime(2020), DateTime(2026, 9, 5)),
        DateTime(2026, 10, 5, 23, 59, 59));
    expect(parsePaymentAmount('2000,50'), 2000.5);
  });
}
