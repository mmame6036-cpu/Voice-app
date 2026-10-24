import 'dart:async';
import 'package:flutter/material.dart';
import 'live_audio_room_screen.dart';

class StartLiveScreen extends StatefulWidget {
  const StartLiveScreen({Key? key}) : super(key: key);

  @override
  State<StartLiveScreen> createState() => _StartLiveScreenState();
}

class _StartLiveScreenState extends State<StartLiveScreen> {
  int _currentStep = 0; // 0: Policy, 1: Face Check, 2: Room Info, 3: Beautify
  int _countdown = 4;
  Timer? _timer;
  bool _canAgree = false;

  final TextEditingController _titleController =
      TextEditingController(text: 'Habesha Voice Lounge 🎙️');
  String _selectedTag = 'Chat';
  String _selectedTheme = 'Purple Sunset';

  final List<String> _tags = ['Chat', 'Music', 'Friendly', 'Game', 'Ethiopia'];
  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'Purple Sunset',
      'colors': [const Color(0xFF6366F1), const Color(0xFFA855F7)]
    },
    {
      'name': 'Ocean Chill',
      'colors': [const Color(0xFF0284C7), const Color(0xFF06B6D4)]
    },
    {
      'name': 'Golden Flame',
      'colors': [const Color(0xFFD97706), const Color(0xFFDC2626)]
    },
    {
      'name': 'Emerald Forest',
      'colors': [const Color(0xFF059669), const Color(0xFF10B981)]
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        setState(() {
          _countdown = 0;
          _canAgree = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // 4ቱንም ደረጃዎች ሲያጠናቅቅ በቀጥታ ክፍሉን ይከፍታል
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveAudioRoomScreen(
            roomTitle: _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : 'Live Room',
            channelName: 'room_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // የደረጃዎች ማሳያ (Step Progress Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2563EB)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _buildStepBody()),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'Host Terms & Guidelines';
      case 1:
        return 'Face Verification';
      case 2:
        return 'Room Details & Cover';
      case 3:
        return 'Room Beautify & Style';
      default:
        return 'Go Live';
    }
  }

Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildPolicyStep();
      case 1:
        return _buildFaceCheckStep();
      case 2:
        return _buildRoomDetailsStep();
      case 3:
        return _buildBeautifyStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ደረጃ 1፡ የ 4 ሰከንድ ማሳሰቢያ
  Widget _buildPolicyStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded,
              color: Color(0xFF2563EB), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Community & Hosting Guidelines',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Respect all guests and members at all times.\n'
            '2. Hate speech, harassment, and explicit content are strictly prohibited.\n'
            '3. Keep your live room welcoming and engaging.\n'
            '4. Accounts violating guidelines will be suspended permanently.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _canAgree
                    ? const Color(0xFF2563EB)
                    : Colors.white12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _canAgree ? _goToNextStep : null,
              child: Text(
                _canAgree ? 'I Agree & Continue' : 'Please read ($_countdown s)',
                style: TextStyle(
                  color: _canAgree ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ደረጃ 2፡ ክብ የፊት ካሜራ ማረጋገጫ
  Widget _buildFaceCheckStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2563EB), width: 3),
                  color: Colors.white.withOpacity(0.04),
                ),
                child: const Icon(Icons.face_retouching_natural_rounded,
                    color: Color(0xFF38BDF8), size: 70),
              ),
              const Positioned(
                bottom: 10,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Face Authenticated',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Host identity confirmed. You are verified to go live.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(

width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _goToNextStep,
              child: const Text('Next: Room Setup',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ደረጃ 3፡ ሽፋን ፎቶ፣ ርዕስ እና ታግ
  Widget _buildRoomDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      color: Colors.white70, size: 36),
                  SizedBox(height: 6),
                  Text('Upload Cover',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Room Title',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161B26),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              hintText: 'Enter an engaging room title...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select Category',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final isSelected = _selectedTag == tag;
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFF161B26),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedTag = tag);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _goToNextStep,
              child: const Text('Next: Choose Style',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

// ደረጃ 4፡ የክፍሉ ድባብ (Theme & Filter)
  Widget _buildBeautifyStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Visual Theme',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the 3D lighting atmosphere for your room.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: _themes.length,
              itemBuilder: (context, index) {
                final theme = _themes[index];
                final isSelected = _selectedTheme == theme['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedTheme = theme['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: theme['colors'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          theme['name'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: _goToNextStep,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Start Live Room Now 🚀',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
