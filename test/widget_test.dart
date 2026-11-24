import 'package:exim_raw/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets("Login ekrani ko'rinadi", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Exim Raw Control'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Parol'), findsOneWidget);
    expect(find.text('Kirish'), findsOneWidget);
  });
}
