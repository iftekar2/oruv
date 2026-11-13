import 'package:flutter_test/flutter_test.dart';
import 'package:oruv/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('MyApp renders initial welcome route without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(hasCompletedOnboarding: false));
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
