import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/main_navigation_screen.dart';

import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Stream<UserModel?> get user => Stream.value(UserModel(
        uid: '123',
        email: 'test@test.com',
        name: 'Test User',
        currentRole: AppRole.owner,
      ));
}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockAppModeProvider extends AppModeProvider {
  @override
  bool get isInitialized => true;

  @override
  AppMode get mode => AppMode.standalone;

  @override
  Future<void> loadSavedMode({UserModel? user}) async {
    // Stub to avoid SharedPreferences calls
  }
}

void main() {
  testWidgets('MainNavigationScreen desktop layout test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    final mockAuthService = MockAuthService();
    final mockDatabaseService = MockDatabaseService();
    final mockAppMode = MockAppModeProvider();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainNavigationScreen(child: SizedBox()),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: mockAuthService),
          Provider<DatabaseService>.value(value: mockDatabaseService),
          ChangeNotifierProvider<AppModeProvider>.value(value: mockAppMode),
          StreamProvider<UserModel?>.value(value: mockAuthService.user, initialData: null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });
}
