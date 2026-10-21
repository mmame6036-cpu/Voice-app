// services/teenPattiSocket.js
const { dealTeenPattiRound } = require('./teenPattiEngine');
const mongoose = require('mongoose');

let ioInstance = null;
let currentRoundId = 1;
let gameState = 'betting'; // 'betting' | 'revealing' | 'settling'
let timeLeft = 15;
let currentBets = []; // { userId, side: 'playerA'|'playerB'|'tie', amount }

function startTeenPattiManager(io) {
  ioInstance = io;

  setInterval(() => {
    timeLeft--;

    if (timeLeft <= 0) {
      if (gameState === 'betting') {
        gameState = 'revealing';
        timeLeft = 6;
        resolveRound();
      } else if (gameState === 'revealing') {
        gameState = 'settling';
        timeLeft = 4;
      } else {
        // Start new round
        currentRoundId++;
        currentBets = [];
        gameState = 'betting';
        timeLeft = 15;

        ioInstance.emit('teen_patti_new_round', {
          roundId: currentRoundId,
          timeLeft,
        });
      }
    }

    ioInstance.emit('teen_patti_timer', {
      roundId: currentRoundId,
      gameState,
      timeLeft,
      totalBetsA: currentBets.filter(b => b.side === 'playerA').reduce((s, b) => s + b.amount, 0),
      totalBetsB: currentBets.filter(b => b.side === 'playerB').reduce((s, b) => s + b.amount, 0),
    });
  }, 1000);

  io.on('connection', (socket) => {
    // ተጠቃሚው ወደ ጌሙ ሲገባ ያለውን ሁኔታ መላክ
    socket.on('teen_patti_join', () => {
      socket.emit('teen_patti_state', {
        roundId: currentRoundId,
        gameState,
        timeLeft,
      });
    });

    // ተጠቃሚ ውርርድ ሲያስይዝ
    socket.on('teen_patti_place_bet', async (data) => {
      try {
        const { userId, side, amount } = data;
        if (gameState !== 'betting') {
          return socket.emit('teen_patti_error', { message: 'Betting is closed for this round!' });
        }

        const betAmount = parseInt(amount, 10);
        if (!betAmount || betAmount <= 0) {
          return socket.emit('teen_patti_error', { message: 'Invalid bet amount' });
        }

        const User = mongoose.models.User;
        const Transaction = mongoose.models.Transaction;

        const user = await User.findOne({ userId: String(userId) });
        if (!user || user.coins < betAmount) {
          return socket.emit('teen_patti_error', { message: 'Insufficient coins balance' });
        }

        // ሳንቲም መቀነስ
        user.coins -= betAmount;
        await user.save();

        if (Transaction) {
          await Transaction.create({
            userId: user.userId,
            type: 'game_bet',
            amount: -betAmount,
            balanceAfter: user.coins,
            description: Teen Patti bet on ${side} (Round #${currentRoundId})
          });
        }

        currentBets.push({ userId: String(userId), side, amount: betAmount });

        socket.emit('teen_patti_bet_success', {
          roundId: currentRoundId,
          side,
          amount: betAmount,
          remainingCoins: user.coins
        });
      } catch (err) {
        socket.emit('teen_patti_error', { message: err.message });
      }
    });
  });
}

async function resolveRound() {
  const result = dealTeenPattiRound();
  const User = mongoose.models.User;
  const Transaction = mongoose.models.Transaction;

  const winners = [];

  for (const bet of currentBets) {
    if (bet.side === result.winner) {
      // 1.9x payout (5% house edge)
      const winCoins = Math.floor(bet.amount * 1.95);
      winners.push({ userId: bet.userId, winCoins });

      if (User) {
        const u = await User.findOneAndUpdate(
          { userId: bet.userId },
          { $inc: { coins: winCoins } },
          { new: true }
        );

        if (Transaction && u) {
          await Transaction.create({
            userId: u.userId,
            type: 'game_win',
            amount: winCoins,
            balanceAfter: u.coins,
            description: Teen Patti Win (Round #${currentRoundId})
          });
        }
      }
    }
  }

  ioInstance.emit('teen_patti_result', {
    roundId: currentRoundId,
    result,
    winners,
  });
}

module.exports = { startTeenPattiManager };
