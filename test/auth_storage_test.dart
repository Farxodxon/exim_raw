import 'package:exim_raw/services/auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveSession token va userni saqlaydi', () async {
    await AuthStorage.saveSession('token-123', {
      'email': 'test@example.com',
      'role': 'admin',
    });

    expect(await AuthStorage.getToken(), 'token-123');
    expect(await AuthStorage.getUser(), {
      'email': 'test@example.com',
      'role': 'admin',
    });
  });

  test("clear sessiyani o'chiradi", () async {
    await AuthStorage.saveSession('token-123', {
      'email': 'test@example.com',
    });

    await AuthStorage.clear();

    expect(await AuthStorage.getToken(), isNull);
    expect(await AuthStorage.getUser(), isNull);
  });
}
