// Test-only stand-ins for the SDK interfaces; never used by production.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal transaction adapter. Security and concurrent commits are validated by
// the emulator suite; these checks execute the actual Dart review service.
class MemoryFirestore extends Fake implements FirebaseFirestore {
  Map<String, Map<String, dynamic>> rows = {};
  List<String> reads = [];
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      MemoryCollection(path);
  @override
  Future<T> runTransaction<T>(TransactionHandler<T> handler,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    final tx = MemoryTransaction(this);
    final result = await handler(tx);
    rows = tx.rows;
    return result;
  }
}

class MemoryCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  MemoryCollection(this.path);
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      MemoryReference('${this.path}/${path ?? 'random-id'}');
}

class MemoryReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  MemoryReference(this.path);
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      MemoryCollection('$path/$name');
}

class MemorySnapshot<T> extends Fake implements DocumentSnapshot<T> {
  MemorySnapshot(this.id, this.value);
  @override
  final String id;
  final T? value;
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
}

class MemoryTransaction extends Fake implements Transaction {
  MemoryTransaction(this.db)
      : rows = {
          for (final entry in db.rows.entries) entry.key: {...entry.value}
        };
  final MemoryFirestore db;
  final Map<String, Map<String, dynamic>> rows;
  bool written = false;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
      DocumentReference<T> ref) async {
    expect(written, isFalse, reason: 'Firestore requires reads before writes');
    db.reads.add(ref.path);
    return MemorySnapshot<T>(ref.id, rows[ref.path] as T?);
  }

  @override
  Transaction update(DocumentReference ref, Map<String, dynamic> data) {
    written = true;
    if (!rows.containsKey(ref.path)) throw StateError('missing');
    rows[ref.path]!.addAll(data);
    return this;
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    written = true;
    rows[ref.path] = {...data as Map<String, dynamic>};
    return this;
  }
}
