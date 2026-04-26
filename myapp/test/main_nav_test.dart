import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/main_navigation_screen.dart';

import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Stream<UserModel?> get user => Stream.value(UserModel(uid: '123', email: 'test@test.com', name: 'Test'));
}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  testWidgets('MainNavigationScreen desktop layout test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: MockAuthService()),
          Provider<DatabaseService>.value(value: MockDatabaseService()),
          StreamProvider<UserModel?>.value(value: MockAuthService().user, initialData: null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MainNavigationScreen()),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
