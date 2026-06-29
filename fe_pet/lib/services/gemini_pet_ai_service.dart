import 'package:dio/dio.dart';

import '../core/gemini_config.dart';
import 'local_pet_ai_service.dart';

class GeminiPetAiService {
  final LocalPetAiService _localSearchService = LocalPetAiService();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: GeminiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<String> generateReply(String userMessage) async {
    final relevantProducts =
        _localSearchService.searchRelevantProducts(userMessage, limit: 5);

    if (_localSearchService.isMedicalRiskQuestion(userMessage)) {
      return '''
Mình có thể hỗ trợ chọn sản phẩm chăm sóc cơ bản, nhưng mô tả của bạn có dấu hiệu cần bác sĩ thú y kiểm tra trực tiếp.

Bạn nên đưa thú cưng đến bác sĩ thú y càng sớm càng tốt nếu có các dấu hiệu như nôn ra máu, đi ngoài ra máu, co giật, không đi tiểu, sốt cao, bỏ ăn nhiều ngày hoặc nghi ngờ ngộ độc.
''';
    }

    final context = relevantProducts.isEmpty
        ? 'No matching product context found.'
        : relevantProducts.map((result) {
            final product = result.product;

            return '''
Product ID: ${product.id}
Name: ${product.name}
Brand: ${product.brand}
Category: ${product.category}
Pet type: ${product.petType}
Age range: ${product.ageRange}
Price: ${product.price} VND
Stock: ${product.stock}
Description: ${product.description}
Suitable for: ${product.suitableFor.join(', ')}
Not suitable for: ${product.notSuitableFor.join(', ')}
Ingredients: ${product.ingredients.join(', ')}
Benefits: ${product.benefits.join(', ')}
Warnings: ${product.warnings.join(', ')}
Recommendation note: ${product.recommendationNote}
Search reasons: ${result.reasons.join(', ')}
''';
          }).join('\n---\n');

    final prompt = '''
Bạn là PawMart AI, trợ lý tư vấn cửa hàng thức ăn và sản phẩm thú cưng.

Nhiệm vụ:
- Trả lời bằng tiếng Việt.
- Chỉ tư vấn dựa trên PRODUCT_CONTEXT được cung cấp.
- Ưu tiên sản phẩm khớp loại thú cưng, độ tuổi, nhu cầu, cảnh báo.
- Nêu rõ tên sản phẩm, giá, lý do phù hợp, lưu ý an toàn.
- Không chẩn đoán bệnh.
- Nếu người dùng mô tả triệu chứng nghiêm trọng, khuyên đi bác sĩ thú y.
- Nếu không có sản phẩm phù hợp, nói rõ PawMart chưa có sản phẩm khớp.
- Không bịa sản phẩm ngoài PRODUCT_CONTEXT.

CUSTOMER_QUESTION:
$userMessage

PRODUCT_CONTEXT:
$context
''';

    try {
      final response = await _dio.post(
        '/models/${GeminiConfig.model}:generateContent',
        queryParameters: {
          'key': GeminiConfig.apiKey,
        },
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': prompt,
                }
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 800,
          },
        },
      );

      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini returned empty response');
      }

      final content = candidates.first['content'];
      final parts = content?['parts'] as List?;

      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini returned no text parts');
      }

      return parts
          .map((part) => part['text'] ?? '')
          .join('\n')
          .trim();
    } on DioException catch (e) {
      final isConnectionError = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.message?.contains('SocketException') == true ||
          e.error?.toString().contains('SocketException') == true;

      if (isConnectionError) {
        throw Exception('Không có kết nối Internet. Vui lòng kiểm tra kết nối mạng.');
      }

      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      throw Exception('Lỗi dịch vụ AI ($statusCode): $data');
    } catch (e) {
      throw Exception('Lỗi kết nối không xác định: $e');
    }
  }
}

