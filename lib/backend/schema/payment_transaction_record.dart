import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

import 'index.dart';

class PaymentTransactionRecord extends FirestoreRecord {
  PaymentTransactionRecord._(
    super.reference,
    super.snapshotData,
  ) {
    _initializeFields();
  }

  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  String? _userUid;
  String get userUid => _userUid ?? '';
  bool hasUserUid() => _userUid != null;

  String? _userEmail;
  String get userEmail => _userEmail ?? '';
  bool hasUserEmail() => _userEmail != null;

  String? _userDisplayName;
  String get userDisplayName => _userDisplayName ?? '';
  bool hasUserDisplayName() => _userDisplayName != null;

  String? _userCode;
  String get userCode => _userCode ?? '';
  bool hasUserCode() => _userCode != null;

  String? _receiptCode;
  String get receiptCode => _receiptCode ?? '';
  bool hasReceiptCode() => _receiptCode != null;

  DateTime? _previousEndSub;
  DateTime? get previousEndSub => _previousEndSub;
  bool hasPreviousEndSub() => _previousEndSub != null;

  DateTime? _newEndSub;
  DateTime? get newEndSub => _newEndSub;
  bool hasNewEndSub() => _newEndSub != null;

  PaimentMethod? _paymentMethod;
  PaimentMethod? get paymentMethod => _paymentMethod;
  bool hasPaymentMethod() => _paymentMethod != null;

  double? _amount;
  double get amount => _amount ?? 0.0;
  bool hasAmount() => _amount != null;

  String? _currency;
  String get currency => _currency ?? '';
  bool hasCurrency() => _currency != null;

  int? _memberTimeBefore;
  int get memberTimeBefore => _memberTimeBefore ?? 0;
  bool hasMemberTimeBefore() => _memberTimeBefore != null;

  int? _memberTimeAfter;
  int get memberTimeAfter => _memberTimeAfter ?? 0;
  bool hasMemberTimeAfter() => _memberTimeAfter != null;

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  String? _createdByEmail;
  String get createdByEmail => _createdByEmail ?? '';
  bool hasCreatedByEmail() => _createdByEmail != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _userUid = snapshotData['user_uid'] as String?;
    _userEmail = snapshotData['user_email'] as String?;
    _userDisplayName = snapshotData['user_display_name'] as String?;
    _userCode = snapshotData['user_code'] as String?;
    _receiptCode = snapshotData['receipt_code'] as String?;
    _previousEndSub = snapshotData['previous_end_sub'] as DateTime?;
    _newEndSub = snapshotData['new_end_sub'] as DateTime?;
    _paymentMethod = snapshotData['payment_method'] is PaimentMethod
        ? snapshotData['payment_method']
        : deserializeEnum<PaimentMethod>(snapshotData['payment_method']);
    _amount = castToType<double>(snapshotData['amount']);
    _currency = snapshotData['currency'] as String?;
    _memberTimeBefore = castToType<int>(snapshotData['member_time_before']);
    _memberTimeAfter = castToType<int>(snapshotData['member_time_after']);
    _createdAt = snapshotData['created_at'] as DateTime?;
    _createdBy = snapshotData['created_by'] as String?;
    _createdByEmail = snapshotData['created_by_email'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('payment_transactions');

  static Stream<PaymentTransactionRecord> getDocument(
    DocumentReference ref,
  ) =>
      ref.snapshots().map(PaymentTransactionRecord.fromSnapshot);

  static Future<PaymentTransactionRecord> getDocumentOnce(
    DocumentReference ref,
  ) =>
      ref.get().then(PaymentTransactionRecord.fromSnapshot);

  static PaymentTransactionRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PaymentTransactionRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PaymentTransactionRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PaymentTransactionRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PaymentTransactionRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PaymentTransactionRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPaymentTransactionRecordData({
  DocumentReference? userRef,
  String? userUid,
  String? userEmail,
  String? userDisplayName,
  String? userCode,
  String? receiptCode,
  DateTime? previousEndSub,
  DateTime? newEndSub,
  PaimentMethod? paymentMethod,
  double? amount,
  String? currency,
  int? memberTimeBefore,
  int? memberTimeAfter,
  DateTime? createdAt,
  String? createdBy,
  String? createdByEmail,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'user_uid': userUid,
      'user_email': userEmail,
      'user_display_name': userDisplayName,
      'user_code': userCode,
      'receipt_code': receiptCode,
      'previous_end_sub': previousEndSub,
      'new_end_sub': newEndSub,
      'payment_method': paymentMethod,
      'amount': amount,
      'currency': currency,
      'member_time_before': memberTimeBefore,
      'member_time_after': memberTimeAfter,
      'created_at': createdAt,
      'created_by': createdBy,
      'created_by_email': createdByEmail,
    }.withoutNulls,
  );
}

class PaymentTransactionRecordDocumentEquality
    implements Equality<PaymentTransactionRecord> {
  const PaymentTransactionRecordDocumentEquality();

  @override
  bool equals(PaymentTransactionRecord? e1, PaymentTransactionRecord? e2) =>
      e1?.userRef == e2?.userRef &&
      e1?.userUid == e2?.userUid &&
      e1?.userEmail == e2?.userEmail &&
      e1?.userDisplayName == e2?.userDisplayName &&
      e1?.userCode == e2?.userCode &&
      e1?.receiptCode == e2?.receiptCode &&
      e1?.previousEndSub == e2?.previousEndSub &&
      e1?.newEndSub == e2?.newEndSub &&
      e1?.paymentMethod == e2?.paymentMethod &&
      e1?.amount == e2?.amount &&
      e1?.currency == e2?.currency &&
      e1?.memberTimeBefore == e2?.memberTimeBefore &&
      e1?.memberTimeAfter == e2?.memberTimeAfter &&
      e1?.createdAt == e2?.createdAt &&
      e1?.createdBy == e2?.createdBy &&
      e1?.createdByEmail == e2?.createdByEmail;

  @override
  int hash(PaymentTransactionRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.userUid,
        e?.userEmail,
        e?.userDisplayName,
        e?.userCode,
        e?.receiptCode,
        e?.previousEndSub,
        e?.newEndSub,
        e?.paymentMethod,
        e?.amount,
        e?.currency,
        e?.memberTimeBefore,
        e?.memberTimeAfter,
        e?.createdAt,
        e?.createdBy,
        e?.createdByEmail,
      ]);

  @override
  bool isValidKey(Object? o) => o is PaymentTransactionRecord;
}
