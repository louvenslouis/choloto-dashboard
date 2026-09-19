import 'dart:async';
import 'package:c_h_o_l_o_t_o_dashboard/flutter_flow/internationalization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio.dart';
import 'package:c_h_o_l_o_t_o_dashboard/support/support_audio_player.dart';

class FakeAudioPlayer extends Fake implements AudioPlayer {
  final positions = StreamController<Duration>.broadcast();
  final completions = StreamController<void>.broadcast();
  int plays = 0, pauses = 0, disposals = 0;
  @override
  Stream<Duration> get onPositionChanged => positions.stream;
  @override
  Stream<void> get onPlayerComplete => completions.stream;
  @override
  Stream<AudioEvent> get eventStream => const Stream.empty();
  @override
  Future<void> setSource(Source source) async {
    expect(source, isA<BytesSource>());
    expect((source as BytesSource).mimeType, 'audio/wav');
    sources++;
  }

  int sources = 0;
  final seeks = <Duration>[];
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {
    expect(mode, ReleaseMode.stop);
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
  }

  @override
  Future<void> resume() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

void main() {
  testWidgets('play/pause, progress, completion and single active audio',
      (tester) async {
    final first = FakeAudioPlayer(), second = FakeAudioPlayer();
    final audio = SupportAudio.fromPcm(Uint8List(16000));
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: Scaffold(
            body: Column(children: [
          SupportAudioPlayer(
              load: () async => audio, playerFactory: () => first),
          SupportAudioPlayer(
              load: () async => audio, playerFactory: () => second),
        ]))));
    final buttons = find.byKey(const ValueKey('support-audio-play'));
    await tester.tap(buttons.at(0));
    await tester.pumpAndSettle();
    expect(first.plays, 1);
    first.positions.add(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator).first)
            .value,
        .5);
    await tester.tap(buttons.at(1));
    await tester.pumpAndSettle();
    expect(first.pauses, 1);
    expect(second.plays, 1);
    await tester.tap(buttons.at(1));
    await tester.pumpAndSettle();
    expect(second.pauses, 1);
    await tester.tap(buttons.at(1));
    await tester.pumpAndSettle();
    second.completions.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    // A late position event must not put a completed message back at its end.
    second.positions.add(const Duration(seconds: 1));
    await tester.pump();
    await tester.tap(buttons.at(1));
    await tester.pumpAndSettle();
    expect(second.plays, 3);
    expect(second.sources, 1);
    expect(second.seeks, [Duration.zero]);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(first.disposals, 1);
    expect(second.disposals, 1);
  });
}
