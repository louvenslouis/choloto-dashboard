import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ResultatsRecord extends FirestoreRecord {
  ResultatsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "bingo" field.
  List<String>? _bingo;
  List<String> get bingo => _bingo ?? const [];
  bool hasBingo() => _bingo != null;

  // "periode" field.
  String? _periode;
  String get periode => _periode ?? '';
  bool hasPeriode() => _periode != null;

  // "tirage" field.
  String? _tirage;
  String get tirage => _tirage ?? '';
  bool hasTirage() => _tirage != null;

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
    _bingo = getDataList(snapshotData['bingo']);
    _periode = snapshotData['periode'] as String?;
    _tirage = snapshotData['tirage'] as String?;
    _createdBy = snapshotData['created_by'] as String?;
    _numeros = getDataList(snapshotData['numeros']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('resultats');

  static Stream<ResultatsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ResultatsRecord.fromSnapshot(s));

  static Future<ResultatsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ResultatsRecord.fromSnapshot(s));

  static ResultatsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ResultatsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ResultatsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ResultatsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ResultatsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ResultatsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createResultatsRecordData({
  DateTime? date,
  String? periode,
  String? tirage,
  String? createdBy,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'periode': periode,
      'tirage': tirage,
      'created_by': createdBy,
    }.withoutNulls,
  );

  return firestoreData;
}

class ResultatsRecordDocumentEquality implements Equality<ResultatsRecord> {
  const ResultatsRecordDocumentEquality();

  @override
  bool equals(ResultatsRecord? e1, ResultatsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.date == e2?.date &&
        listEquality.equals(e1?.bingo, e2?.bingo) &&
        e1?.periode == e2?.periode &&
        e1?.tirage == e2?.tirage &&
        e1?.createdBy == e2?.createdBy &&
        listEquality.equals(e1?.numeros, e2?.numeros);
  }

  @override
  int hash(ResultatsRecord? e) => const ListEquality().hash(
      [e?.date, e?.bingo, e?.periode, e?.tirage, e?.createdBy, e?.numeros]);

  @override
  bool isValidKey(Object? o) => o is ResultatsRecord;
}
