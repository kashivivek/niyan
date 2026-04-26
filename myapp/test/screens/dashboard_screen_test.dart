import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DashboardScreen has a title and displays dashboard items', (WidgetTester tester) async {
    final mockAuthService = MockAuthService();
    final mockUser = MockUser();

    when(mockAuthService.user).thenAnswer((_) => Stream.value(UserModel(uid: '123', email: 'test@test.com', name: 'Test User')));
    when(mockUser.uid).thenReturn('123');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: mockAuthService),
          StreamProvider<UserModel?>.value(value: mockAuthService.user, initialData: null),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the title is displayed
    expect(find.text('Dashboard'), findsOneWidget);

    // Verify that the dashboard items are displayed
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Tenants'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
  });
}
