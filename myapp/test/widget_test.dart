import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/login_screen.dart';

import 'mock.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App starts with LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Pump to process async initialization/redirects
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
