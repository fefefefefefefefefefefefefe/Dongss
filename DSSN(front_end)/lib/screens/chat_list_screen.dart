// lib/screens/chat_list_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/chat_provider.dart';
import 'package:dong_story/models/chat.dart';
import 'package:dong_story/screens/chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('쪽지'),
        backgroundColor: const Color(0xFF1E8854),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final rooms = chatProvider.chatRooms;

          if (rooms.isEmpty) {
            return const Center(
              child: Text('대화 목록이 없습니다.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _ChatRoomTile(room: room);
            },
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomTile({required this.room});

  // 시간을 'HH:mm' 또는 '어제' 등으로 표시하는 간단한 로직
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 25,
        child: Icon(Icons.person),
      ),
      title: Text(room.partnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        room.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Text(_formatTime(room.lastTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(roomId: room.id, partnerName: room.partnerName),
          ),
        );
      },
    );
  }
}