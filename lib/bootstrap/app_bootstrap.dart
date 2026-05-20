import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/recognition_service.dart';

class AppBootstrap {
  final AppConfig config;
  final AuthService authService;
  final DatabaseService databaseService;
  final RecognitionService recognitionService;

  const AppBootstrap({
    required this.config,
    required this.authService,
    required this.databaseService,
    required this.recognitionService,
  });

  static Future<AppBootstrap> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Local development can still fall back to --dart-define values.
    }

    final config = AppConfig.fromEnvironment();

    if (config.isSupabaseConfigured) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabasePublishableKey,
      );
    }

    return AppBootstrap(
      config: config,
      authService: AuthService(
        client: config.isSupabaseConfigured ? Supabase.instance.client : null,
      ),
      databaseService: DatabaseService(),
      recognitionService: RecognitionService(
        apiKey: config.geminiApiKey,
        publishableKey: config.supabasePublishableKey,
        remoteBaseUrl: config.recognitionApiBaseUrl,
      ),
    );
  }
}
