import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/screens/wrapper.dart';
import 'package:myapp/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:myapp/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<ImageService>(create: (_) => ImageService()),
        StreamProvider<UserModel?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Property Manager',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const Wrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
