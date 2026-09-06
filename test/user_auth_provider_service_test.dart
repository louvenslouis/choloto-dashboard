import 'package:c_h_o_l_o_t_o_dashboard/users/user_auth_provider_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and normalizes authentication providers', () {
    final result = parseUserAuthProvidersPayload({
      'data': {
        'providers': {
          'user-1': ['google.com', 'password', 'google.com'],
          'user-2': <String>[],
        },
      },
    });

    expect(result['user-1'], ['google.com', 'password']);
    expect(result['user-2'], isEmpty);
  });

  test('rejects malformed authentication provider responses', () {
    expect(
      () => parseUserAuthProvidersPayload({'data': <String, dynamic>{}}),
      throwsA(isA<UserAuthProviderException>()),
    );
  });
}
