import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:myapp/services/billing_service.dart';
import 'package:myapp/services/property_service.dart';
import 'package:myapp/services/tenant_service.dart';
import 'package:myapp/services/transaction_service.dart';
import 'package:myapp/services/vendor_service.dart';
import 'package:myapp/services/society_service.dart';
import 'package:myapp/services/visitor_service.dart';
import 'package:myapp/services/admin_service.dart';
import 'package:myapp/services/community_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15 edge-to-edge compliance
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Activate App Check for non-web platforms.
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  }
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;
  late final AppRouter _appRouter;
  late final AppModeProvider _appModeProvider;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _appModeProvider = AppModeProvider();
    _appRouter = AppRouter(_authService, _appModeProvider);
    // Mode is now restored in MainNavigationScreen._checkAutoRoute()
    // where UserModel is available for Firestore-backed cross-device sync.
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _appModeProvider),
        Provider<AuthService>.value(value: _authService),
        // Legacy monolithic service — kept for backward compatibility
        // Screens are gradually migrating to domain-specific services below
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<ImageService>(create: (_) => ImageService()),
        // New domain-specific services (Phase 0)
        Provider<PropertyService>(create: (_) => PropertyService()),
        Provider<TenantService>(create: (_) => TenantService()),
        Provider<BillingService>(create: (_) => BillingService()),
        Provider<TransactionService>(create: (_) => TransactionService()),
        Provider<SocietyService>(create: (_) => SocietyService()),
        Provider<VendorService>(create: (_) => VendorService()),
        Provider<VisitorService>(create: (_) => VisitorService()),
        Provider<AdminService>(create: (_) => AdminService()),
        Provider<CommunityService>(create: (_) => CommunityService()),
        StreamProvider<UserModel?>(
          create: (context) => _authService.user,
          initialData: null,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Niyan',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _appRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
