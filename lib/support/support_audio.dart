import 'dart:convert';
import 'dart:typed_data';

// 30 seconds of mono PCM at 8 kHz fits comfortably in one Firestore document,
// including Base64 overhead. WAV is playable on Android, iOS and browsers.
const supportAudioSampleRate = 8000;
const maxSupportAudioSeconds = 30;
const maxSupportAudioBytes = 480044;

class SupportAudio {
  SupportAudio(this.bytes, this.durationMs) {
    if (!_validWav(bytes) ||
        durationMs <= 0 ||
        durationMs > maxSupportAudioSeconds * 1000 ||
        durationMs != ((bytes.length - 44) * 1000 ~/ 16000)) {
      throw const FormatException('invalid-support-audio');
    }
  }

  final Uint8List bytes;
  final int durationMs;

  Map<String, dynamic> toData() => {
        'base64': base64Encode(bytes),
        'mime_type': 'audio/wav',
        'byte_length': bytes.length,
        'duration_ms': durationMs,
      };

  factory SupportAudio.fromData(Map<String, dynamic>? data) {
    if (data == null ||
        data['base64'] is! String ||
        (data['base64'] as String).length > 640060 ||
        data['mime_type'] != 'audio/wav' ||
        data['duration_ms'] is! int) {
      throw const FormatException('support-audio-unavailable');
    }
    final bytes = base64Decode(data['base64'] as String);
    if (data['byte_length'] != bytes.length) {
      throw const FormatException('invalid-support-audio-size');
    }
    return SupportAudio(bytes, data['duration_ms'] as int);
  }

  factory SupportAudio.fromPcm(Uint8List pcm) {
    if (pcm.isEmpty ||
        pcm.length.isOdd ||
        pcm.length > maxSupportAudioBytes - 44) {
      throw const FormatException('invalid-support-pcm');
    }
    final wav = Uint8List(44 + pcm.length);
    final header = ByteData.sublistView(wav);
    wav.setRange(0, 4, ascii.encode('RIFF'));
    header.setUint32(4, wav.length - 8, Endian.little);
    wav.setRange(8, 16, ascii.encode('WAVEfmt '));
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, supportAudioSampleRate, Endian.little);
    header.setUint32(28, 16000, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    wav.setRange(36, 40, ascii.encode('data'));
    header.setUint32(40, pcm.length, Endian.little);
    wav.setRange(44, wav.length, pcm);
    return SupportAudio(wav, pcm.length * 1000 ~/ 16000);
  }

  static bool _validWav(Uint8List bytes) {
    if (bytes.length <= 44 ||
        bytes.length > maxSupportAudioBytes ||
        bytes.length.isOdd) {
      return false;
    }
    final h = ByteData.sublistView(bytes);
    return ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 16), allowInvalid: true) == 'WAVEfmt ' &&
        ascii.decode(bytes.sublist(36, 40), allowInvalid: true) == 'data' &&
        h.getUint32(4, Endian.little) == bytes.length - 8 &&
        h.getUint32(16, Endian.little) == 16 &&
        h.getUint16(20, Endian.little) == 1 &&
        h.getUint16(22, Endian.little) == 1 &&
        h.getUint32(24, Endian.little) == supportAudioSampleRate &&
        h.getUint32(28, Endian.little) == 16000 &&
        h.getUint16(32, Endian.little) == 2 &&
        h.getUint16(34, Endian.little) == 16 &&
        h.getUint32(40, Endian.little) == bytes.length - 44;
  }
}

String supportAudioTime(Duration duration) =>
    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
