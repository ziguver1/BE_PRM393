import '../data/pet_knowledge_data.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime createdAt;

  AiChatMessage({
    required this.text,
    required this.isUser,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ProductSearchResult {
  final PetKnowledgeItem product;
  final int score;
  final List<String> reasons;

  const ProductSearchResult({
    required this.product,
    required this.score,
    required this.reasons,
  });
}

class LocalPetAiService {
  static const List<String> _medicalRiskWords = [
    'nôn ra máu',
    'đi ngoài ra máu',
    'không thở',
    'co giật',
    'bỏ ăn nhiều ngày',
    'tiểu ra máu',
    'không đi tiểu',
    'sốt cao',
    'ngộ độc',
    'tai chảy mủ',
    'vết thương hở',
  ];

  String normalize(String input) {
    var text = input.toLowerCase().trim();

    const vietnameseMap = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };

    vietnameseMap.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  List<String> _tokens(String text) {
    final normalized = normalize(text);
    return normalized
        .split(' ')
        .where((word) => word.length >= 2)
        .toList();
  }

  bool _containsAny(String text, List<String> phrases) {
    final normalizedText = normalize(text);
    return phrases.any((phrase) => normalizedText.contains(normalize(phrase)));
  }

  ProductSearchResult _scoreProduct(String userMessage, PetKnowledgeItem product) {
    final normalizedQuestion = normalize(userMessage);
    final productText = normalize(product.knowledgeText);
    final questionTokens = _tokens(userMessage);

    int score = 0;
    final reasons = <String>[];

    for (final token in questionTokens) {
      if (productText.contains(token)) score += 1;
    }

    if (_containsAny(normalizedQuestion, ['mèo', 'meo', 'cat'])) {
      if (normalize(product.petType).contains('cat')) {
        score += 18;
        reasons.add('phù hợp cho mèo');
      }
    }

    if (_containsAny(normalizedQuestion, ['chó', 'cho', 'cún', 'cun', 'dog', 'puppy'])) {
      if (normalize(product.petType).contains('dog')) {
        score += 18;
        reasons.add('phù hợp cho chó');
      }
    }

    if (_containsAny(normalizedQuestion, ['mèo con', 'meo con', 'kitten', 'babycat', 'mèo 1 tháng', 'mèo 2 tháng', 'mèo 3 tháng'])) {
      if (_containsAny(product.ageRange, ['kitten', 'babycat', '1-4 months', '2-12 months'])) {
        score += 22;
        reasons.add('đúng nhóm tuổi mèo con');
      }
    }

    if (_containsAny(normalizedQuestion, ['chó con', 'cho con', 'cún con', 'cun con', 'puppy', 'chó 2 tháng', 'chó 3 tháng'])) {
      if (_containsAny(product.ageRange, ['puppy', '2-12 months'])) {
        score += 22;
        reasons.add('đúng nhóm tuổi chó con');
      }
    }

    if (_containsAny(normalizedQuestion, ['trưởng thành', 'truong thanh', 'adult', 'chó lớn', 'cho lon', 'mèo lớn', 'meo lon'])) {
      if (_containsAny(product.ageRange, ['adult', '1+ years'])) {
        score += 12;
        reasons.add('phù hợp thú cưng trưởng thành');
      }
    }

    final intentRules = <String, List<String>>{
      'da lông': ['lông', 'long', 'da', 'coat', 'skin', 'rụng lông', 'rụng', 'đẹp lông', 'dep long'],
      'tiêu hóa': ['tiêu hóa', 'tieu hoa', 'đi ngoài', 'di ngoai', 'phân', 'phan', 'stool', 'digest'],
      'tiết niệu': ['tiểu', 'tieu', 'urinary', 'nước tiểu', 'nuoc tieu'],
      'răng miệng': ['răng', 'rang', 'miệng', 'mieng', 'hôi miệng', 'hoi mieng', 'dental', 'plaque'],
      'bọ chét ve': ['ve', 'bọ chét', 'bo chet', 'flea', 'tick'],
      'vệ sinh': ['tắm', 'tam', 'shampoo', 'vệ sinh', 've sinh', 'khử mùi', 'khu mui'],
      'đồ chơi': ['đồ chơi', 'do choi', 'toy', 'cào', 'cao', 'cắn đồ', 'can do'],
      'combo': ['combo', 'mới nuôi', 'moi nuoi', 'starter', 'cần mua gì', 'can mua gi'],
      'uống nước': ['uống nước', 'uong nuoc', 'ít uống', 'it uong', 'hydration', 'water'],
      'giá rẻ': ['giá rẻ', 'gia re', 'tiết kiệm', 'tiet kiem', 'rẻ', 're'],
      'premium': ['premium', 'cao cấp', 'cao cap', 'tốt nhất', 'tot nhat'],
    };

    for (final entry in intentRules.entries) {
      if (_containsAny(normalizedQuestion, entry.value)) {
        final productHasIntent =
            entry.value.any((keyword) => productText.contains(normalize(keyword))) ||
            product.tags.any((tag) => normalize(tag).contains(normalize(entry.key))) ||
            product.benefits.any((benefit) => normalize(benefit).contains(normalize(entry.key)));

        if (productHasIntent) {
          score += 14;
          reasons.add('khớp nhu cầu ${entry.key}');
        }
      }
    }

    for (final alias in product.aliases) {
      if (normalizedQuestion.contains(normalize(alias))) {
        score += 18;
        reasons.add('khớp từ khóa tìm kiếm "$alias"');
      }
    }

    if (score > 0 && product.status == 'active' && product.stock > 0) {
      score += 5;
      reasons.add('còn hàng');
    }

    return ProductSearchResult(
      product: product,
      score: score,
      reasons: reasons.toSet().toList(),
    );
  }

  List<ProductSearchResult> searchRelevantProducts(String userMessage, {int limit = 4}) {
    final results = petKnowledgeBase
        .map((product) => _scoreProduct(userMessage, product))
        .where((result) => result.score > 3)
        .toList();

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  bool isMedicalRiskQuestion(String userMessage) {
    final normalizedQuestion = normalize(userMessage);
    return _medicalRiskWords.any((word) => normalizedQuestion.contains(normalize(word)));
  }

  String generateReply(String userMessage) {
    final results = searchRelevantProducts(userMessage);

    if (isMedicalRiskQuestion(userMessage)) {
      return '''
Mình có thể gợi ý sản phẩm chăm sóc cơ bản, nhưng mô tả của bạn có dấu hiệu cần được kiểm tra trực tiếp.

Bạn nên đưa thú cưng đến bác sĩ thú y càng sớm càng tốt, đặc biệt nếu có các dấu hiệu như bỏ ăn lâu, nôn/đi ngoài ra máu, co giật, không đi tiểu, sốt cao hoặc nghi ngờ ngộ độc.

Sau khi bác sĩ xác định tình trạng, PawMart có thể hỗ trợ chọn thức ăn hoặc sản phẩm chăm sóc phù hợp hơn.
''';
    }

    if (results.isEmpty) {
      return '''
Mình chưa tìm thấy sản phẩm thật sự khớp với câu hỏi trong dữ liệu PawMart hiện tại.

Bạn có thể hỏi cụ thể hơn theo mẫu:
• Mèo con 3 tháng nên ăn gì?
• Chó con mới nuôi cần mua gì?
• Mèo ít uống nước thì nên mua gì?
• Chó bị hôi miệng dùng sản phẩm nào?
• Có thức ăn giúp chó/mèo đẹp lông không?
''';
    }

    final buffer = StringBuffer();

    buffer.writeln('Mình tìm thấy ${results.length} lựa chọn phù hợp trong dữ liệu PawMart:');
    buffer.writeln('');

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final product = result.product;

      buffer.writeln('${i + 1}. ${product.name}');
      buffer.writeln('   • Giá: ${_formatCurrency(product.price)}');
      buffer.writeln('   • Dành cho: ${product.petType} - ${product.ageRange}');
      buffer.writeln('   • Lý do phù hợp: ${result.reasons.take(3).join(', ')}.');
      buffer.writeln('   • Lợi ích chính: ${product.benefits.take(3).join(', ')}.');
      buffer.writeln('   • Lưu ý: ${product.warnings.first}');
      buffer.writeln('');
    }

    final best = results.first.product;
    buffer.writeln('Gợi ý ưu tiên: ${best.name}.');
    buffer.writeln('Vì sản phẩm này khớp tốt nhất với câu hỏi của bạn và hiện còn ${best.stock} sản phẩm trong kho.');

    buffer.writeln('');
    buffer.writeln('Lưu ý: Nếu thú cưng đang có triệu chứng bệnh nghiêm trọng, nên hỏi bác sĩ thú y trước khi đổi thức ăn hoặc dùng sản phẩm chăm sóc.');

    return buffer.toString();
  }

  String _formatCurrency(int value) {
    final chars = value.toString().split('').reversed.toList();
    final parts = <String>[];

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) parts.add('.');
      parts.add(chars[i]);
    }

    return '${parts.reversed.join()}đ';
  }
}
