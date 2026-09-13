import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'support_audio.dart';

abstract class SupportVoiceRecorder {
  Future<void> start(void Function() onLimit);
  Future<SupportAudio> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class MicrophonePermissionDenied implements Exception {}

class DeviceSupportVoiceRecorder implements SupportVoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<RecordState>? _states;
  Object? _streamError;
  final _pcm = BytesBuilder(copy: false);
  bool _disposed = false;
  bool _limitReached = false;

  @override
  Future<void> start(void Function() onLimit) async {
    if (!await _recorder.hasPermission()) throw MicrophonePermissionDenied();
    if (_disposed) return;
    _pcm.clear();
    _limitReached = false;
    _streamError = null;
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: supportAudioSampleRate,
      numChannels: 1,
    ));
    if (_disposed) {
      await _recorder.cancel();
      return;
    }

    void failed(Object error) {
      _streamError = error;
      onLimit();
    }

    _states = _recorder.onStateChanged().listen((state) {
      if (state == RecordState.pause || state == RecordState.stop) onLimit();
    }, onError: failed);
    _subscription = stream.listen((chunk) {
      if (_limitReached) return;
      final remaining = maxSupportAudioBytes - 44 - _pcm.length;
      _pcm.add(chunk.length <= remaining ? chunk : chunk.sublist(0, remaining));
      if (_pcm.length >= maxSupportAudioBytes - 44) {
        _limitReached = true;
        onLimit();
      }
    }, onError: failed);
  }

  @override
  Future<SupportAudio> stop() async {
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    await _states?.cancel();
    _states = null;
    if (_streamError != null) {
      throw const FormatException('support-recording-interrupted');
    }
    return SupportAudio.fromPcm(_pcm.takeBytes());
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _states?.cancel();
    _states = null;
    _pcm.clear();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await cancel();
    await _recorder.dispose();
  }
}
