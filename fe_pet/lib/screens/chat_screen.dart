import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage([String? customText]) async {
    final text = (customText ?? messageController.text).trim();

    if (text.isEmpty) return;

    if (customText == null) {
      messageController.clear();
    }

    await context.read<ChatProvider>().sendMessage(text);

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 100));

    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    // Danh sách câu hỏi gợi ý nhanh
    final suggestions = [
      'Mèo con 3 tháng ăn gì?',
      'Chó bị hôi miệng dùng gì?',
      'Cát vệ sinh mèo khử mùi tốt',
      'Đồ chơi cho cún hay cắn phá',
      'Hạt mềm dễ tiêu hóa cho cún',
    ];

    // Số lượng dòng trong list bao gồm tin nhắn + typing indicator (nếu đang tải)
    final totalItems = chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trợ lý PawMart AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Sẵn sàng hỗ trợ bạn',
                  style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: chatProvider.clearChat,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Xóa hội thoại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner thông tin hỗ trợ AI
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI đang đọc dữ liệu sản phẩm của PawMart. Bạn có thể hỏi: "mèo con 3 tháng ăn gì", "chó hôi miệng dùng gì", "mới nuôi mèo cần mua gì"...',
                    style: TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                // Hiển thị TypingIndicator ở dòng cuối cùng khi đang load
                if (index == chatProvider.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: TypingIndicator(),
                  );
                }

                final message = chatProvider.messages[index];

                if (message.isUser) {
                  // Bong bóng tin nhắn của người dùng
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.zero,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                } else {
                  // Bong bóng tin nhắn của AI (được nâng cấp)
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.orange.shade800,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PawMart AI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.zero,
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: ParsedResponseWidget(text: message.text),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          if (chatProvider.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      chatProvider.errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: chatProvider.clearError,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          // Chips gợi ý nhanh đặt ngay trên thanh nhập liệu
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    onPressed: chatProvider.isLoading ? null : () => sendMessage(suggestions[index]),
                    label: Text(suggestions[index]),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          // Ô nhập tin nhắn & nút gửi thiết kế cao cấp
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: messageController,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Hỏi PawMart AI...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: chatProvider.isLoading ? null : () => sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: chatProvider.isLoading ? Colors.grey.shade300 : Colors.orange.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!chatProvider.isLoading)
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget phân tích phản hồi thông minh
class ParsedResponseWidget extends StatelessWidget {
  final String text;
  const ParsedResponseWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // 1. Dòng thông tin sản phẩm (Ví dụ: "1. Royal Canin...")
      final productHeaderRegExp = RegExp(r'^(\d+)\.\s+(.*)');
      if (productHeaderRegExp.hasMatch(line)) {
        final match = productHeaderRegExp.firstMatch(line)!;
        final num = match.group(1);
        final name = match.group(2)!.replaceAll('**', '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    num!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 2. Dòng thuộc tính chi tiết (Ví dụ: "• Giá: ...")
      final detailRegExp = RegExp(r'^([•\-*])\s+([^:]+):\s+(.*)');
      if (detailRegExp.hasMatch(line)) {
        final match = detailRegExp.firstMatch(line)!;
        final key = match.group(2)!.trim().replaceAll('**', '');
        final value = match.group(3)!.trim().replaceAll('**', '');

        IconData icon = Icons.info_outline_rounded;
        Color color = Colors.grey.shade600;

        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('giá')) {
          icon = Icons.sell_outlined;
          color = Colors.green.shade600;
        } else if (lowerKey.contains('dành cho') || lowerKey.contains('phù hợp')) {
          icon = Icons.pets_rounded;
          color = Colors.blue.shade600;
        } else if (lowerKey.contains('lý do')) {
          icon = Icons.check_circle_outline_rounded;
          color = Colors.orange.shade700;
        } else if (lowerKey.contains('lợi ích')) {
          icon = Icons.stars_rounded;
          color = Colors.amber.shade700;
        } else if (lowerKey.contains('lưu ý') || lowerKey.contains('cảnh báo')) {
          icon = Icons.warning_amber_rounded;
          color = Colors.red.shade600;
        }

        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      children: [
                        TextSpan(
                          text: '$key: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: value),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Dòng cảnh báo/lưu ý y tế quan trọng (Đổi màu hộp cảnh báo để nổi bật)
      if (line.toLowerCase().startsWith('lưu ý:') || line.toLowerCase().contains('bác sĩ thú y')) {
        children.add(
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.replaceAll('**', ''),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Các dòng text thông thường (Ví dụ: câu chào, câu chốt hạ)
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line.replaceAll('**', ''),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// Widget mô phỏng hiệu ứng đang nhập tin nhắn (Typing Indicator)
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.orange.shade100,
          child: Icon(
            Icons.smart_toy_rounded,
            color: Colors.orange.shade800,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay) % 1.0;
                  final opacity = (1.0 - (value - 0.5).abs() * 2).clamp(0.2, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
