import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/property_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/action_item_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core_platform_interface/test.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Stream<UserModel?> get user => Stream.value(UserModel(
        uid: '123',
        email: 'test@test.com',
        name: 'Test User',
        currentRole: AppRole.owner,
      ));
}

class MockPropertyService extends Mock implements PropertyService {
  @override
  Stream<List<PropertyModel>> getProperties(String ownerId) => Stream.value([]);
  @override
  Stream<List<UnitModel>> allUnits(String ownerId) => Stream.value([]);
}

class MockDatabaseService extends Mock implements DatabaseService {
  @override
  Stream<List<PropertyModel>> getProperties(String ownerId) => Stream.value([]);
  @override
  Stream<List<UnitModel>> allUnits(String ownerId) => Stream.value([]);
  @override
  Stream<List<ActionItem>> getActionItems(String ownerId) => Stream.value([]);
}

class MockAppModeProvider extends AppModeProvider {
  @override
  bool get isInitialized => true;

  @override
  AppMode get mode => AppMode.standalone;
}

class MockFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #collection) {
      return MockCollectionReference();
    }
    throw UnimplementedError();
  }
}

class MockCollectionReference implements CollectionReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      return MockQuery();
    }
    throw UnimplementedError();
  }
}

class MockQuery implements Query<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #snapshots) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.value(MockQuerySnapshot());
    }
    throw UnimplementedError();
  }
}

class MockQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #docs) {
      return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  testWidgets('DashboardScreen has a title and displays dashboard items', (WidgetTester tester) async {
    final mockAuthService = MockAuthService();
    final mockPropertyService = MockPropertyService();
    final mockDatabaseService = MockDatabaseService();
    final mockFirestore = MockFirebaseFirestore();
    final appModeProvider = MockAppModeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: mockAuthService),
          Provider<PropertyService>.value(value: mockPropertyService),
          Provider<DatabaseService>.value(value: mockDatabaseService),
          Provider<FirebaseFirestore>.value(value: mockFirestore),
          ChangeNotifierProvider<AppModeProvider>.value(value: appModeProvider),
          StreamProvider<UserModel?>.value(value: mockAuthService.user, initialData: null),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the welcome title is displayed
    expect(find.textContaining('Welcome,'), findsOneWidget);

    // Verify that the dashboard KPI cards are displayed
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Occupancy'), findsOneWidget);
    expect(find.text('Pending Rents'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
  });
}
