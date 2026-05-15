import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bootstrap/app_bootstrap.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/recognition_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();

  runApp(
    MyApp(
      config: bootstrap.config,
      authService: bootstrap.authService,
      databaseService: bootstrap.databaseService,
      recognitionService: bootstrap.recognitionService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppConfig config;
  final AuthService authService;
  final DatabaseService databaseService;
  final RecognitionService recognitionService;

  const MyApp({
    super.key,
    required this.config,
    required this.authService,
    required this.databaseService,
    required this.recognitionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<AuthService>.value(value: authService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<RecognitionService>.value(value: recognitionService),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Nhận diện cây cối',
        theme: appTheme(),
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
