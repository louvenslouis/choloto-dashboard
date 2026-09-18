import 'dart:convert';
import 'dart:typed_data';

import 'package:c_h_o_l_o_t_o_dashboard/support/support_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prepares a picked PNG in the browser build', () async {
    final input = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ));

    final output = await pickPreparedSupportImage(
      pickImage: () async => input,
    );

    expect(output, isNotNull);
    expect(output!.length, lessThanOrEqualTo(600000));
    expect(output.take(3), orderedEquals([255, 216, 255]));
  });
}
