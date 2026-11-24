import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedding_connects/auth/auth_service.dart';
import 'package:wedding_connects/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows login screen when logged out', (tester) async {
    await authService.init();
    await tester.pumpWidget(const WeddingConnectsApp());
    expect(find.text('Welcome back'), findsOneWidget);
  });

  test('sign up requires OTP, then login works with password', () async {
    final s = AuthService();
    await s.init();
    expect(
      await s.signUp(
        name: 'Asha',
        type: ContactType.email,
        contact: 'asha@example.com',
        password: 'secret123',
      ),
      isNotNull,
    );
    await s.sendOtp(ContactType.email, 'asha@example.com');
    expect(await s.verifyOtp(ContactType.email, 'asha@example.com', '000000'),
        isFalse);
    expect(await s.verifyOtp(ContactType.email, 'asha@example.com', '123456'),
        isTrue);
    expect(
      await s.signUp(
        name: 'Asha',
        type: ContactType.email,
        contact: 'asha@example.com',
        password: 'secret123',
      ),
      isNull,
    );
    await s.logout();
    expect(await s.login(ContactType.email, 'ASHA@example.com', 'wrong'),
        isNotNull);
    expect(await s.login(ContactType.email, 'ASHA@example.com', 'secret123'),
        isNull);
  });
}
