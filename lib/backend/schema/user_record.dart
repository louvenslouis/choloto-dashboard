import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "end_sub" field.
  DateTime? _endSub;
  DateTime? get endSub => _endSub;
  bool hasEndSub() => _endSub != null;

  // "method" field.
  PaimentMethod? _method;
  PaimentMethod? get method => _method;
  bool hasMethod() => _method != null;

  // "code_personnel" field.
  String? _codePersonnel;
  String get codePersonnel => _codePersonnel ?? '';
  bool hasCodePersonnel() => _codePersonnel != null;

  // "member_time" field.
  int? _memberTime;
  int get memberTime => _memberTime ?? 0;
  bool hasMemberTime() => _memberTime != null;

  // "birthday" field.
  DateTime? _birthday;
  DateTime? get birthday => _birthday;
  bool hasBirthday() => _birthday != null;

  // "profile" field.
  String? _profile;
  String get profile => _profile ?? '';
  bool hasProfile() => _profile != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _endSub = snapshotData['end_sub'] as DateTime?;
    _method = snapshotData['method'] is PaimentMethod
        ? snapshotData['method']
        : deserializeEnum<PaimentMethod>(snapshotData['method']);
    _codePersonnel = snapshotData['code_personnel'] as String?;
    _memberTime = castToType<int>(snapshotData['member_time']);
    _birthday = snapshotData['birthday'] as DateTime?;
    _profile = snapshotData['profile'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) => UserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  DateTime? endSub,
  PaimentMethod? method,
  String? codePersonnel,
  int? memberTime,
  DateTime? birthday,
  String? profile,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'end_sub': endSub,
      'method': method,
      'code_personnel': codePersonnel,
      'member_time': memberTime,
      'birthday': birthday,
      'profile': profile,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserRecordDocumentEquality implements Equality<UserRecord> {
  const UserRecordDocumentEquality();

  @override
  bool equals(UserRecord? e1, UserRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.endSub == e2?.endSub &&
        e1?.method == e2?.method &&
        e1?.codePersonnel == e2?.codePersonnel &&
        e1?.memberTime == e2?.memberTime &&
        e1?.birthday == e2?.birthday &&
        e1?.profile == e2?.profile;
  }

  @override
  int hash(UserRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber,
        e?.endSub,
        e?.method,
        e?.codePersonnel,
        e?.memberTime,
        e?.birthday,
        e?.profile
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}
