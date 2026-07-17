import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/network/api_client.dart';

class SupportMessage {
  final int id;
  final int conversationId;
  final String senderType; // 'Customer' | 'Admin'
  final int senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String status; // 'SENDING' | 'SENT' | 'DELIVERED' | 'READ'
  final DateTime? deliveredAt;
  final DateTime? readAt;

  SupportMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    final isRead = json['isRead'] ?? false;
    final deliveredAtVal = json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'].toString()) : null;
    final readAtVal = json['readAt'] != null ? DateTime.parse(json['readAt'].toString()) : null;
    return SupportMessage(
      id: json['MessageId'] ?? json['id'] ?? 0,
      conversationId: json['ChatRoomId'] ?? json['conversationId'] ?? 0,
      senderType: json['senderType']?.toString() ?? 'Customer',
      senderId: json['SenderId'] ?? json['senderId'] ?? 0,
      message: json['Content']?.toString() ?? json['message']?.toString() ?? '',
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
      isRead: isRead,
      status: json['status']?.toString() ?? (isRead ? 'READ' : 'SENT'),
      deliveredAt: deliveredAtVal,
      readAt: readAtVal,
    );
  }

  SupportMessage copyWith({
    int? id,
    int? conversationId,
    String? senderType,
    int? senderId,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return SupportMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class SupportConversation {
  final int id;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCustomer;
  final int unreadAdmin;

  SupportConversation({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCustomer,
    required this.unreadAdmin,
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    return SupportConversation(
      id: json['id'] ?? json['ChatRoomId'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['CreatedAt'] != null
              ? DateTime.parse(json['CreatedAt'].toString())
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : (json['UpdatedAt'] != null
              ? DateTime.parse(json['UpdatedAt'].toString())
              : DateTime.now()),
      lastMessage: json['lastMessage']?.toString() ?? json['LastMessage']?.toString() ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'].toString())
          : (json['LastMessageAt'] != null
              ? DateTime.parse(json['LastMessageAt'].toString())
              : DateTime.now()),
      unreadCustomer: json['unreadCustomer'] ?? 0,
      unreadAdmin: json['unreadAdmin'] ?? 0,
    );
  }
}

class SupportChatProvider extends ChangeNotifier {
  io.Socket? _socket;
  SupportConversation? _conversation;
  List<SupportMessage> _messages = [];
  bool _isLoading = false;
  bool _isConnecting = false;
  String? _errorMessage;

  List<SupportMessage> get messages => _messages;
  SupportConversation? get conversation => _conversation;
  bool get isLoading => _isLoading;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;

  bool get isConnected => _socket?.connected ?? false;

  // 1. Fetch current conversation metadata & create if missing
  Future<void> loadConversation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get('/chat/conversation');
      if (response.statusCode == 200 || response.statusCode == 201) {
        _conversation = SupportConversation.fromJson(response.data);
        await _loadMessagesInternal(_conversation!.id);
      }
    } catch (e) {
      log('Error loading conversation: $e');
      _errorMessage = 'Không thể tải hội thoại hỗ trợ. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Fetch history messages of conversation
  Future<void> _loadMessagesInternal(int conversationId) async {
    try {
      final response = await ApiClient().dio.get('/chat/messages', queryParameters: {
        'conversationId': conversationId,
      });
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data;
        _messages = list.map((item) => SupportMessage.fromJson(item)).toList();
      }
    } catch (e) {
      log('Error loading messages: $e');
    }
  }

  // 3. Connect to standalone Socket.IO Server on port 3002
  void connectSocket() {
    if (_socket != null && _socket!.connected) {
      if (_conversation != null) {
        markConversationOpened(_conversation!.id);
      }
      return;
    }

    final token = ApiClient().token;
    if (token == null || token.isEmpty) return;

    _isConnecting = true;
    notifyListeners();

    // Dynamically resolve server IP to target port 3002
    final String apiBase = ApiClient.getBaseUrl();
    String socketUrl = 'http://localhost:3002';
    if (apiBase.contains('10.0.2.2')) {
      socketUrl = 'http://10.0.2.2:3002';
    } else if (apiBase.contains('localhost')) {
      socketUrl = 'http://localhost:3002';
    } else {
      try {
        final uri = Uri.parse(apiBase);
        socketUrl = '${uri.scheme}://${uri.host}:3002';
      } catch (_) {}
    }

    log('Connecting to Socket.IO server: $socketUrl/chat');

    _socket = io.io('$socketUrl/chat', io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      log('Socket connected: support chat');
      _isConnecting = false;
      notifyListeners();

      if (_conversation != null) {
        joinRoom(_conversation!.id);
        markConversationOpened(_conversation!.id);
      }
    });

    _socket!.onConnectError((err) {
      log('Socket connect error: $err');
      _isConnecting = false;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      log('Socket disconnected: support chat');
      notifyListeners();
    });

    // Listen for new messages in real-time
    _socket!.on('new_message', (data) {
      final newMessage = SupportMessage.fromJson(data);
      final clientTempId = data['clientTempId'];

      // If incoming message is from the other party (Admin), immediately acknowledge delivery
      if (newMessage.senderType == 'Admin' && _socket != null && _socket!.connected) {
        _socket!.emit('message_delivered_ack', {
          'messageId': newMessage.id,
        });
      }

      if (clientTempId != null) {
        final index = _messages.indexWhere((m) => m.id == clientTempId);
        if (index != -1) {
          _messages[index] = newMessage;
          notifyListeners();
          return;
        }
      }

      // Prevent duplicate messages
      if (!_messages.any((m) => m.id == newMessage.id)) {
        _messages.add(newMessage);
        notifyListeners();
      }
    });

    // Listen for delivery updates
    _socket!.on('message_delivered', (data) {
      final senderType = data['senderType'];
      final messageId = data['messageId'] ?? data['MessageId'];
      if (senderType == 'Customer') {
        bool updated = false;
        for (var i = 0; i < _messages.length; i++) {
          if (messageId != null) {
            if (_messages[i].id == messageId) {
              _messages[i] = _messages[i].copyWith(status: 'DELIVERED');
              updated = true;
              break;
            }
          } else {
            if (_messages[i].senderType == 'Customer' &&
                (_messages[i].status == 'SENT' || _messages[i].status == 'SENDING')) {
              _messages[i] = _messages[i].copyWith(status: 'DELIVERED');
              updated = true;
            }
          }
        }
        if (updated) notifyListeners();
      }
    });

    // Listen for read receipt updates
    _socket!.on('message_read', (data) {
      final senderType = data['senderType'];
      if (senderType == 'Customer') {
        bool updated = false;
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].senderType == 'Customer' && _messages[i].status != 'READ') {
            _messages[i] = _messages[i].copyWith(status: 'READ', isRead: true);
            updated = true;
          }
        }
        if (updated) notifyListeners();
      }
    });
  }

  // 4. Join the room conversation room
  void joinRoom(int conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join', conversationId);
      log('Emitted join room event for conversation ID: $conversationId');
    }
  }

  // 4b. Mark conversation opened (reads all messages)
  void markConversationOpened(int conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('conversation_opened', {
        'conversationId': conversationId,
      });
      log('Emitted conversation_opened event for conversation ID: $conversationId');
    }
  }

  // 5. Send message (Optimistic updates)
  Future<void> sendMessage(String text) async {
    final messageText = text.trim();
    if (messageText.isEmpty || _conversation == null) return;

    // Optimistic temporary message to display immediately in UI
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final optimisticMsg = SupportMessage(
      id: tempId,
      conversationId: _conversation!.id,
      senderType: 'Customer',
      senderId: _conversation!.userId,
      message: messageText,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'SENDING',
    );

    _messages.add(optimisticMsg);
    notifyListeners();

    try {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('customer_send_message', {
          'conversationId': _conversation!.id,
          'message': messageText,
          'clientTempId': tempId,
        });
      } else {
        // Fallback to HTTP REST API if socket is disconnected
        final response = await ApiClient().dio.post('/chat/message', data: {
          'conversationId': _conversation!.id,
          'message': messageText,
          'clientTempId': tempId,
        });
        if (response.statusCode == 201) {
          final sentMsg = SupportMessage.fromJson(response.data);
          // Remove temporary item and insert final
          _messages.removeWhere((m) => m.id == tempId);
          _messages.add(sentMsg);
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error sending message: $e');
      // Rollback optimistic message and alert user
      _messages.removeWhere((m) => m.id == tempId);
      _errorMessage = 'Không thể gửi tin nhắn. Vui lòng kết nối mạng.';
      notifyListeners();
    }
  }

  // 6. Disconnect from socket on view exit
  void disconnectSocket() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.close();
      _socket = null;
      log('Disconnected support chat socket');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
