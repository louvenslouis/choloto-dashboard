import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

const _maxInputBytes = 12 * 1024 * 1024;

Future<Uint8List?> pickSupportImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    withData: true,
  );
  if (result == null) return null;

  final file = result.files.single;
  if (file.size <= 0 || file.size > _maxInputBytes || file.bytes == null) {
    throw const FormatException('image-size');
  }
  return file.bytes;
}
