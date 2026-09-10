import 'dart:typed_data';
import 'package:c_h_o_l_o_t_o_dashboard/flutter_flow/internationalization.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio_player.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_conversation.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_inbox_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_firestore.dart';

class VoiceRepository extends SupportConversationRepository {
  VoiceRepository() : super(firestore: MemoryFirestore());
  @override
  Stream<List<SupportMessage>> watchMessages(String userUid) => Stream.value([
        SupportMessage('voice', {
          'sender_role': 'user',
          'text': 'Note vocale',
          'attachment_type': 'audio'
        })
      ]);
  @override
  Future<SupportAudio> loadMessageAudio(
          {required String conversationId, required String messageId}) async =>
      SupportAudio.fromPcm(Uint8List(16000));
}

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 1280.0]) {
      testWidgets('admin voice fits $brightness $width', (tester) async {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              FFLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            theme: ThemeData(brightness: brightness),
            home: SupportConversationPage(
                conversation:
                    const SupportConversation('member', {'user_uid': 'member'}),
                repository: VoiceRepository())));
        await tester.pumpAndSettle();
        expect(find.byType(SupportAudioPlayer), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
