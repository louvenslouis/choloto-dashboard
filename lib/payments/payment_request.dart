import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

// Keep this contract in sync with the dashboard's lib/payments/ copy.
const maxProofBytes = 600000;
const paymentMethods = [
  'moncash',
  'natcash',
  'zelle',
  'cashapp',
  'virement',
  'cash',
  'stripe'
];
const paymentCurrencies = ['GDS', 'USD'];

DateTime? paymentDate(Object? value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
        ? value
        : null;

double? parsePaymentAmount(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0 || value > 999999999.99) {
    return null;
  }
  final rounded = double.parse(value.toStringAsFixed(2));
  return rounded > 0 ? rounded : null;
}

class PaymentRequest {
  const PaymentRequest(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get userUid => data['user_uid'] as String;
  String get status => data['status'] as String? ?? 'pending';
  String get method => data['payment_method'] as String? ?? '';
  String get currency => data['currency'] as String? ?? '';
  double? get amount => (data['amount'] as num?)?.toDouble();
  String get reference => data['payment_reference'] as String? ?? '';
  String get note => data['note'] as String? ?? '';
  String get reason => data['rejection_reason'] as String? ?? '';
  String get transactionId => data['transaction_id'] as String? ?? '';
  DateTime? get createdAt => paymentDate(data['created_at']);
  DateTime? get newEndSub => paymentDate(data['new_end_sub']);
}

class PaymentRequestRepository {
  PaymentRequestRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> get requests =>
      db.collection('payment_requests');
  String newId() => requests.doc().id;

  Stream<List<PaymentRequest>> watch({String? userUid, String? status}) {
    Query<Map<String, dynamic>> query = requests;
    if (userUid != null) query = query.where('user_uid', isEqualTo: userUid);
    if (status != null) query = query.where('status', isEqualTo: status);
    // Single-field filters preserve compatibility without composite indexes.
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PaymentRequest(doc.id, doc.data())).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970))));
  }

  Future<Uint8List> loadProof(String id) async {
    final snapshot =
        await requests.doc(id).collection('evidence').doc('image').get();
    final data = snapshot.data();
    if (data == null ||
        data['base64'] is! String ||
        (data['base64'] as String).length > 800000) {
      throw const FormatException('proof-unavailable');
    }
    final bytes = base64Decode(data['base64'] as String);
    if (bytes.isEmpty || bytes.length > maxProofBytes) {
      throw const FormatException('invalid-proof');
    }
    return bytes;
  }

  /// Online transaction: no silent offline queue, same id on an uncertain retry.
  /// The image and metadata are committed together; submission never grants VIP.
  Future<void> submit(
      {required String id,
      required String userUid,
      required Uint8List proof,
      required String note}) async {
    if (userUid.isEmpty ||
        proof.isEmpty ||
        proof.length > maxProofBytes ||
        note.trim().length > 500) {
      throw ArgumentError('invalid-payment-request');
    }
    final requestRef = requests.doc(id);
    await db.runTransaction((tx) async {
      final existing = await tx.get(requestRef);
      if (existing.exists) {
        if (existing.data()?['user_uid'] != userUid) {
          throw StateError('request-owner');
        }
        return; // An acknowledged or uncertain retry cannot create a second payment.
      }
      final profile = await tx.get(db.collection('user').doc(userUid));
      if (!profile.exists) throw StateError('profile-missing');
      tx.set(requestRef, {
        'user_uid': userUid,
        'plan': 'vip',
        'status': 'pending',
        'note': note.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      tx.set(requestRef.collection('evidence').doc('image'), {
        'base64': base64Encode(proof),
        'mime_type': 'image/jpeg',
        'byte_length': proof.length,
      });
    });
  }
}
