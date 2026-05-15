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
      final fromDotEnv = dotenv.env[key];
      if (fromDotEnv != null && fromDotEnv.trim().isNotEmpty) {
        return fromDotEnv.trim();
      }
      return String.fromEnvironment(key).trim();
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
}
