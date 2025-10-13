// lib/models/chat.dart

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isMe; // 현재 로그인 사용자가 보낸 메시지인지 여부

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatRoom {
  final String id;
  final String partnerName;
  final String lastMessage;
  final DateTime lastTime;
  final List<ChatMessage> messages;

  ChatRoom({
    required this.id,
    required this.partnerName,
    required this.lastMessage,
    required this.lastTime,
    required this.messages,
  });
}