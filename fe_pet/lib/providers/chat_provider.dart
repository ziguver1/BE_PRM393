import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/gemini_pet_ai_service.dart';
import '../services/local_pet_ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiPetAiService _aiService = GeminiPetAiService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final List<AiChatMessage> messages = [
    AiChatMessage(
      text:
          'Xin chào! Mình là PawMart AI. Bạn có thể hỏi mình về thức ăn, snack, đồ chăm sóc, đồ chơi cho chó mèo.',
      isUser: false,
    ),
  ];

  bool isLoading = false;
  String? errorMessage;

  ChatProvider() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasNoConnection = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (hasNoConnection) {
        errorMessage = "Không có kết nối Internet. Đã tự động chuyển sang chế độ ngoại tuyến.";
      } else {
        if (errorMessage == "Không có kết nối Internet. Đã tự động chuyển sang chế độ ngoại tuyến.") {
          errorMessage = null;
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    final message = text.trim();

    if (message.isEmpty) return;

    messages.add(AiChatMessage(text: message, isUser: true));
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final reply = await _aiService.generateReply(message);

      messages.add(
        AiChatMessage(
          text: reply,
          isUser: false,
        ),
      );
    } catch (e) {
      final localReply = LocalPetAiService().generateReply(message);

      // Làm sạch chuỗi Exception: ở đầu nếu có
      String friendlyError = e.toString();
      if (friendlyError.startsWith('Exception: ')) {
        friendlyError = friendlyError.substring('Exception: '.length);
      }

      messages.add(
        AiChatMessage(
          text:
              '⚠️ Thiết bị đang ngoại tuyến hoặc kết nối yếu. Tôi đã tự động chuyển sang dữ liệu sản phẩm offline để hỗ trợ bạn:\n\n$localReply',
          isUser: false,
        ),
      );

      errorMessage = friendlyError;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearChat() {
    messages
      ..clear()
      ..add(
        AiChatMessage(
          text:
              'Xin chào! Mình là PawMart AI. Bạn có thể hỏi mình về thức ăn, snack, đồ chăm sóc, đồ chơi cho chó mèo.',
          isUser: false,
        ),
      );

    errorMessage = null;
    notifyListeners();
  }
}