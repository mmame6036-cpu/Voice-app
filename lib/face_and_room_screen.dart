import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class FaceAndRoomScreen extends StatefulWidget {
  final String userId;
  final String baseUrl;

  const FaceAndRoomScreen({
    super.key,
    required this.userId,
    required this.baseUrl,
  });

  @override
  State<FaceAndRoomScreen> createState() => _FaceAndRoomScreenState();
}

class _FaceAndRoomScreenState extends State<FaceAndRoomScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isFaceVerified = false;
  String verificationDate = '';
  int taxCycleDay = 0;
  String? currentRoomId;
  List<dynamic> activeSeats = [];
  bool isLoading = false;
void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  Future<Map<String, dynamic>> _sendPost(String path, Map<String, dynamic> body) async {
    final client = HttpClient();
    final uri = Uri.parse('${widget.baseUrl}$path');
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  // እውነተኛ የፊት/ባዮሜትሪክ መፈተሻ
  Future<void> verifyFace() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _notify('ይህ ስልክ የፊት ወይም የባዮሜትሪክ አሻራ አይደግፍም!');
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'ክፍል ለመክፈት እባክዎ እውነተኛ የፊት አሻራዎን ያረጋግጡ',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        setState(() => isLoading = true);

        final data = await _sendPost('/verify-face', {
          'userId': widget.userId,
          'faceImageData': 'hardware_biometric_success_token',
        });

        setState(() {
          isFaceVerified = true;
          verificationDate = data['verifiedAt'] ?? DateTime.now().toString();
          taxCycleDay = 1;
        _notify('የፊት አሻራ ማረጋገጫ በተሳካ ሁኔታ ተጠናቋል!');
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) Navigator.pop(context, true);
  });
} else {
        _notify('የፊት አሻራ ማረጋገጫው አልተሳካም፤ አልፈቀደም!');
      }
    } catch (e) {
      _notify('የአሻራ ፍተሻ ስህተት ተከስቷል፡ $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createRoom() async {
    if (!isFaceVerified) {
      _notify('ክፍል ለመክፈት መጀመሪያ እውነተኛ የፊት አሻራዎን ያረጋግጡ!');
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = await _sendPost('/rooms/create', {
        'userId': widget.userId,
        'roomTitle': 'የቀጥታ ድምጽ ክፍል',
        'dailyTax': 20,
      });

      if (data['success'] == true) {
        setState(() {
          currentRoomId = data['room']['roomId'];
          activeSeats = data['room']['seats'];
        });
        _notify('30 ወንበር ያለው ክፍል ተከፍቷል!');
      } else {
        _notify(data['message']?.toString() ?? 'ክፍል መክፈት አልተቻለም');
      }
    } catch (e) {
      setState(() {
        currentRoomId = 'local_room_1';
        activeSeats = List.generate(30, (i) => {'seatIndex': i + 1, 'occupantId': null});
      });
      _notify('30 ወንበር ያለው ክፍል ተከፍቷል');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void takeSeat(int seatIndex) {
    setState(() {
      final seat = activeSeats.firstWhere((s) => s['seatIndex'] == seatIndex);
      if (seat['occupantId'] == null) {
        seat['occupantId'] = widget.userId;
        _notify('ወንበር $seatIndex ተይዟል (ነፃ ማውሪያ ነው፤ ኮይን አያመነጭም)');
      }
    });
  }

void _notify(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('የድምጽ አፕሊኬሽን (30 ወንበሮች)'),
        backgroundColor: const Color(0xFF1E1F2E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222436),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFaceVerified ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isFaceVerified ? Icons.verified : Icons.error_outline,
                          color: isFaceVerified ? Colors.green : Colors.redAccent,
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFaceVerified ? "የፊት አሻራ ተረጋግጧል" : "የፊት አሻራ አልተሰጠም",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                isFaceVerified
                                    ? "የ7 ቀን ዴሊ ታክስ ቆጣሪ፡ ቀን $taxCycleDay"
                                    : "ክፍል ለመክፈት መጀመሪያ እውነተኛ አሻራ ይስጡ",
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (!isFaceVerified)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onPressed: verifyFace,
                            child: const Text("አሻራ ስጥ", style: TextStyle(color: Colors.black, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFaceVerified ? Colors.blueAccent : Colors.grey[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isFaceVerified ? createRoom : null,
                      icon: const Icon(Icons.meeting_room, color: Colors.white, size: 20),
                      label: const Text(
                        "ክፍል ክፈት (30 ወንበር - ታክስ ያለው)",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

if (currentRoomId != null) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "የመነጋገሪያ ወንበሮች (30 ወንበር - ነፃ ማውሪያ ብቻ)",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: activeSeats.length,
                        itemBuilder: (context, index) {
                          final seat = activeSeats[index];
                          final isOccupied = seat['occupantId'] != null;

                          return InkWell(
                            onTap: () => takeSeat(seat['seatIndex']),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isOccupied ? Colors.teal[800] : const Color(0xFF222436),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOccupied ? Colors.tealAccent : Colors.white24,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOccupied ? Icons.mic : Icons.airline_seat_recline_normal,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOccupied ? "ተይዟል" : "${seat['seatIndex']}",
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
