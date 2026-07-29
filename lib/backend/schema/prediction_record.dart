import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PredictionRecord extends FirestoreRecord {
  PredictionRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "periode" field.
  String? _periode;
  String get periode => _periode ?? '';
  bool hasPeriode() => _periode != null;

  // "pourcentage" field.
  int? _pourcentage;
  int get pourcentage => _pourcentage ?? 0;
  bool hasPourcentage() => _pourcentage != null;

  // "created_by" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "boloto" field.
  PredictionsStruct? _boloto;
  PredictionsStruct get boloto => _boloto ?? PredictionsStruct();
  bool hasBoloto() => _boloto != null;

  // "mariage" field.
  PredictionsStruct? _mariage;
  PredictionsStruct get mariage => _mariage ?? PredictionsStruct();
  bool hasMariage() => _mariage != null;

  // "chif3" field.
  PredictionsStruct? _chif3;
  PredictionsStruct get chif3 => _chif3 ?? PredictionsStruct();
  bool hasChif3() => _chif3 != null;

  // "chif4" field.
  PredictionsStruct? _chif4;
  PredictionsStruct get chif4 => _chif4 ?? PredictionsStruct();
  bool hasChif4() => _chif4 != null;

  // "soutni" field.
  PredictionsStruct? _soutni;
  PredictionsStruct get soutni => _soutni ?? PredictionsStruct();
  bool hasSoutni() => _soutni != null;

  // "extra" field.
  PredictionsStruct? _extra;
  PredictionsStruct get extra => _extra ?? PredictionsStruct();
  bool hasExtra() => _extra != null;

  // "favori" field.
  PredictionsStruct? _favori;
  PredictionsStruct get favori => _favori ?? PredictionsStruct();
  bool hasFavori() => _favori != null;

  void _initializeFields() {
    _date = snapshotData['date'] as DateTime?;
    _periode = snapshotData['periode'] as String?;
    _pourcentage = castToType<int>(snapshotData['pourcentage']);
    _createdBy = snapshotData['created_by'] as String?;
    _boloto = snapshotData['boloto'] is PredictionsStruct
        ? snapshotData['boloto']
        : PredictionsStruct.maybeFromMap(snapshotData['boloto']);
    _mariage = snapshotData['mariage'] is PredictionsStruct
        ? snapshotData['mariage']
        : PredictionsStruct.maybeFromMap(snapshotData['mariage']);
    _chif3 = snapshotData['chif3'] is PredictionsStruct
        ? snapshotData['chif3']
        : PredictionsStruct.maybeFromMap(snapshotData['chif3']);
    _chif4 = snapshotData['chif4'] is PredictionsStruct
        ? snapshotData['chif4']
        : PredictionsStruct.maybeFromMap(snapshotData['chif4']);
    _soutni = snapshotData['soutni'] is PredictionsStruct
        ? snapshotData['soutni']
        : PredictionsStruct.maybeFromMap(snapshotData['soutni']);
    _extra = snapshotData['extra'] is PredictionsStruct
        ? snapshotData['extra']
        : PredictionsStruct.maybeFromMap(snapshotData['extra']);
    _favori = snapshotData['favori'] is PredictionsStruct
        ? snapshotData['favori']
        : PredictionsStruct.maybeFromMap(snapshotData['favori']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('prediction');

  static Stream<PredictionRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PredictionRecord.fromSnapshot(s));

  static Future<PredictionRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PredictionRecord.fromSnapshot(s));

  static PredictionRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PredictionRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PredictionRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PredictionRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PredictionRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PredictionRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPredictionRecordData({
  DateTime? date,
  String? periode,
  int? pourcentage,
  String? createdBy,
  PredictionsStruct? boloto,
  PredictionsStruct? mariage,
  PredictionsStruct? chif3,
  PredictionsStruct? chif4,
  PredictionsStruct? soutni,
  PredictionsStruct? extra,
  PredictionsStruct? favori,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'periode': periode,
      'pourcentage': pourcentage,
      'created_by': createdBy,
      'boloto': PredictionsStruct().toMap(),
      'mariage': PredictionsStruct().toMap(),
      'chif3': PredictionsStruct().toMap(),
      'chif4': PredictionsStruct().toMap(),
      'soutni': PredictionsStruct().toMap(),
      'extra': PredictionsStruct().toMap(),
      'favori': PredictionsStruct().toMap(),
    }.withoutNulls,
  );

  // Handle nested data for "boloto" field.
  addPredictionsStructData(firestoreData, boloto, 'boloto');

  // Handle nested data for "mariage" field.
  addPredictionsStructData(firestoreData, mariage, 'mariage');

  // Handle nested data for "chif3" field.
  addPredictionsStructData(firestoreData, chif3, 'chif3');

  // Handle nested data for "chif4" field.
  addPredictionsStructData(firestoreData, chif4, 'chif4');

  // Handle nested data for "soutni" field.
  addPredictionsStructData(firestoreData, soutni, 'soutni');

  // Handle nested data for "extra" field.
  addPredictionsStructData(firestoreData, extra, 'extra');

  // Handle nested data for "favori" field.
  addPredictionsStructData(firestoreData, favori, 'favori');

  return firestoreData;
}

class PredictionRecordDocumentEquality implements Equality<PredictionRecord> {
  const PredictionRecordDocumentEquality();

  @override
  bool equals(PredictionRecord? e1, PredictionRecord? e2) {
    return e1?.date == e2?.date &&
        e1?.periode == e2?.periode &&
        e1?.pourcentage == e2?.pourcentage &&
        e1?.createdBy == e2?.createdBy &&
        e1?.boloto == e2?.boloto &&
        e1?.mariage == e2?.mariage &&
        e1?.chif3 == e2?.chif3 &&
        e1?.chif4 == e2?.chif4 &&
        e1?.soutni == e2?.soutni &&
        e1?.extra == e2?.extra &&
        e1?.favori == e2?.favori;
  }

  @override
  int hash(PredictionRecord? e) => const ListEquality().hash([
        e?.date,
        e?.periode,
        e?.pourcentage,
        e?.createdBy,
        e?.boloto,
        e?.mariage,
        e?.chif3,
        e?.chif4,
        e?.soutni,
        e?.extra,
        e?.favori
      ]);

  @override
  bool isValidKey(Object? o) => o is PredictionRecord;
}
