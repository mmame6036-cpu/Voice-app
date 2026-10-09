import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'user_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  Function(Map<String, dynamic>)? onChairActionReceived;
  Function(Map<String, dynamic>)? onChatMessageReceived;

  void connect() {
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      UserService.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      isConnected = true;
      debugPrint('Socket Connected Successfully');
    });

    socket?.onDisconnect((_) {
      isConnected = false;
      debugPrint('Socket Disconnected');
    });

    // Seat events listener
    socket?.on('chair_action', (data) {
      if (data != null && onChairActionReceived != null) {
        if (data is Map<String, dynamic>) {
          onChairActionReceived!(data);
        } else if (data is Map) {
          onChairActionReceived!(Map<String, dynamic>.from(data));
        }
      }
    });

    // Chat message listener
    socket?.on('chat_message', (data) {
      if (data != null && onChatMessageReceived != null) {
        if (data is Map<String, dynamic>) {
          onChatMessageReceived!(data);
        } else if (data is Map) {
          onChatMessageReceived!(Map<String, dynamic>.from(data));
        }
      }
    });

    // Fallback broadcast listener
    socket?.on('message', (data) {
      if (data != null && onChatMessageReceived != null) {
        if (data is Map<String, dynamic>) {
          onChatMessageReceived!(data);
        } else if (data is Map) {
          onChatMessageReceived!(Map<String, dynamic>.from(data));
        }
      }
    });
  }

  void joinRoom(String roomId) {
    if (socket == null || !socket!.connected) {
      connect();
    }
    socket?.emit('join_room', roomId);
    socket?.emit('join', roomId);
  }

  void sendChairAction({
    required String roomId,
    required int chairIndex,
    required String action,
  }) {
    final user = UserService();
    final payload = {
      'room': roomId,
      'roomId': roomId,
      'chairIndex': chairIndex,
      'userName': user.userName,
      'userId': user.userId,
      'action': action,
    };
    socket?.emit('chair_action', payload);
  }

  void sendChatMessage({
    required String roomId,
    required String text,
  }) {
    final user = UserService();
    final payload = {
      'room': roomId,
      'roomId': roomId,
      'sender': user.userName,
      'userId': user.userId,
      'text': text,
    };
    socket?.emit('chat_message', payload);
    socket?.emit('message', payload);
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;
  }
}
