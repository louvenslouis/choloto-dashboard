import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_bot.dart';

class SupportBotRepository {
  SupportBotRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;
  DocumentReference<Map<String, dynamic>> get _document =>
      db.collection('support_bot').doc('config');
  Stream<SupportBotConfig> watch() => _document.snapshots().map((s) => s.exists
      ? SupportBotConfig.fromJson(s.data()!)
      : SupportBotConfig.initial);
  Future<SupportBotConfig> load() async {
    final snapshot =
        await _document.get(const GetOptions(source: Source.server));
    return snapshot.exists
        ? SupportBotConfig.fromJson(snapshot.data()!)
        : SupportBotConfig.initial;
  }

  Future<void> publish(SupportBotConfig config) async {
    config = config.synchronizedForPublication();
    config.validate();
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(_document);
      final revision = snapshot.data()?['revision'] as int? ?? 0;
      if (revision != config.revision) {
        throw StateError(
            'Le bot a été modifié ailleurs. Rouvrez l’éditeur pour charger la dernière version.');
      }
      transaction
          .set(_document, {...config.toJson(), 'revision': revision + 1});
    });
  }
}
