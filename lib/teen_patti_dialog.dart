import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'services/socket_service.dart';

class TeenPattiDialog extends StatefulWidget {
  final VoidCallback? onBalanceUpdated;

  const TeenPattiDialog({Key? key, this.onBalanceUpdated}) : super(key: key);

  static void show(BuildContext context, {VoidCallback? onBalanceUpdated}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TeenPattiDialog(onBalanceUpdated: onBalanceUpdated),
    );
  }

  @override
  State<TeenPattiDialog> createState() => _TeenPattiDialogState();
}

class _TeenPattiDialogState extends State<TeenPattiDialog> {
  final UserService _user = UserService();
  final SocketService _socket = SocketService();

  int _roundId = 1;
  String _gameState = 'betting'; // 'betting' | 'revealing' | 'settling'
  int _timeLeft = 15;
  int _totalBetsA = 0;
  int _totalBetsB = 0;
  int _selectedBetChip = 100;
  String? _mySelectedSide;
  Map<String, dynamic>? _lastResult;

  final List<int> _chipOptions = [50, 100, 500, 1000, 5000];

  @override
  void initState() {
    super.initState();
    _initGameListeners();
  }

  void _initGameListeners() {
    _socket.socket?.emit('teen_patti_join');

    _socket.socket?.on('teen_patti_state', (data) {
      if (!mounted || data == null) return;
      setState(() {
        _roundId = data['roundId'] ?? _roundId;
        _gameState = data['gameState'] ?? _gameState;
        _timeLeft = data['timeLeft'] ?? _timeLeft;
        _totalBetsA = data['totalBetsA'] ?? 0;
        _totalBetsB = data['totalBetsB'] ?? 0;
        _lastResult = data['lastResult'];
      });
    });

    _socket.socket?.on('teen_patti_timer', (data) {
      if (!mounted || data == null) return;
      setState(() {
        _roundId = data['roundId'] ?? _roundId;
        _gameState = data['gameState'] ?? _gameState;
        _timeLeft = data['timeLeft'] ?? _timeLeft;
        _totalBetsA = data['totalBetsA'] ?? _totalBetsA;
        _totalBetsB = data['totalBetsB'] ?? _totalBetsB;
        if (data['lastResult'] != null) {
          _lastResult = data['lastResult'];
        }
      });
    });

    _socket.socket?.on('teen_patti_new_round', (data) {
      if (!mounted) return;
      setState(() {
        _roundId = data['roundId'] ?? (_roundId + 1);
        _gameState = 'betting';
        _timeLeft = data['timeLeft'] ?? 15;
        _totalBetsA = 0;
        _totalBetsB = 0;
        _mySelectedSide = null;
        _lastResult = null;
      });
    });

    _socket.socket?.on('teen_patti_bet_success', (data) {
      if (!mounted || data == null) return;
      setState(() {
        _user.coins = data['remainingCoins'] ?? _user.coins;
      });
      if (widget.onBalanceUpdated != null) widget.onBalanceUpdated!();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bet placed on ${data['side'].toString().toUpperCase()} (${data['amount']} Coins)'),
          backgroundColor: const Color(0xFF00C9A7),
          duration: const Duration(seconds: 1),
        ),
      );
    });

    _socket.socket?.on('teen_patti_result', (data) {
      if (!mounted || data == null) return;
      setState(() {
        _lastResult = data['result'];
      });

      final List winners = data['winners'] ?? [];
      final myWin = winners.firstWhere(
        (w) => w['userId']?.toString() == _user.userId,
        orElse: () => null,
      );

      if (myWin != null) {
        final winAmount = myWin['winCoins'];
        _user.coins += (winAmount as int);
        if (widget.onBalanceUpdated != null) widget.onBalanceUpdated!();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You won $winAmount Coins in Teen Patti!'),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

_socket.socket?.on('teen_patti_error', (data) {
      if (!mounted || data == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Game Error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  void _placeBet(String side) {
    if (_gameState != 'betting') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Betting is closed! Wait for next round.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_user.coins < _selectedBetChip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient coins! Please recharge.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _mySelectedSide = side);

    _socket.socket?.emit('teen_patti_place_bet', {
      'userId': _user.userId,
      'side': side,
      'amount': _selectedBetChip,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: Color(0xFF141724),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.style, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Teen Patti (Round #$_roundId)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gameState == 'betting' ? const Color(0xFF00C9A7).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gameState == 'betting' ? const Color(0xFF00C9A7) : Colors.redAccent,
                    ),
                  ),
                  child: Text(
                    _gameState == 'betting' ? '⏱ ${_timeLeft}s Bet' : '🃏 Revealing...',
                    style: TextStyle(
                      color: _gameState == 'betting' ? const Color(0xFF00C9A7) : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(child: _buildBettingSideCard('PLAYER A', 'playerA', _totalBetsA, Colors.blueAccent)),

const SizedBox(width: 10),
                  Expanded(child: _buildBettingSideCard('PLAYER B', 'playerB', _totalBetsB, Colors.pinkAccent)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_user.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Payout: 1.95x',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _chipOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final chip = _chipOptions[idx];
                final isSelected = (_selectedBetChip == chip);
                return GestureDetector(
                  onTap: () => setState(() => _selectedBetChip = chip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF6C5CE7)])
                          : null,
                      color: isSelected ? null : const Color(0xFF1E2235),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$chip',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBettingSideCard(String title, String sideKey, int totalBets, Color accentColor) {
    final bool isWinner = (_lastResult != null && _lastResult!['winner'] == sideKey);
    final bool isSelected = (_mySelectedSide == sideKey);

    final List cards = (_lastResult != null && _lastResult![sideKey] != null)
        ? (_lastResult![sideKey]['cards'] ?? [])
        : [];
    final String handType = (_lastResult != null && _lastResult![sideKey] != null)
        ? (_lastResult![sideKey]['evaluation']?['type'] ?? '')
        : '';

    return GestureDetector(
      onTap: () => _placeBet(sideKey),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E2E),
          borderRadius: BorderRadius.circular(18),

border: Border.all(
            color: isWinner
                ? Colors.amber
                : (isSelected ? accentColor : Colors.white10),
            width: isWinner ? 2.5 : (isSelected ? 2 : 1),
          ),
          boxShadow: isWinner
              ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (isWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'WINNER',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bets: $totalBets 🪙',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cards.isNotEmpty
                  ? cards.map((c) => _buildPlayingCard(c['label'], c['suit'])).toList()
                  : [
                      _buildCardBack(),
                      const SizedBox(width: 4),
                      _buildCardBack(),
                      const SizedBox(width: 4),
                      _buildCardBack(),
                    ],
            ),
            const Spacer(),
            if (handType.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  handType,
                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                isSelected ? 'Bet Active' : 'Bet Here',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingCard(String label, String suit) {
    final bool isRed = suit == '♥' || suit == '♦';
    return Container(
      width: 38,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(

label,
            style: TextStyle(
              color: isRed ? Colors.red : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            suit,
            style: TextStyle(
              color: isRed ? Colors.red : Colors.black,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 38,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.6), width: 1),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.style, color: Colors.amber, size: 16),
    );
  }
}
