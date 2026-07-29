// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PredictionsStruct extends FFFirebaseStruct {
  PredictionsStruct({
    String? name,
    int? stars,
    List<String>? boul,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _name = name,
        _stars = stars,
        _boul = boul,
        super(firestoreUtilData);

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "stars" field.
  int? _stars;
  int get stars => _stars ?? 0;
  set stars(int? val) => _stars = val;

  void incrementStars(int amount) => stars = stars + amount;

  bool hasStars() => _stars != null;

  // "boul" field.
  List<String>? _boul;
  List<String> get boul => _boul ?? const [];
  set boul(List<String>? val) => _boul = val;

  void updateBoul(Function(List<String>) updateFn) {
    updateFn(_boul ??= []);
  }

  bool hasBoul() => _boul != null;

  static PredictionsStruct fromMap(Map<String, dynamic> data) =>
      PredictionsStruct(
        name: data['name'] as String?,
        stars: castToType<int>(data['stars']),
        boul: getDataList(data['boul']),
      );

  static PredictionsStruct? maybeFromMap(dynamic data) => data is Map
      ? PredictionsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'name': _name,
        'stars': _stars,
        'boul': _boul,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'stars': serializeParam(
          _stars,
          ParamType.int,
        ),
        'boul': serializeParam(
          _boul,
          ParamType.String,
          isList: true,
        ),
      }.withoutNulls;

  static PredictionsStruct fromSerializableMap(Map<String, dynamic> data) =>
      PredictionsStruct(
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        stars: deserializeParam(
          data['stars'],
          ParamType.int,
          false,
        ),
        boul: deserializeParam<String>(
          data['boul'],
          ParamType.String,
          true,
        ),
      );

  @override
  String toString() => 'PredictionsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is PredictionsStruct &&
        name == other.name &&
        stars == other.stars &&
        listEquality.equals(boul, other.boul);
  }

  @override
  int get hashCode => const ListEquality().hash([name, stars, boul]);
}

PredictionsStruct createPredictionsStruct({
  String? name,
  int? stars,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    PredictionsStruct(
      name: name,
      stars: stars,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

PredictionsStruct? updatePredictionsStruct(
  PredictionsStruct? predictions, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    predictions
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addPredictionsStructData(
  Map<String, dynamic> firestoreData,
  PredictionsStruct? predictions,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (predictions == null) {
    return;
  }
  if (predictions.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && predictions.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final predictionsData =
      getPredictionsFirestoreData(predictions, forFieldValue);
  final nestedData =
      predictionsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = predictions.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getPredictionsFirestoreData(
  PredictionsStruct? predictions, [
  bool forFieldValue = false,
]) {
  if (predictions == null) {
    return {};
  }
  final firestoreData = mapToFirestore(predictions.toMap());

  // Add any Firestore field values
  mapToFirestore(predictions.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getPredictionsListFirestoreData(
  List<PredictionsStruct>? predictionss,
) =>
    predictionss?.map((e) => getPredictionsFirestoreData(e, true)).toList() ??
    [];
