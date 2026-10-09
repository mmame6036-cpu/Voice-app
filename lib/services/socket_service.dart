import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'user_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  // ክስተቶችን (Events) ለስክሪኖች ማስተላለፊያ ፈንክሽኖች
  Function(Map<String, dynamic>)? onChairActionReceived;
  Function(Map<String, dynamic>)? onChatMessageReceived;

  // ከሶኬት ጋር መገናኘት
  void connect() {
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      UserService.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      isConnected = true;
      debugPrint('Socket ተገናኝቷል');
    });

    socket?.onDisconnect((_) {
      isConnected = false;
      debugPrint('Socket ተቋርጧል');
    });

    // የወንበር ለውጥ ሲመጣ
    socket?.on('chair_action', (data) {
      if (data is Map<String, dynamic> && onChairActionReceived != null) {
        onChairActionReceived!(data);
      }
    });

    // የቻት መልዕክት ሲመጣ
    socket?.on('chat_message', (data) {
      if (data is Map<String, dynamic> && onChatMessageReceived != null) {
        onChatMessageReceived!(data);
      }
    });
  }

  // ክፍል መቀላቀል
  void joinRoom(String roomId) {
    socket?.emit('join_room', {'room': roomId});
  }

  // ወንበር መያዝ ወይም መልቀቅ
  void sendChairAction({
    required String roomId,
    required int chairIndex,
    required String action, // 'sit' ወይም 'leave'
  }) {
    final user = UserService();
    socket?.emit('chair_action', {
      'room': roomId,
      'chairIndex': chairIndex,
      'userName': user.userName,
      'userId': user.userId,
      'action': action,
    });
  }

  // የክፍል ውስጥ መልዕክት መላክ
  void sendChatMessage({
    required String roomId,
    required String text,
  }) {
    final user = UserService();
    socket?.emit('chat_message', {
      'room': roomId,
      'sender': user.userName,
      'userId': user.userId,
      'text': text,
    });
  }

  // ከሶኬት መውጣት
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;
  }
}
