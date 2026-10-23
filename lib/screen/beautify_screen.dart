import 'package:flutter/material.dart';

class BeautifyScreen extends StatefulWidget {
  final String roomTitle;
  const BeautifyScreen({Key? key, this.roomTitle = 'My Voice Room'}) : super(key: key);

  @override
  State<BeautifyScreen> createState() => _BeautifyScreenState();
}

class _BeautifyScreenState extends State<BeautifyScreen> {
  int _selectedThemeIndex = 0;

  final List<Map<String, dynamic>> _themes = [
    {'name': 'Party Night', 'color': const Color(0xFF6366F1), 'icon': Icons.celebration},
    {'name': 'Chill & Relax', 'color': const Color(0xFF0EA5E9), 'icon': Icons.nightlight_round},
    {'name': 'Romantic', 'color': const Color(0xFFEC4899), 'icon': Icons.favorite},
    {'name': 'Gaming', 'color': const Color(0xFF8B5CF6), 'icon': Icons.sports_esports},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Start live',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // የማሳሰቢያ ባነር
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '3 Steps to Going Live - Make Money Daily!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEA580C),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 3ቱ ደረጃዎች (ደረጃ 3 ላይ ደርሰናል)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepItem(1, 'Verification', isDone: true, isActive: false),
                _buildStepDivider(isActive: true),
                _buildStepItem(2, 'Upload Cover', isDone: true, isActive: false),
                _buildStepDivider(isActive: true),
                _buildStepItem(3, 'Beautify', isDone: false, isActive: true),
              ],
            ),

            const SizedBox(height: 35),

            // የተመረጠው የክፍል ቅድመ-እይታ ካርድ (Room Theme Preview)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _themes[_selectedThemeIndex]['color'],
                    (_themes[_selectedThemeIndex]['color'] as Color).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_themes[_selectedThemeIndex]['color'] as Color).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 15,

bottom: 15,
                    child: Icon(
                      _themes[_selectedThemeIndex]['icon'],
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE PREVIEW',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.roomTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Theme: ${_themes[_selectedThemeIndex]['name']}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Room Atmosphere',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 14),

            // የጭብጥ መምረጫ ዝርዝር (Theme Selector List)
            SizedBox(
              height: 75,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _themes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final theme = _themes[index];
                  final isSelected = _selectedThemeIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedThemeIndex = index),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme['color'].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? theme['color'] : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(theme['icon'], color: theme['color'], size: 24),
                          const SizedBox(height: 4),
                          Text(
                            theme['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(

fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme['color'] : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // ክፍሉን መክፈቻ ቁልፍ (Go Live Button)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // የማረጋገጫውን ሂደት በሙሉ ጨርሶ በቀጥታ ወደ ክፍል መግቢያ
                    Navigator.popUntil(context, (route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 የቀጥታ ድምፅ ክፍልዎ በተሳካ ሁኔታ ተከፍቷል!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go Live Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int step, String title, {required bool isDone, required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF10B981)
                : (isActive ? const Color(0xFF2563EB) : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$step',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isActive || isDone ? Colors.black87 : Colors.grey,
            fontWeight: isActive || isDone ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isActive}) {
    return Container(
      width: 45,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade300,
    );
  }
}
