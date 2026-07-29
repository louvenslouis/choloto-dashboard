// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class IdPredictionsStruct extends FFFirebaseStruct {
  IdPredictionsStruct({
    List<String>? boloto,
    List<String>? chif3,
    List<String>? chif4,
    List<String>? mariage,
    List<String>? favori,
    List<String>? soutni,
    List<String>? extra,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _boloto = boloto,
        _chif3 = chif3,
        _chif4 = chif4,
        _mariage = mariage,
        _favori = favori,
        _soutni = soutni,
        _extra = extra,
        super(firestoreUtilData);

  // "boloto" field.
  List<String>? _boloto;
  List<String> get boloto => _boloto ?? const [];
  set boloto(List<String>? val) => _boloto = val;

  void updateBoloto(Function(List<String>) updateFn) {
    updateFn(_boloto ??= []);
  }

  bool hasBoloto() => _boloto != null;

  // "chif3" field.
  List<String>? _chif3;
  List<String> get chif3 => _chif3 ?? const [];
  set chif3(List<String>? val) => _chif3 = val;

  void updateChif3(Function(List<String>) updateFn) {
    updateFn(_chif3 ??= []);
  }

  bool hasChif3() => _chif3 != null;

  // "chif4" field.
  List<String>? _chif4;
  List<String> get chif4 => _chif4 ?? const [];
  set chif4(List<String>? val) => _chif4 = val;

  void updateChif4(Function(List<String>) updateFn) {
    updateFn(_chif4 ??= []);
  }

  bool hasChif4() => _chif4 != null;

  // "mariage" field.
  List<String>? _mariage;
  List<String> get mariage => _mariage ?? const [];
  set mariage(List<String>? val) => _mariage = val;

  void updateMariage(Function(List<String>) updateFn) {
    updateFn(_mariage ??= []);
  }

  bool hasMariage() => _mariage != null;

  // "favori" field.
  List<String>? _favori;
  List<String> get favori => _favori ?? const [];
  set favori(List<String>? val) => _favori = val;

  void updateFavori(Function(List<String>) updateFn) {
    updateFn(_favori ??= []);
  }

  bool hasFavori() => _favori != null;

  // "soutni" field.
  List<String>? _soutni;
  List<String> get soutni => _soutni ?? const [];
  set soutni(List<String>? val) => _soutni = val;

  void updateSoutni(Function(List<String>) updateFn) {
    updateFn(_soutni ??= []);
  }

  bool hasSoutni() => _soutni != null;

  // "extra" field.
  List<String>? _extra;
  List<String> get extra => _extra ?? const [];
  set extra(List<String>? val) => _extra = val;

  void updateExtra(Function(List<String>) updateFn) {
    updateFn(_extra ??= []);
  }

  bool hasExtra() => _extra != null;

  static IdPredictionsStruct fromMap(Map<String, dynamic> data) =>
      IdPredictionsStruct(
        boloto: getDataList(data['boloto']),
        chif3: getDataList(data['chif3']),
        chif4: getDataList(data['chif4']),
        mariage: getDataList(data['mariage']),
        favori: getDataList(data['favori']),
        soutni: getDataList(data['soutni']),
        extra: getDataList(data['extra']),
      );

  static IdPredictionsStruct? maybeFromMap(dynamic data) => data is Map
      ? IdPredictionsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'boloto': _boloto,
        'chif3': _chif3,
        'chif4': _chif4,
        'mariage': _mariage,
        'favori': _favori,
        'soutni': _soutni,
        'extra': _extra,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'boloto': serializeParam(
          _boloto,
          ParamType.String,
          isList: true,
        ),
        'chif3': serializeParam(
          _chif3,
          ParamType.String,
          isList: true,
        ),
        'chif4': serializeParam(
          _chif4,
          ParamType.String,
          isList: true,
        ),
        'mariage': serializeParam(
          _mariage,
          ParamType.String,
          isList: true,
        ),
        'favori': serializeParam(
          _favori,
          ParamType.String,
          isList: true,
        ),
        'soutni': serializeParam(
          _soutni,
          ParamType.String,
          isList: true,
        ),
        'extra': serializeParam(
          _extra,
          ParamType.String,
          isList: true,
        ),
      }.withoutNulls;

  static IdPredictionsStruct fromSerializableMap(Map<String, dynamic> data) =>
      IdPredictionsStruct(
        boloto: deserializeParam<String>(
          data['boloto'],
          ParamType.String,
          true,
        ),
        chif3: deserializeParam<String>(
          data['chif3'],
          ParamType.String,
          true,
        ),
        chif4: deserializeParam<String>(
          data['chif4'],
          ParamType.String,
          true,
        ),
        mariage: deserializeParam<String>(
          data['mariage'],
          ParamType.String,
          true,
        ),
        favori: deserializeParam<String>(
          data['favori'],
          ParamType.String,
          true,
        ),
        soutni: deserializeParam<String>(
          data['soutni'],
          ParamType.String,
          true,
        ),
        extra: deserializeParam<String>(
          data['extra'],
          ParamType.String,
          true,
        ),
      );

  @override
  String toString() => 'IdPredictionsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is IdPredictionsStruct &&
        listEquality.equals(boloto, other.boloto) &&
        listEquality.equals(chif3, other.chif3) &&
        listEquality.equals(chif4, other.chif4) &&
        listEquality.equals(mariage, other.mariage) &&
        listEquality.equals(favori, other.favori) &&
        listEquality.equals(soutni, other.soutni) &&
        listEquality.equals(extra, other.extra);
  }

  @override
  int get hashCode => const ListEquality()
      .hash([boloto, chif3, chif4, mariage, favori, soutni, extra]);
}

IdPredictionsStruct createIdPredictionsStruct({
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    IdPredictionsStruct(
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

IdPredictionsStruct? updateIdPredictionsStruct(
  IdPredictionsStruct? idPredictions, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    idPredictions
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addIdPredictionsStructData(
  Map<String, dynamic> firestoreData,
  IdPredictionsStruct? idPredictions,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (idPredictions == null) {
    return;
  }
  if (idPredictions.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && idPredictions.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final idPredictionsData =
      getIdPredictionsFirestoreData(idPredictions, forFieldValue);
  final nestedData =
      idPredictionsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = idPredictions.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getIdPredictionsFirestoreData(
  IdPredictionsStruct? idPredictions, [
  bool forFieldValue = false,
]) {
  if (idPredictions == null) {
    return {};
  }
  final firestoreData = mapToFirestore(idPredictions.toMap());

  // Add any Firestore field values
  mapToFirestore(idPredictions.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getIdPredictionsListFirestoreData(
  List<IdPredictionsStruct>? idPredictionss,
) =>
    idPredictionss
        ?.map((e) => getIdPredictionsFirestoreData(e, true))
        .toList() ??
    [];
