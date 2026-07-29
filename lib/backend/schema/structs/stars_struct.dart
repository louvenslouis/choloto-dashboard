// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StarsStruct extends FFFirebaseStruct {
  StarsStruct({
    String? uid,
    String? name,
    int? id,
    String? number,
    DateTime? time,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _uid = uid,
        _name = name,
        _id = id,
        _number = number,
        _time = time,
        super(firestoreUtilData);

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  set uid(String? val) => _uid = val;

  bool hasUid() => _uid != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  set id(int? val) => _id = val;

  void incrementId(int amount) => id = id + amount;

  bool hasId() => _id != null;

  // "number" field.
  String? _number;
  String get number => _number ?? '';
  set number(String? val) => _number = val;

  bool hasNumber() => _number != null;

  // "time" field.
  DateTime? _time;
  DateTime? get time => _time;
  set time(DateTime? val) => _time = val;

  bool hasTime() => _time != null;

  static StarsStruct fromMap(Map<String, dynamic> data) => StarsStruct(
        uid: data['uid'] as String?,
        name: data['name'] as String?,
        id: castToType<int>(data['id']),
        number: data['number'] as String?,
        time: data['time'] as DateTime?,
      );

  static StarsStruct? maybeFromMap(dynamic data) =>
      data is Map ? StarsStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'uid': _uid,
        'name': _name,
        'id': _id,
        'number': _number,
        'time': _time,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'uid': serializeParam(
          _uid,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'id': serializeParam(
          _id,
          ParamType.int,
        ),
        'number': serializeParam(
          _number,
          ParamType.String,
        ),
        'time': serializeParam(
          _time,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static StarsStruct fromSerializableMap(Map<String, dynamic> data) =>
      StarsStruct(
        uid: deserializeParam(
          data['uid'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        id: deserializeParam(
          data['id'],
          ParamType.int,
          false,
        ),
        number: deserializeParam(
          data['number'],
          ParamType.String,
          false,
        ),
        time: deserializeParam(
          data['time'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'StarsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is StarsStruct &&
        uid == other.uid &&
        name == other.name &&
        id == other.id &&
        number == other.number &&
        time == other.time;
  }

  @override
  int get hashCode => const ListEquality().hash([uid, name, id, number, time]);
}

StarsStruct createStarsStruct({
  String? uid,
  String? name,
  int? id,
  String? number,
  DateTime? time,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    StarsStruct(
      uid: uid,
      name: name,
      id: id,
      number: number,
      time: time,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

StarsStruct? updateStarsStruct(
  StarsStruct? stars, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    stars
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addStarsStructData(
  Map<String, dynamic> firestoreData,
  StarsStruct? stars,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (stars == null) {
    return;
  }
  if (stars.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && stars.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final starsData = getStarsFirestoreData(stars, forFieldValue);
  final nestedData = starsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = stars.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getStarsFirestoreData(
  StarsStruct? stars, [
  bool forFieldValue = false,
]) {
  if (stars == null) {
    return {};
  }
  final firestoreData = mapToFirestore(stars.toMap());

  // Add any Firestore field values
  mapToFirestore(stars.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getStarsListFirestoreData(
  List<StarsStruct>? starss,
) =>
    starss?.map((e) => getStarsFirestoreData(e, true)).toList() ?? [];
