import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  static String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];

    if (key == null || key.trim().isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env');
    }

    return key;
  }

  static String get baseUrl {
    return dotenv.env['GEMINI_BASE_URL'] ??
        'https://generativelanguage.googleapis.com/v1beta';
  }

  static String get model {
    return dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
  }
}