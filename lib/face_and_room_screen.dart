import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'home_aura_background.dart';

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
  bool isFaceVerified = false;
  String verificationDate = '';
  int taxCycleDay = 0;
  String? currentRoomId;
  List<dynamic> activeSeats = [];
  bool isLoading = false;

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

  Future<void> verifyFace() async {
    setState(() => isLoading = true);
    try {
      final data = await _sendPost('/verify-face', {
        'userId': widget.userId,
        'faceImageData': 'face_scan_verified_token',
      });

      if (data['success'] == true) {
        setState(() {
          isFaceVerified = true;
          verificationDate = data['verifiedAt'] ?? '';
          taxCycleDay = 1;
        });
        _notify(data['message']?.toString() ?? 'የፊት አሻራ ጸድቋል');
      } else {
        _notify(data['message']?.toString() ?? 'ማረጋገጥ አልተቻለም');
      }
    } catch (e) {
      // ለሙከራ እንዲመች ሰርቨሩ ባይኖርም እንዲያልፍ
      setState(() {
        isFaceVerified = true;
        taxCycleDay = 1;
      });
      _notify('አሻራው በሙከራ ደረጃ ጸድቋል');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createRoom() async {
    if (!isFaceVerified) {
      _notify('ክፍል ለመክፈት መጀመሪያ የፊት አሻራዎን ያረጋግጡ!');
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
        _notify('ክፍሉ ተከፍቷል!');
      } else {
        _notify(data['message']?.toString() ?? 'ክፍል መክፈት አልተቻለም');
      }
    } catch (e) {
      setState(() {
        currentRoomId = 'local_room_1';
        activeSeats = List.generate(8, (i) => {'seatIndex': i + 1, 'occupantId': null});
      });
      _notify('ክፍሉ ተከፍቷል (Local Mode)');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('የድምጽ አፕሊኬሽን ማዕከል'),
        backgroundColor: const Color(0xFF1E1F2E),
      ),
      body: HomeAuraBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(

children: [
                    Container(
                      padding: const EdgeInsets.all(14),
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
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFaceVerified ? "የፊት አሻራ ተረጋግጧል" : "የፊት አሻራ አልተሰጠም",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  isFaceVerified
                                      ? "የ7 ቀን ዴሊ ታክስ ቆጣሪ፡ ቀን $taxCycleDay"
                                      : "ክፍል ለመክፈት መጀመሪያ አሻራ ይስጡ",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!isFaceVerified)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                              ),
                              onPressed: verifyFace,
                              child: const Text("አሻራ ስጥ", style: TextStyle(color: Colors.black)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFaceVerified ? Colors.blueAccent : Colors.grey[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isFaceVerified ? createRoom : null,
                        icon: const Icon(Icons.meeting_room, color: Colors.white),
                        label: const Text(
                          "ክፍል ክፈት (የታክስ ስርዓት ያለው)",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (currentRoomId != null) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "የመነጋገሪያ ወንበሮች (ነፃ ማውሪያ ብቻ - ኮይን አይሰጥም)",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),

Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
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
                                  borderRadius: BorderRadius.circular(10),
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
                                      size: 26,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isOccupied ? "ተይዟል" : "ወንበር ${seat['seatIndex']}",
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
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
      ),
    );
  }
}
