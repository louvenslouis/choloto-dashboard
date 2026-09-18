import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '/payments/payment_request.dart' show maxProofBytes;
import 'support_image_picker_native.dart'
    if (dart.library.js_interop) 'support_image_picker_web.dart';

/// Selects a still image, removes metadata and bounds its Firestore payload.
Future<Uint8List?> pickPreparedSupportImage({
  Future<Uint8List?> Function()? pickImage,
}) async {
  Uint8List? bytes;
  if (pickImage != null) {
    bytes = await pickImage();
  } else {
    bytes = await pickSupportImageBytes();
  }
  if (bytes == null) return null;
  return compute(prepareSupportImage, bytes);
}

Uint8List prepareSupportImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
    throw const FormatException('image-size');
  }
  final img.Decoder decoder;
  if (bytes.length > 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    decoder = img.JpegDecoder();
  } else if (bytes.length > 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    decoder = img.PngDecoder();
  } else if (bytes.length > 12 &&
      bytes[0] == 82 &&
      bytes[1] == 73 &&
      bytes[2] == 70 &&
      bytes[3] == 70 &&
      bytes[8] == 87 &&
      bytes[9] == 69 &&
      bytes[10] == 66 &&
      bytes[11] == 80) {
    decoder = img.WebPDecoder();
  } else {
    throw const FormatException('image-format');
  }
  final info = decoder.startDecode(bytes);
  if (info == null ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width * info.height > 24000000 ||
      info.numFrames != 1) {
    throw const FormatException('image-dimensions');
  }
  final decoded = decoder.decodeFrame(0);
  if (decoded == null) throw const FormatException('image-format');
  var picture = img.bakeOrientation(decoded);
  if (picture.width > 1600 || picture.height > 1600) {
    picture = img.copyResize(
      picture,
      width: picture.width >= picture.height ? 1600 : null,
      height: picture.height > picture.width ? 1600 : null,
    );
  }
  picture = img.Image.fromBytes(
    width: picture.width,
    height: picture.height,
    bytes: picture.getBytes(order: img.ChannelOrder.rgb).buffer,
    numChannels: 3,
  );
  // Camera photos can still be larger than the Firestore attachment limit
  // after the first resize. Keep reducing the bounded image until the encoded
  // payload fits instead of rejecting an otherwise valid photo.
  for (var pass = 0; pass < 8; pass++) {
    for (final quality in [88, 78, 65, 50, 40, 32]) {
      final encoded = img.encodeJpg(picture, quality: quality);
      if (encoded.length <= maxProofBytes) return encoded;
    }
    final nextWidth = math.max(320, (picture.width * .75).round());
    if (nextWidth >= picture.width) break;
    picture = img.copyResize(picture, width: nextWidth);
  }
  throw const FormatException('image-size');
}
