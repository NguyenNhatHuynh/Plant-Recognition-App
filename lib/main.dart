import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'services/recognition_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Local development can still fall back to --dart-define or an injected env file.
  }

  final databaseService = DatabaseService();
  final recognitionService = RecognitionService(
    apiKey: dotenv.env['GEMINI_API_KEY'] ??
        const String.fromEnvironment('GEMINI_API_KEY'),
  );

  runApp(
    MyApp(
      databaseService: databaseService,
      recognitionService: recognitionService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;
  final RecognitionService recognitionService;

  const MyApp({
    super.key,
    required this.databaseService,
    required this.recognitionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<RecognitionService>.value(value: recognitionService),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Nhận diện cây cối',
        theme: appTheme(),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
