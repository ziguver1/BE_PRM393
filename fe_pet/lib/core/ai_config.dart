import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConfig {
  static String get apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];

    if (key == null || key.trim().isEmpty) {
      throw Exception('Missing OPENAI_API_KEY in .env');
    }

    return key;
  }

  static String get baseUrl {
    return dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  }

  static String get model {
    return dotenv.env['OPENAI_MODEL'] ?? 'gpt-4.1-mini';
  }
}