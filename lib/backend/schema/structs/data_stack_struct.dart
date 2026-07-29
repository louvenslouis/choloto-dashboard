// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DataStackStruct extends FFFirebaseStruct {
  DataStackStruct({
    String? valeur,
    String? tirage,
    String? boul,
    String? periode,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _valeur = valeur,
        _tirage = tirage,
        _boul = boul,
        _periode = periode,
        super(firestoreUtilData);

  // "valeur" field.
  String? _valeur;
  String get valeur => _valeur ?? '';
  set valeur(String? val) => _valeur = val;

  bool hasValeur() => _valeur != null;

  // "tirage" field.
  String? _tirage;
  String get tirage => _tirage ?? '';
  set tirage(String? val) => _tirage = val;

  bool hasTirage() => _tirage != null;

  // "boul" field.
  String? _boul;
  String get boul => _boul ?? '';
  set boul(String? val) => _boul = val;

  bool hasBoul() => _boul != null;

  // "periode" field.
  String? _periode;
  String get periode => _periode ?? '';
  set periode(String? val) => _periode = val;

  bool hasPeriode() => _periode != null;

  static DataStackStruct fromMap(Map<String, dynamic> data) => DataStackStruct(
        valeur: data['valeur'] as String?,
        tirage: data['tirage'] as String?,
        boul: data['boul'] as String?,
        periode: data['periode'] as String?,
      );

  static DataStackStruct? maybeFromMap(dynamic data) => data is Map
      ? DataStackStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'valeur': _valeur,
        'tirage': _tirage,
        'boul': _boul,
        'periode': _periode,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'valeur': serializeParam(
          _valeur,
          ParamType.String,
        ),
        'tirage': serializeParam(
          _tirage,
          ParamType.String,
        ),
        'boul': serializeParam(
          _boul,
          ParamType.String,
        ),
        'periode': serializeParam(
          _periode,
          ParamType.String,
        ),
      }.withoutNulls;

  static DataStackStruct fromSerializableMap(Map<String, dynamic> data) =>
      DataStackStruct(
        valeur: deserializeParam(
          data['valeur'],
          ParamType.String,
          false,
        ),
        tirage: deserializeParam(
          data['tirage'],
          ParamType.String,
          false,
        ),
        boul: deserializeParam(
          data['boul'],
          ParamType.String,
          false,
        ),
        periode: deserializeParam(
          data['periode'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'DataStackStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DataStackStruct &&
        valeur == other.valeur &&
        tirage == other.tirage &&
        boul == other.boul &&
        periode == other.periode;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([valeur, tirage, boul, periode]);
}

DataStackStruct createDataStackStruct({
  String? valeur,
  String? tirage,
  String? boul,
  String? periode,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DataStackStruct(
      valeur: valeur,
      tirage: tirage,
      boul: boul,
      periode: periode,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DataStackStruct? updateDataStackStruct(
  DataStackStruct? dataStack, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    dataStack
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDataStackStructData(
  Map<String, dynamic> firestoreData,
  DataStackStruct? dataStack,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (dataStack == null) {
    return;
  }
  if (dataStack.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && dataStack.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final dataStackData = getDataStackFirestoreData(dataStack, forFieldValue);
  final nestedData = dataStackData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = dataStack.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDataStackFirestoreData(
  DataStackStruct? dataStack, [
  bool forFieldValue = false,
]) {
  if (dataStack == null) {
    return {};
  }
  final firestoreData = mapToFirestore(dataStack.toMap());

  // Add any Firestore field values
  mapToFirestore(dataStack.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDataStackListFirestoreData(
  List<DataStackStruct>? dataStacks,
) =>
    dataStacks?.map((e) => getDataStackFirestoreData(e, true)).toList() ?? [];
