import 'package:flutter/material.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // የኮይን ጥቅሎች ዝርዝር
    final packages = [
      {'coins': '100', 'price': '\$0.99', 'bonus': '+0'},
      {'coins': '500', 'price': '\$4.99', 'bonus': '+50'},
      {'coins': '1000', 'price': '\$9.99', 'bonus': '+150'},
      {'coins': '5000', 'price': '\$49.99', 'bonus': '+1000'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF13141C),
      appBar: AppBar(
        title: const Text('ኮይን ሪቻርጅ', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1F2E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "የእርስዎ ቀሪ ሂሳብ፡ 0 ኮይን",
              style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final pkg = packages[index];
                  return InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('የ ${pkg['price']} ክፍያ ሂደት ተጀምሯል...')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF222436),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                              const SizedBox(width: 5),
                              Text(
                                pkg['coins']!,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (pkg['bonus'] != '+0') ...[
                            const SizedBox(height: 4),
                            Text(
                              'ቦነስ ${pkg['bonus']}',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              pkg['price']!,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),

),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
