import 'package:flutter/material.dart';
import 'package:helloworld/room_screen.dart';
import 'agency_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoomScreen(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1B2E),
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: const [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purpleAccent,
                        child:
                            Icon(Icons.person, size: 55, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              size: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "User",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "ID: 98765432",
                    style: TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1B2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.monetization_on,
                              color: Colors.amber, size: 22),
                          SizedBox(width: 4),
                          Text(
                            "50,000",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text("Coins",
                          style:
                              TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                  Container(height: 35, width: 1, color: Colors.white24),
                  Column(
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.diamond,
                              color: Colors.cyanAccent, size: 22),
                          SizedBox(width: 4),
                          Text(
                            "1,200",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text("Diamonds",
                          style:
                              TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1F1B2E),
              leading: const Icon(Icons.account_balance_wallet,
                  color: Colors.orangeAccent),
              title:
                  const Text("Wallet", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1F1B2E),
              leading: const Icon(Icons.military_tech, color: Colors.amber),
              title:
                  const Text("Badges", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            // የተገናኘው የኤጀንሲ ማዕከል ቁልፍ
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1F1B2E),
              leading: const Icon(Icons.groups, color: Colors.tealAccent),
              title: const Text("Agency Center",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("የኤጀንሲ አስተዳደር እና ሆስቶች",
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.white54),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AgencyCenterPage()));
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1F1B2E),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Log Out",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
