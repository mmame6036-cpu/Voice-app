import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaceAndRoomScreen extends StatefulWidget {
  final String userId;
  final String baseUrl; // ለምሳሌ፡ 'http://YOUR_SERVER_IP:3000/api'

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

  // 1. የፊት አሻራ መላኪያ እና ማረጋገጫ
  Future<void> verifyFace() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/verify-face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'faceImageData': 'face_scan_verified_token',
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          isFaceVerified = true;
          verificationDate = data['verifiedAt'] ?? '';
          taxCycleDay = 1;
        });
        _notify(data['message']);
      } else {
        _notify(data['message'] ?? 'ማረጋገጥ አልተቻለም');
      }
    } catch (e) {
      _notify('የሰርቨር ግንኙነት ስህተት ተፈጥሯል');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. ክፍል መክፈቻ (አሻራውን አረጋግጦ)
  Future<void> createRoom() async {
    if (!isFaceVerified) {
      _notify('ክፍል ለመክፈት መጀመሪያ የፊት አሻራዎን ያረጋግጡ!');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/rooms/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'roomTitle': 'የቀጥታ ድምጽ ክፍል',
          'dailyTax': 20,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          currentRoomId = data['room']['roomId'];
          activeSeats = data['room']['seats'];
        });
        _notify('ክፍሉ ተከፍቷል! የ7 ቀን ታክስ ቆጣሪ በስራ ላይ ነው');
      } else {
        _notify(data['message'] ?? 'ክፍል መክፈት አልተቻለም');
      }
    } catch (e) {
      _notify('የክፍል መክፈቻ ጥሪ አልተሳካም');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 3. ነፃ ወንበር መያዣ (ምንም ኮይን/ፖይንት አያመነጭም)
  Future<void> takeSeat(int seatIndex) async {
    if (currentRoomId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/rooms/take-seat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': currentRoomId,
          'seatIndex': seatIndex,
          'userId': widget.userId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          activeSeats = data['seats'];
        });
        _notify('ወንበር $seatIndex ተይዟል (ነፃ ማውሪያ ነው፤ ኮይን አያመነጭም)');
      } else {
        _notify(data['message'] ?? 'ወንበሩን መያዝ አልተቻለም');
      }
    } catch (e) {
      _notify('የወንበር ጥሪ አልተሳካም');
    }
  }

  void _notify(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('የድምጽ አፕሊኬሽን ማዕከል'),
        backgroundColor: const Color(0xFF1E1F2E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(

padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ካርድ 1፡ የፊት አሻራ ሁኔታ እና የ7 ቀን ቆጣሪ
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

                  // ቁልፍ 2፡ ክፍል መክፈቻ (አሻራ ከሌለ ይቆለፋል)
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

                  // ክፍል 3፡ ክፍሉ ሲከፈት የሚታዩ 8ቱ ወንበሮች
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
    );
  }
}
