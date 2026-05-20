import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String geminiApiKey;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String recognitionApiBaseUrl;

  const AppConfig({
    required this.geminiApiKey,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.recognitionApiBaseUrl,
  });

  factory AppConfig.fromEnvironment() {
    String readValue(String key) {
      try {
        final fromDotEnv = dotenv.env[key];
        if (fromDotEnv != null && fromDotEnv.trim().isNotEmpty) {
          return fromDotEnv.trim();
        }
      } catch (_) {
        // When `.env` is not bundled, dev/release builds can still read
        // values supplied through `--dart-define` without crashing here.
      }
      return _readKnownDartDefine(key);
    }

    final supabasePublishableKey = readValue('SUPABASE_PUBLISHABLE_KEY');

    return AppConfig(
      geminiApiKey: readValue('GEMINI_API_KEY'),
      supabaseUrl: readValue('SUPABASE_URL'),
      supabasePublishableKey: supabasePublishableKey.isNotEmpty
          ? supabasePublishableKey
          : readValue('SUPABASE_ANON_KEY'),
      recognitionApiBaseUrl: readValue('RECOGNITION_API_BASE_URL'),
    );
  }

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  bool get isRemoteRecognitionConfigured => recognitionApiBaseUrl.isNotEmpty;

  static String _readKnownDartDefine(String key) {
    switch (key) {
      case 'GEMINI_API_KEY':
        return const String.fromEnvironment('GEMINI_API_KEY').trim();
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL').trim();
      case 'SUPABASE_PUBLISHABLE_KEY':
        return const String.fromEnvironment(
          'SUPABASE_PUBLISHABLE_KEY',
        ).trim();
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment('SUPABASE_ANON_KEY').trim();
      case 'RECOGNITION_API_BASE_URL':
        return const String.fromEnvironment(
          'RECOGNITION_API_BASE_URL',
        ).trim();
      default:
        return '';
    }
  }
}
