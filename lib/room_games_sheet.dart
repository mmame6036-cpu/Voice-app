import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'main.dart';

class RoomGamesSheet extends StatefulWidget {
  final dynamic socket;
  final VoidCallback onCoinsChanged;

  const RoomGamesSheet({Key? key, this.socket, required this.onCoinsChanged}) : super(key: key);

  static void show(BuildContext context, {dynamic socket, required VoidCallback onCoinsChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoomGamesSheet(socket: socket, onCoinsChanged: onCoinsChanged),
    );
  }

  @override
  State<RoomGamesSheet> createState() => _RoomGamesSheetState();
}

class _RoomGamesSheetState extends State<RoomGamesSheet> {
  String? activeGameUrl;
  String? activeGameTitle;
  WebViewController? _webViewController;
  bool isLoading = true;

  // በክፍሉ ውስጥ የሚጫወቱት እውነተኛ የ HTML5 ጌሞች ዝርዝር
  final List<Map<String, dynamic>> gamesList = const [
    {
      'title': 'Fruit Party',
      'icon': Icons.fastfood_rounded,
      'color': Colors.orangeAccent,
      'url': 'https://html5.gamedistribution.com/b4955b253b3b4aa58fa6c91a7837053e/',
    },
    {
      'title': 'Chicken Road',
      'icon': Icons.egg_rounded,
      'color': Colors.amber,
      'url': 'https://html5.gamedistribution.com/6c66ff97fbc54d5885065c71a399652a/',
    },
    {
      'title': 'Ocean Hunt',
      'icon': Icons.water_drop_rounded,
      'color': Colors.blueAccent,
      'url': 'https://html5.gamedistribution.com/95648f80479148d4888be65cf80efd12/',
    },
    {
      'title': 'GaroGems',
      'icon': Icons.diamond_rounded,
      'color': Colors.purpleAccent,
      'url': 'https://html5.gamedistribution.com/bce33e6dae984f48a6042971a8ea9a4e/',
    },
  ];

  void _loadGame(String title, String url) {
    setState(() {
      activeGameTitle = title;
      activeGameUrl = url;
      isLoading = true;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF0F111D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // የላይኛው መጎተቻና ራስጌ
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (activeGameUrl != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => setState(() {
                      activeGameUrl = null;
                      activeGameTitle = null;
                    }),
                  )
                else
                  const SizedBox(width: 32),
                Text(
                  activeGameTitle ?? 'Room Games',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),

Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${AppData.userCoins}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // የጨዋታው ሜዳ (WebView) ወይም የካርዶች ምርጫ
          Expanded(
            child: activeGameUrl == null
                ? _buildGameSelectionGrid()
                : Stack(
                    children: [
                      if (_webViewController != null)
                        WebViewWidget(controller: _webViewController!),
                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSelectionGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: gamesList.length,
      itemBuilder: (context, idx) {
        final g = gamesList[idx];
        return GestureDetector(
          onTap: () => _loadGame(g['title'], g['url']),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (g['color'] as Color).withOpacity(0.35),
                  Colors.white.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (g['color'] as Color).withOpacity(0.6), width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(g['icon'] as IconData, color: g['color'] as Color, size: 42),
                const SizedBox(height: 10),
                Text(
                  g['title'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PLAY NOW',
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
