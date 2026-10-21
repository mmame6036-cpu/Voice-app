// services/teenPattiEngine.js

const SUITS = ['♠', '♥', '♦', '♣'];
const VALUES = [
  { rank: 2, label: '2' },
  { rank: 3, label: '3' },
  { rank: 4, label: '4' },
  { rank: 5, label: '5' },
  { rank: 6, label: '6' },
  { rank: 7, label: '7' },
  { rank: 8, label: '8' },
  { rank: 9, label: '9' },
  { rank: 10, label: '10' },
  { rank: 11, label: 'J' },
  { rank: 12, label: 'Q' },
  { rank: 13, label: 'K' },
  { rank: 14, label: 'A' },
];

function generateDeck() {
  const deck = [];
  for (const suit of SUITS) {
    for (const val of VALUES) {
      deck.push({ suit, label: val.label, rank: val.rank });
    }
  }
  // Shuffle
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
}

// Hand Ranks:
// 6 = Trail / Set (AAA, KKK)
// 5 = Pure Sequence / Straight Flush (A-K-Q same suit)
// 4 = Sequence / Straight (A-2-3 or 10-J-Q)
// 3 = Color / Flush (same suit)
// 2 = Pair (two of same rank)
// 1 = High Card
function evaluateHand(cards) {
  const sorted = [...cards].sort((a, b) => b.rank - a.rank);
  const r = sorted.map((c) => c.rank);
  const isFlush = sorted[0].suit === sorted[1].suit && sorted[1].suit === sorted[2].suit;

  // A-2-3 special sequence handling
  const isNormalSeq = (r[0] - r[1] === 1 && r[1] - r[2] === 1);
  const isA23 = (r[0] === 14 && r[1] === 3 && r[2] === 2);
  const isSeq = isNormalSeq || isA23;

  // 1. Trail / Set
  if (r[0] === r[1] && r[1] === r[2]) {
    return { score: 6000000 + r[0], type: 'Trail', multiplier: 20 };
  }

  // 2. Pure Sequence
  if (isFlush && isSeq) {
    const seqHigh = isA23 ? 3 : r[0];
    return { score: 5000000 + seqHigh, type: 'Pure Sequence', multiplier: 10 };
  }

  // 3. Sequence
  if (isSeq) {
    const seqHigh = isA23 ? 3 : r[0];
    return { score: 4000000 + seqHigh, type: 'Sequence', multiplier: 5 };
  }

  // 4. Color / Flush
  if (isFlush) {
    return { score: 3000000 + r[0] * 10000 + r[1] * 100 + r[2], type: 'Color', multiplier: 3 };
  }

  // 5. Pair
  if (r[0] === r[1]) {
    return { score: 2000000 + r[0] * 1000 + r[2], type: 'Pair', multiplier: 2 };
  }
  if (r[1] === r[2]) {
    return { score: 2000000 + r[1] * 1000 + r[0], type: 'Pair', multiplier: 2 };
  }
  if (r[0] === r[2]) {
    return { score: 2000000 + r[0] * 1000 + r[1], type: 'Pair', multiplier: 2 };
  }

  // 6. High Card
  return { score: 1000000 + r[0] * 10000 + r[1] * 100 + r[2], type: 'High Card', multiplier: 1.9 };
}

function dealTeenPattiRound() {
  const deck = generateDeck();
  const playerA = [deck.pop(), deck.pop(), deck.pop()];
  const playerB = [deck.pop(), deck.pop(), deck.pop()];

  const evalA = evaluateHand(playerA);
  const evalB = evaluateHand(playerB);

  let winner = 'tie';
  if (evalA.score > evalB.score) {
    winner = 'playerA';
  } else if (evalB.score > evalA.score) {
    winner = 'playerB';
  }

  return {
    playerA: { cards: playerA, evaluation: evalA },
    playerB: { cards: playerB, evaluation: evalB },
    winner,
  };
}

module.exports = { dealTeenPattiRound };
