import 'package:flutter/material.dart';

class RoomSessionManager extends ChangeNotifier {
  RoomSessionManager._();
  static final RoomSessionManager instance = RoomSessionManager._();

  bool hasActiveRoom = false;
  bool isMinimized = false;
  String roomId = "";
  String roomTitle = "";
  bool isMuted = false;

  VoidCallback? onExpand;
  Future<void> Function()? onLeaveRoom;
  Future<void> Function(bool mute)? onToggleMute;

  void registerActiveRoom({
    required String id,
    required String title,
    required bool muted,
    required VoidCallback expandCallback,
    required Future<void> Function() leaveCallback,
    required Future<void> Function(bool mute) muteCallback,
  }) {
    hasActiveRoom = true;
    isMinimized = false;
    roomId = id;
    roomTitle = title;
    isMuted = muted;
    onExpand = expandCallback;
    onLeaveRoom = leaveCallback;
    onToggleMute = muteCallback;
    notifyListeners();
  }

  void minimizeRoom() {
    if (!hasActiveRoom) return;
    isMinimized = true;
    notifyListeners();
  }

  void expandRoom() {
    if (!hasActiveRoom) return;
    isMinimized = false;
    notifyListeners();
    final cb = onExpand;
    if (cb != null) {
      cb();
    }
  }

  void updateMuteState(bool muted) {
    isMuted = muted;
    notifyListeners();
  }

  Future<void> closeMinimizedRoom() async {
    final leaveCb = onLeaveRoom;
    hasActiveRoom = false;
    isMinimized = false;
    roomId = "";
    roomTitle = "";
    onExpand = null;
    onLeaveRoom = null;
    onToggleMute = null;
    notifyListeners();
    if (leaveCb != null) {
      await leaveCb();
    }
  }

  void clearSessionOnly() {
    hasActiveRoom = false;
    isMinimized = false;
    roomId = "";
    roomTitle = "";
    onExpand = null;
    onLeaveRoom = null;
    onToggleMute = null;
    notifyListeners();
  }
}

class FloatingRoomOverlay extends StatefulWidget {
  final Widget child;
  const FloatingRoomOverlay({super.key, required this.child});

  @override
  State<FloatingRoomOverlay> createState() => _FloatingRoomOverlayState();
}

class _FloatingRoomOverlayState extends State<FloatingRoomOverlay> {
  double _rightOffset = 14.0;
  double _bottomOffset = 95.0;

  @override
  Widget build(BuildContext context) {
    final mgr = RoomSessionManager.instance;
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: mgr,
          builder: (context, _) {
            if (!mgr.hasActiveRoom) return const SizedBox.shrink();
            if (!mgr.isMinimized) return const SizedBox.shrink();

            final size = MediaQuery.of(context).size;
            return Positioned(
              right: _rightOffset.clamp(8.0, size.width - 210.0),
              bottom: _bottomOffset.clamp(60.0, size.height - 120.0),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rightOffset -= details.delta.dx;
                    _bottomOffset -= details.delta.dy;
                  });
                },
                onTap: () => mgr.expandRoom(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 205,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B1D14), Color(0xFF140D09)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFFFD700),

width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF107C41),
                          ),
                          child: const Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mgr.roomTitle.isNotEmpty
                                    ? mgr.roomTitle
                                    : "Voice Room",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "● Audio: Live",
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final nextMute = !mgr.isMuted;
                            mgr.updateMuteState(nextMute);
                            final toggleCb = mgr.onToggleMute;
                            if (toggleCb != null) {
                              await toggleCb(nextMute);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              mgr.isMuted ? Icons.mic_off : Icons.mic,
                              color: mgr.isMuted
                                  ? Colors.redAccent
                                  : const Color(0xFFFFD700),
                              size: 18,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => mgr.closeMinimizedRoom(),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.white12,
                            child: Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
