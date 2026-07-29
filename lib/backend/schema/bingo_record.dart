import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BingoRecord extends FirestoreRecord {
  BingoRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "dataStack" field.
  List<DataStackStruct>? _dataStack;
  List<DataStackStruct> get dataStack => _dataStack ?? const [];
  bool hasDataStack() => _dataStack != null;

  // "expiration" field.
  DateTime? _expiration;
  DateTime? get expiration => _expiration;
  bool hasExpiration() => _expiration != null;

  void _initializeFields() {
    _date = snapshotData['date'] as DateTime?;
    _dataStack = getStructList(
      snapshotData['dataStack'],
      DataStackStruct.fromMap,
    );
    _expiration = snapshotData['expiration'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('bingo');

  static Stream<BingoRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BingoRecord.fromSnapshot(s));

  static Future<BingoRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BingoRecord.fromSnapshot(s));

  static BingoRecord fromSnapshot(DocumentSnapshot snapshot) => BingoRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BingoRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BingoRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BingoRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BingoRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBingoRecordData({
  DateTime? date,
  DateTime? expiration,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'expiration': expiration,
    }.withoutNulls,
  );

  return firestoreData;
}

class BingoRecordDocumentEquality implements Equality<BingoRecord> {
  const BingoRecordDocumentEquality();

  @override
  bool equals(BingoRecord? e1, BingoRecord? e2) {
    const listEquality = ListEquality();
    return e1?.date == e2?.date &&
        listEquality.equals(e1?.dataStack, e2?.dataStack) &&
        e1?.expiration == e2?.expiration;
  }

  @override
  int hash(BingoRecord? e) =>
      const ListEquality().hash([e?.date, e?.dataStack, e?.expiration]);

  @override
  bool isValidKey(Object? o) => o is BingoRecord;
}
