import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CroixRecord extends FirestoreRecord {
  CroixRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "created_by" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "numeros" field.
  List<String>? _numeros;
  List<String> get numeros => _numeros ?? const [];
  bool hasNumeros() => _numeros != null;

  void _initializeFields() {
    _date = snapshotData['date'] as DateTime?;
    _createdBy = snapshotData['created_by'] as String?;
    _numeros = getDataList(snapshotData['numeros']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('croix');

  static Stream<CroixRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CroixRecord.fromSnapshot(s));

  static Future<CroixRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CroixRecord.fromSnapshot(s));

  static CroixRecord fromSnapshot(DocumentSnapshot snapshot) => CroixRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CroixRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CroixRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CroixRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CroixRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCroixRecordData({
  DateTime? date,
  String? createdBy,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'created_by': createdBy,
    }.withoutNulls,
  );

  return firestoreData;
}

class CroixRecordDocumentEquality implements Equality<CroixRecord> {
  const CroixRecordDocumentEquality();

  @override
  bool equals(CroixRecord? e1, CroixRecord? e2) {
    const listEquality = ListEquality();
    return e1?.date == e2?.date &&
        e1?.createdBy == e2?.createdBy &&
        listEquality.equals(e1?.numeros, e2?.numeros);
  }

  @override
  int hash(CroixRecord? e) =>
      const ListEquality().hash([e?.date, e?.createdBy, e?.numeros]);

  @override
  bool isValidKey(Object? o) => o is CroixRecord;
}
