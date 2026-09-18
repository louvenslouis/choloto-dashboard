import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

const _maxInputBytes = 12 * 1024 * 1024;

/// Opens a browser image input and keeps it attached until selection or cancel.
Future<Uint8List?> pickSupportImageBytes() {
  final result = Completer<Uint8List?>();
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..style.display = 'none';
  document.body?.append(input);

  var completed = false;
  late final JSFunction cancelListener;
  late final JSFunction focusListener;

  void finish(Uint8List? bytes, [Object? error]) {
    if (completed) return;
    completed = true;
    input.removeEventListener('cancel', cancelListener);
    window.removeEventListener('focus', focusListener);
    input.remove();
    if (error == null) {
      result.complete(bytes);
    } else {
      result.completeError(error);
    }
  }

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      finish(null);
      return;
    }
    if (file.size <= 0 || file.size > _maxInputBytes) {
      finish(null, const FormatException('image-size'));
      return;
    }

    final reader = FileReader();
    reader.onLoadEnd.first.then((_) {
      final buffer = (reader.result as JSArrayBuffer?)?.toDart;
      final bytes = buffer?.asUint8List();
      if (bytes == null || bytes.isEmpty || bytes.length > _maxInputBytes) {
        finish(null, const FormatException('image-unavailable'));
      } else {
        finish(bytes);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  cancelListener = ((Event _) => finish(null)).toJS;
  focusListener = ((Event _) {
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!completed && (input.files == null || input.files!.length == 0)) {
        finish(null);
      }
    });
  }).toJS;
  input.addEventListener('cancel', cancelListener);
  window.addEventListener('focus', focusListener);

  input.click();
  return result.future;
}
