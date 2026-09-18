@TestOn('browser')
library;

import 'package:c_h_o_l_o_t_o_dashboard/support/support_image_picker_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart';

void main() {
  test('paperclip opens an attached browser photo input', () async {
    final selection = pickSupportImageBytes();

    final input = document.querySelector('input[type="file"]');
    expect(input, isA<HTMLInputElement>());
    expect((input! as HTMLInputElement).accept, 'image/*');

    input.dispatchEvent(Event('cancel'));
    expect(await selection, isNull);
    expect(document.querySelector('input[type="file"]'), isNull);
  });
}
