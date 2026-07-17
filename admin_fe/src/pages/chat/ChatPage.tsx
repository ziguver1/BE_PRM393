import React, { useState, useEffect, useRef } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Send } from 'lucide-react';
import { io, Socket } from 'socket.io-client';
import { storage } from '@/utils/storage';
import { chatService } from '@/services';
import { useAuth } from '@/contexts';
import { formatRelativeTime } from '@/utils/format';
import { Button } from '@/components/ui';
import { LoadingPage, EmptyState, ErrorPage, Loading } from '@/components';
import { ChatRoom, Message } from '@/types';

// Web audio URL for incoming notifications
const NOTIFICATION_SOUND = 'https://assets.mixkit.co/active_storage/sfx/2869/2869-600.wav';

export function ChatPage() {
  const queryClient = useQueryClient();
  const { admin } = useAuth();
  const [selectedRoom, setSelectedRoom] = useState<ChatRoom | null>(null);
  const [messageText, setMessageText] = useState('');
  const [liveMessages, setLiveMessages] = useState<Message[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const socketRef = useRef<Socket | null>(null);

  const token = storage.get<string>('ACCESS_TOKEN');

  // 1. Fetch conversations (rooms) using React Query
  const { data: rooms, isLoading: roomsLoading, error: roomsError, refetch } = useQuery({
    queryKey: ['chat-rooms'],
    queryFn: () => chatService.getRooms(),
  });

  // 2. Fetch history when selected room changes
  useEffect(() => {
    if (!selectedRoom) {
      setLiveMessages([]);
      return;
    }

    // Load message history from REST API
    chatService.getMessages(selectedRoom.ChatRoomId).then((history) => {
      setLiveMessages(history);
      // Mark read in DB and trigger room list refresh to reset badge
      queryClient.invalidateQueries({ queryKey: ['chat-rooms'] });
    });

    // Join room and mark conversation opened via socket
    if (socketRef.current) {
      socketRef.current.emit('join', selectedRoom.ChatRoomId);
      socketRef.current.emit('conversation_opened', { conversationId: selectedRoom.ChatRoomId });
    }
  }, [selectedRoom, queryClient]);

  // 3. Connect to standalone Socket.IO Server
  useEffect(() => {
    if (!token) return;

    const socket = io('http://localhost:3002/chat', {
      auth: { token },
      transports: ['websocket'],
    });

    socketRef.current = socket;

    socket.on('connect', () => {
      console.log('Admin socket support connected successfully.');
    });

    // Listen to real-time incoming messages
    socket.on('new_message', (msg: any) => {
      // Map properties to match client Message interface
      const incomingMessage: Message = {
        MessageId: msg.MessageId,
        ChatRoomId: msg.ChatRoomId,
        SenderId: msg.SenderId,
        Content: msg.Content,
        CreatedAt: msg.CreatedAt,
        status: msg.status,
        Sender: (admin && msg.SenderId === admin.id) ? {
          UserId: admin.id,
          FullName: admin.name || 'Admin',
          Avatar: null,
          Role: 'ADMIN',
        } : undefined,
      };

      // Play audio notification if customer sent it
      const isFromCustomer = msg.senderType === 'Customer';

      if (isFromCustomer) {
        new Audio(NOTIFICATION_SOUND).play().catch(() => {});
        socket.emit('message_delivered_ack', { messageId: msg.MessageId });
      }

      setLiveMessages((prev) => {
        // Avoid duplicate message appending
        if (prev.some((m) => m.MessageId === incomingMessage.MessageId)) {
          return prev;
        }
        return [...prev, incomingMessage];
      });

      // Clear badge if current room is active and update rooms list
      queryClient.invalidateQueries({ queryKey: ['chat-rooms'] });
    });

    socket.on('message_read', (data: any) => {
      if (data.senderType === 'Admin') {
        setLiveMessages((prev) =>
          prev.map((m) =>
            admin && m.SenderId === admin.id ? { ...m, status: 'READ' } : m
          )
        );
      }
    });

    socket.on('message_delivered', (data: any) => {
      if (data.senderType === 'Admin') {
        setLiveMessages((prev) =>
          prev.map((m) => {
            if (data.messageId) {
              return m.MessageId === data.messageId ? { ...m, status: 'DELIVERED' } : m;
            }
            return admin && m.SenderId === admin.id && (!m.status || m.status === 'SENT')
              ? { ...m, status: 'DELIVERED' }
              : m;
          })
        );
      }
    });

    // Listen for room updates (e.g. unread counters, last messages)
    socket.on('conversations_updated', () => {
      queryClient.invalidateQueries({ queryKey: ['chat-rooms'] });
    });

    return () => {
      socket.off('connect');
      socket.off('new_message');
      socket.off('message_read');
      socket.off('message_delivered');
      socket.off('conversations_updated');
      socket.disconnect();
    };
  }, [token, admin, queryClient]);

  // 4. Auto scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [liveMessages]);

  const handleSendMessage = () => {
    if (!messageText.trim() || !selectedRoom) return;

    // Send via socket connection for instant response
    if (socketRef.current) {
      socketRef.current.emit('admin_send_message', {
        conversationId: selectedRoom.ChatRoomId,
        message: messageText.trim(),
      });
      setMessageText('');
    } else {
      // Fallback to REST API if socket is offline
      chatService.sendMessage({
        ChatRoomId: selectedRoom.ChatRoomId,
        Content: messageText.trim(),
      }).then(() => {
        setMessageText('');
      });
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  if (roomsLoading) return <LoadingPage />;
  if (roomsError) return <ErrorPage onRetry={() => refetch()} />;

  const roomList = rooms || [];

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* Room List */}
      <div className="w-80 rounded-lg border bg-card flex flex-col">
        <div className="border-b p-4">
          <h2 className="text-lg font-semibold text-foreground">Hội thoại hỗ trợ</h2>
        </div>
        <div className="flex-1 overflow-y-auto">
          {roomList.length === 0 ? (
            <EmptyState
              icon="message"
              title="Không có hội thoại nào"
              description="Chưa có khách hàng nhắn tin hỗ trợ"
            />
          ) : (
            roomList.map((room: any) => {
              const isSelected = selectedRoom?.ChatRoomId === room.ChatRoomId;
              // Check unread count (unreadAdmin in new model)
              const unreadCount = room.unreadAdmin || 0;
              const hasUnread = unreadCount > 0;

              return (
                <div
                  key={room.ChatRoomId}
                  className={`flex cursor-pointer gap-3 border-b p-4 hover:bg-muted/50 transition-colors ${
                    isSelected ? 'bg-muted/50' : ''
                  }`}
                  onClick={() => setSelectedRoom(room)}
                >
                  <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10">
                    <span className="text-sm font-semibold text-primary">
                      {room.User?.FullName?.charAt(0).toUpperCase() || 'C'}
                    </span>
                    {hasUnread && !isSelected && (
                      <span className="absolute -top-1 -right-1 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-destructive px-1 text-[10px] font-bold text-destructive-foreground">
                        {unreadCount}
                      </span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <p className={`text-sm truncate ${hasUnread ? 'font-bold text-foreground' : 'font-medium text-foreground'}`}>
                        {room.User?.FullName}
                      </p>
                    </div>
                    <p className={`text-xs truncate mt-0.5 ${hasUnread ? 'font-semibold text-foreground' : 'text-muted-foreground'}`}>
                      {room.lastMessage || 'Chưa có tin nhắn'}
                    </p>
                    <p className="text-[10px] text-muted-foreground mt-1">
                      {formatRelativeTime(room.lastMessageAt || room.CreatedAt)}
                    </p>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Chat Window */}
      <div className="flex-1 rounded-lg border bg-card flex flex-col">
        {selectedRoom ? (
          <>
            {/* Chat Header */}
            <div className="border-b p-4 flex items-center justify-between bg-muted/20">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                  <span className="text-sm font-semibold text-primary">
                    {selectedRoom.User?.FullName?.charAt(0).toUpperCase() || 'C'}
                  </span>
                </div>
                <div>
                  <p className="text-sm font-medium text-foreground">{selectedRoom.User?.FullName}</p>
                  <p className="text-xs text-muted-foreground">ID khách hàng: #{selectedRoom.UserId}</p>
                </div>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-muted/5">
              {liveMessages.length === 0 ? (
                <div className="flex items-center justify-center h-full text-muted-foreground text-sm">
                  Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện hỗ trợ!
                </div>
              ) : (
                liveMessages.map((msg) => {
                  const isOutgoing = !!(admin && msg.SenderId === admin.id);
                  
                  return (
                    <div
                      key={msg.MessageId}
                      className={`flex ${isOutgoing ? 'justify-end' : 'justify-start'}`}
                    >
                      <div className={`flex gap-2 max-w-[70%] ${isOutgoing ? 'flex-row-reverse' : 'flex-row'}`}>
                        {!isOutgoing && (
                          <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10">
                            <span className="text-xs font-semibold text-primary">
                              {selectedRoom.User?.FullName?.charAt(0).toUpperCase() || 'C'}
                            </span>
                          </div>
                        )}
                        <div>
                          {!isOutgoing && (
                            <p className="text-[10px] text-muted-foreground ml-1 mb-1">
                              {selectedRoom.User?.FullName}
                            </p>
                          )}
                          <div
                            className={`rounded-lg px-4 py-2 text-sm ${
                              isOutgoing
                                ? 'bg-primary text-primary-foreground rounded-tr-none'
                                : 'bg-card border text-foreground rounded-tl-none'
                            }`}
                          >
                            <p className="break-all whitespace-pre-wrap">{msg.Content}</p>
                          </div>
                          <div className={`flex items-center gap-1 mt-1 ${isOutgoing ? 'justify-end mr-1' : 'ml-1'}`}>
                            <p className="text-[9px] text-muted-foreground">
                              {new Date(msg.CreatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </p>
                            {isOutgoing && (
                              <span className="text-[10px] select-none">
                                {(!msg.status || msg.status === 'SENT') && <span className="text-muted-foreground">✓</span>}
                                {msg.status === 'DELIVERED' && <span className="text-muted-foreground">✓✓</span>}
                                {msg.status === 'READ' && <span className="text-green-500 font-semibold">✓✓</span>}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Message Input */}
            <div className="border-t p-4 bg-background">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Nhập tin nhắn hỗ trợ..."
                  className="flex-1 rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                  value={messageText}
                  onChange={(e) => setMessageText(e.target.value)}
                  onKeyDown={handleKeyPress}
                />
                <Button
                  onClick={handleSendMessage}
                  disabled={!messageText.trim()}
                >
                  <Send className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </>
        ) : (
          <EmptyState
            icon="message"
            title="Chọn khách hàng hỗ trợ"
            description="Chọn một cuộc hội thoại ở danh sách bên trái để phản hồi hỗ trợ trực tuyến"
          />
        )}
      </div>
    </div>
  );
}
