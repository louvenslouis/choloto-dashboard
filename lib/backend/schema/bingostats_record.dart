import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BingostatsRecord extends FirestoreRecord {
  BingostatsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  String? _user;
  String get user => _user ?? '';
  bool hasUser() => _user != null;

  // "gain" field.
  bool? _gain;
  bool get gain => _gain ?? false;
  bool hasGain() => _gain != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _user = snapshotData['user'] as String?;
    _gain = snapshotData['gain'] as bool?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('bingostats')
          : FirebaseFirestore.instance.collectionGroup('bingostats');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('bingostats').doc(id);

  static Stream<BingostatsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BingostatsRecord.fromSnapshot(s));

  static Future<BingostatsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BingostatsRecord.fromSnapshot(s));

  static BingostatsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BingostatsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BingostatsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BingostatsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BingostatsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BingostatsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBingostatsRecordData({
  String? user,
  bool? gain,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'gain': gain,
    }.withoutNulls,
  );

  return firestoreData;
}

class BingostatsRecordDocumentEquality implements Equality<BingostatsRecord> {
  const BingostatsRecordDocumentEquality();

  @override
  bool equals(BingostatsRecord? e1, BingostatsRecord? e2) {
    return e1?.user == e2?.user && e1?.gain == e2?.gain;
  }

  @override
  int hash(BingostatsRecord? e) =>
      const ListEquality().hash([e?.user, e?.gain]);

  @override
  bool isValidKey(Object? o) => o is BingostatsRecord;
}
