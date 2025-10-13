// lib/screens/chat_room_screen.dart (새 파일)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/chat_provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/chat.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;

  const ChatRoomScreen({super.key, required this.roomId, required this.partnerName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 메시지 목록의 끝으로 스크롤
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final senderName = authProvider.currentUser ?? '비회원';

    Provider.of<ChatProvider>(context, listen: false).sendMessage(
      widget.roomId,
      text,
      senderName,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // 위젯이 빌드된 후 스크롤을 맨 아래로 이동
    _scrollToBottom();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.partnerName),
        backgroundColor: const Color(0xFF1E8854),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getMessagesForRoom(widget.roomId);

                return ListView.builder(
                  controller: _scrollController, // 스크롤 컨트롤러 추가
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF1E8854)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// 메시지 말풍선 위젯
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isMe ? const Color(0xFFDCF8C6) : Colors.white;
    final textColor = message.isMe ? Colors.black : Colors.black;
    final margin = message.isMe
        ? const EdgeInsets.only(top: 4, bottom: 4, left: 80)
        : const EdgeInsets.only(top: 4, bottom: 4, right: 80);

    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!message.isMe) // 상대방 메시지일 경우에만 닉네임 표시
              Text(
                message.sender,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
              ),
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}