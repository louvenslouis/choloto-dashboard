import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_request.dart';

class PaymentReviewException implements Exception {
  const PaymentReviewException(this.key);
  final String key;
}

DateTime suggestedPaymentEnd(DateTime? currentEnd, DateTime now) {
  final base = currentEnd != null && currentEnd.isAfter(now) ? currentEnd : now;
  final lastDay = DateTime(base.year, base.month + 2, 0).day;
  return DateTime(
      base.year, base.month + 1, base.day.clamp(1, lastDay), 23, 59, 59);
}

class PaymentReviewService {
  PaymentReviewService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;

  Future<String> approve(
      {required String requestId,
      required String adminUid,
      required String adminEmail,
      required double amount,
      required String currency,
      required String method,
      required DateTime endSub}) async {
    if (parsePaymentAmount(amount.toString()) != amount) {
      throw const PaymentReviewException('amountError');
    }
    if (!paymentCurrencies.contains(currency) ||
        !paymentMethods.contains(method)) {
      throw const PaymentReviewException('required');
    }
    final requestRef = db.collection('payment_requests').doc(requestId);
    final transactionRef =
        db.collection('payment_transactions').doc('proof_$requestId');
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(requestRef);
      if (!snapshot.exists) throw const PaymentReviewException('stale');
      final request = PaymentRequest(snapshot.id, snapshot.data()!);
      if (request.status == 'approved' &&
          request.transactionId == transactionRef.id) {
        return;
      }
      if (request.status != 'pending') {
        throw const PaymentReviewException('stale');
      }
      final userRef = db.collection('user').doc(request.userUid);
      final user = await tx.get(userRef);
      if (!user.exists) throw const PaymentReviewException('missingProfile');
      final data = user.data()!;
      final previousEnd = paymentDate(data['end_sub']);
      final now = DateTime.now();
      if (!endSub.isAfter(now) ||
          (previousEnd != null && !endSub.isAfter(previousEnd))) {
        throw const PaymentReviewException('invalidEnd');
      }
      final count = (data['member_time'] as num?)?.toInt() ?? 0;
      tx.update(userRef, {
        'end_sub': Timestamp.fromDate(endSub),
        'method': method,
        'member_time': count + 1,
        'updated_time': FieldValue.serverTimestamp()
      });
      tx.set(transactionRef, {
        'user_ref': userRef,
        'user_uid': request.userUid,
        if (data['email'] is String) 'user_email': data['email'],
        if (data['display_name'] is String)
          'user_display_name': data['display_name'],
        if (data['code_personnel'] is String)
          'user_code': data['code_personnel'],
        'receipt_code': 'CH-${transactionRef.id}',
        'transaction_type': previousEnd != null ? 'renewal' : 'subscription',
        if (previousEnd != null)
          'previous_end_sub': Timestamp.fromDate(previousEnd),
        'new_end_sub': Timestamp.fromDate(endSub),
        'payment_method': method,
        'amount': amount,
        'currency': currency,
        'member_time_before': count,
        'member_time_after': count + 1,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': adminUid,
        if (adminEmail.isNotEmpty) 'created_by_email': adminEmail,
      });
      tx.update(requestRef, {
        'status': 'approved',
        'amount': amount,
        'currency': currency,
        'payment_method': method,
        'transaction_id': transactionRef.id,
        'new_end_sub': Timestamp.fromDate(endSub),
        'reviewed_by': adminUid,
        'reviewed_at': FieldValue.serverTimestamp()
      });
    });
    return transactionRef.id;
  }

  Future<void> reject(
      {required String requestId,
      required String adminUid,
      required String reason}) async {
    if (reason.trim().isEmpty || reason.trim().length > 500) {
      throw const PaymentReviewException('required');
    }
    final ref = db.collection('payment_requests').doc(requestId);
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists || snapshot.data()?['status'] != 'pending') {
        throw const PaymentReviewException('stale');
      }
      tx.update(ref, {
        'status': 'rejected',
        'rejection_reason': reason.trim(),
        'reviewed_by': adminUid,
        'reviewed_at': FieldValue.serverTimestamp()
      });
    });
  }
}
