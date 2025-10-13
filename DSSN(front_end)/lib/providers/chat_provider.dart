// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import 'package:dong_story/models/chat.dart';

class ChatProvider extends ChangeNotifier {
  // 더미 채팅 데이터
  final List<ChatRoom> _chatRooms = [
    ChatRoom(
      id: 'r1',
      partnerName: '김민지',
      lastMessage: '네, 알겠습니다. 내일 뵙겠습니다.',
      lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
      messages: [
        ChatMessage(
            sender: '김민지',
            text: '혹시 스터디 자료는 다 준비되셨나요?',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isMe: false),
        ChatMessage(
            sender: '나',
            text: '네, 알겠습니다. 내일 뵙겠습니다.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isMe: true),
      ],
    ),
    ChatRoom(
      id: 'r2',
      partnerName: '박준호 선배',
      lastMessage: '네, 바로 전달드릴게요.',
      lastTime: DateTime.now().subtract(const Duration(minutes: 30)),
      messages: [
        ChatMessage(
            sender: '박준호 선배',
            text: '프로젝트 계획서 좀 보내줄 수 있니?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isMe: false),
        ChatMessage(
            sender: '나',
            text: '네, 바로 전달드릴게요.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isMe: true),
      ],
    ),
  ];

  List<ChatRoom> get chatRooms => _chatRooms;

  // 메시지 전송 (더미 로직)
  void sendMessage(String roomId, String text, String senderName) {
    final room = _chatRooms.firstWhere((r) => r.id == roomId);
    final isMe = senderName == '나';

    final newMessage = ChatMessage(
      sender: senderName,
      text: text,
      timestamp: DateTime.now(),
      isMe: isMe,
    );

    room.messages.add(newMessage);

    // 채팅방 목록 업데이트 (최신 메시지와 시간)
    final updatedRoom = ChatRoom(
      id: room.id,
      partnerName: room.partnerName,
      lastMessage: text,
      lastTime: DateTime.now(),
      messages: room.messages,
    );

    _chatRooms.removeWhere((r) => r.id == roomId);
    _chatRooms.insert(0, updatedRoom); // 최신 메시지 방을 맨 위로

    notifyListeners();
  }

  // 특정 방의 메시지를 가져오는 함수
  List<ChatMessage> getMessagesForRoom(String roomId) {
    return _chatRooms.firstWhere((r) => r.id == roomId).messages;
  }
}