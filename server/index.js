const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const fbApp = require('firebase-admin/app');
const fbFs = require('firebase-admin/firestore');
const FV = fbFs.FieldValue;
const { RtcTokenBuilder, RtcRole } = require('agora-token');

const app = express();
app.use(cors());
app.use(express.json());

function pick(a, b, c, d) {
  const arr = [a, b, c, d];
  for (let i = 0; i < arr.length; i++) {
    if (arr[i] !== undefined && arr[i] !== null && arr[i] !== '') return arr[i];
  }
  return '';
}

let db = null;
try {
  const ps = ['/etc/secrets/serviceAccountKey.json', path.join(process.cwd(), 'serviceAccountKey.json')];
  for (let i = 0; i < ps.length; i++) {
    if (fs.existsSync(ps[i])) {
      const sa = JSON.parse(fs.readFileSync(ps[i], 'utf8'));
      if (fbApp.getApps().length === 0) fbApp.initializeApp({ credential: fbApp.cert(sa) });
      db = fbFs.getFirestore();
      console.log('Firebase Admin initialized successfully.');
      break;
    }
  }
} catch (e) { console.error('Firebase init error:', e.message); }

const APP_ID = pick(process.env.AGORA_APP_ID, process.env.AGORAApp_ID);
const APP_CERT = pick(process.env.AGORA_APP_CERTIFICATE, process.env.AGORAApp_Certificate);
const PAY_ID = pick(process.env.BINANCE_PAY_ID, '1059643208');
const mem = new Map();

// ============================================================================
// SERVER-AUTHORITATIVE DRAGON VS TIGER ENGINE (30s LIVE MULTIPLAYER CYCLE)
// ============================================================================
const DT_BET_MS = 20000;
const DT_REVEAL_MS = 5000;
const DT_SETTLE_MS = 5000;

let dtInterval = null;
let dtLastActivity = Date.now();
let dtBusy = false;

let dtState = {
  roundId: '',
  roundNumber: 0,
  phase: 'BETTING',
  roundStartTime: 0,
  roundEndTime: 0,
  revealEndTime: 0,
  nextRoundTime: 0,
  pot: { dragon: 0, tie: 0, tiger: 0 },
  totalPot: 0,
  dragonCard: null,
  tigerCard: null,
  winner: null,
  topWinners: [],
  history: []
};

function drawTwoCards() {
  const suits = ['S', 'H', 'D', 'C'];
  const deck = [];
  for (let s = 0; s < suits.length; s++) {
    for (let r = 1; r <= 13; r++) {
      deck.push({ rank: r, suit: suits[s] });
    }
  }
  for (let i = deck.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    const tmp = deck[i];
    deck[i] = deck[j];
    deck[j] = tmp;
  }
  return { dragonCard: deck[0], tigerCard: deck[1] };
}

async function syncDtStateToFirestore() {
  if (!db) return;
  try {
    await db.collection('games').doc('dragon_tiger').set({
      roundId: dtState.roundId,
      roundNumber: dtState.roundNumber,
      phase: dtState.phase,
      roundStartTime: dtState.roundStartTime,
      roundEndTime: dtState.roundEndTime,
      revealEndTime: dtState.revealEndTime,
      nextRoundTime: dtState.nextRoundTime,
      pot: dtState.pot,
      totalPot: dtState.totalPot,
      dragonCard: dtState.dragonCard,
      tigerCard: dtState.tigerCard,
      winner: dtState.winner,
      topWinners: dtState.topWinners,
      history: dtState.history,
      serverNow: Date.now()
    }, { merge: true });
  } catch (e) {
    console.error('DT sync error:', e.message);
  }
}

async function startNewDtRound() {
  const now = Date.now();
  const nextNum = dtState.roundNumber + 1;
  const roundId = 'dt_' + now + '_' + nextNum;

  dtState = {
    roundId,
    roundNumber: nextNum,
    phase: 'BETTING',
    roundStartTime: now,
    roundEndTime: now + DT_BET_MS,
    revealEndTime: now + DT_BET_MS + DT_REVEAL_MS,
    nextRoundTime: now + DT_BET_MS + DT_REVEAL_MS + DT_SETTLE_MS,
    pot: { dragon: 0, tie: 0, tiger: 0 },
    totalPot: 0,
    dragonCard: null,
    tigerCard: null,
    winner: null,
    topWinners: [],
    history: dtState.history.slice(0, 20)
  };

  await syncDtStateToFirestore();
}

async function revealDtRound() {
  const { dragonCard, tigerCard } = drawTwoCards();
  let winner = 'tie';
  let shortCode = 'Tie';
  if (dragonCard.rank > tigerCard.rank) {
    winner = 'dragon';
    shortCode = 'D';
  } else if (tigerCard.rank > dragonCard.rank) {
    winner = 'tiger';
    shortCode = 'T';
  }

  dtState.phase = 'REVEALING';
  dtState.dragonCard = dragonCard;
  dtState.tigerCard = tigerCard;
  dtState.winner = winner;
  dtState.history = [shortCode].concat(dtState.history).slice(0, 20);

  await syncDtStateToFirestore();
}

async function settleDtRound() {
  dtState.phase = 'SETTLEMENT';
  const roundId = dtState.roundId;
  const winner = dtState.winner;
  const winnersList = [];
  let totalRoundBets = dtState.totalPot;
  let totalRoundPayouts = 0;

  if (db && roundId) {
    try {
      const betsSnap = await db.collection('games').doc('dragon_tiger')
        .collection('rounds').doc(roundId).collection('bets').get();

      for (const betDoc of betsSnap.docs) {
        const uid = betDoc.id;
        let paidAmount = 0;
        let bData = betDoc.data();

        await db.runTransaction(async (t) => {
          const freshBet = await t.get(betDoc.ref);
          if (!freshBet.exists) return;
          const d = freshBet.data();
          if (d.paid === true) return;

          const dBet = Number(d.dragon || 0);
          const tBet = Number(d.tiger || 0);
          const tieBet = Number(d.tie || 0);

          let payout = 0;
          if (winner === 'dragon') payout = dBet * 2;
          else if (winner === 'tiger') payout = tBet * 2;
          else if (winner === 'tie') payout = tieBet * 22;

          t.update(betDoc.ref, {
            paid: true,
            wonAmount: payout,
            winnerSide: winner,
            settledAt: Date.now()
          });

          if (payout > 0) {
            const userRef = db.collection('users').doc(uid);
            t.set(userRef, { coins: FV.increment(payout) }, { merge: true });
          }
          paidAmount = payout;
        });

        if (paidAmount > 0) {
          totalRoundPayouts += paidAmount;
          winnersList.push({
            uid,
            name: String(bData.userName || 'Player'),
            numericId: Number(bData.numericId || 0),
            wonAmount: paidAmount
          });

          if (paidAmount >= 10000 && bData.roomId) {
            db.collection('rooms').doc(String(bData.roomId)).collection('messages').add({
              sender: 'Dragon vs Tiger',
              senderUid: 'system_dt',
              message: String(bData.userName || 'VIP') + ' won ' + paidAmount + ' coins in Dragon vs Tiger!',
              isSystem: true,
              ts: Date.now()
            }).catch(() => {});
          }
        }
      }

      winnersList.sort((a, b) => b.wonAmount - a.wonAmount);
      dtState.topWinners = winnersList.slice(0, 3);

      const netProfit = totalRoundBets - totalRoundPayouts;
      await db.collection('games').doc('dragon_tiger_stats').set({
        totalRounds: FV.increment(1),
        totalBets: FV.increment(totalRoundBets),
        totalPayouts: FV.increment(totalRoundPayouts),
        netProfit: FV.increment(netProfit),
        updatedAt: Date.now()
      }, { merge: true });
    } catch (e) {
      console.error('DT settle error:', e.message);
    }
  }

  await syncDtStateToFirestore();
}

async function dtTick() {
  if (dtBusy || !db) return;
  dtBusy = true;
  try {
    const now = Date.now();

    if (!dtState.roundId) {
      const existing = await db.collection('games').doc('dragon_tiger').get();
      if (existing.exists) {
        const d = existing.data();
        dtState.roundNumber = Number(d.roundNumber || 0);
        dtState.history = Array.isArray(d.history) ? d.history.slice(0, 20) : [];
      }
      await startNewDtRound();
      return;
    }

    if (dtState.phase === 'BETTING' && dtState.totalPot === 0 && (now - dtLastActivity > 180000)) {
      clearInterval(dtInterval);
      dtInterval = null;
      return;
    }

if (dtState.phase === 'BETTING' && now >= dtState.roundEndTime) {
      await revealDtRound();
    } else if (dtState.phase === 'REVEALING' && now >= dtState.revealEndTime) {
      await settleDtRound();
    } else if (dtState.phase === 'SETTLEMENT' && now >= dtState.nextRoundTime) {
      await startNewDtRound();
    }
  } catch (e) {
    console.error('DT tick error:', e.message);
  } finally {
    dtBusy = false;
  }
}

function ensureDtLoopRunning() {
  dtLastActivity = Date.now();
  if (!db) return;
  if (!dtInterval) {
    dtTick();
    dtInterval = setInterval(dtTick, 1000);
  }
}

// ============================================================================
// ADMIN DASHBOARD HTML
// ============================================================================
const HTML = `<!DOCTYPE html><html><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>NILE Admin</title>
<style>*{box-sizing:border-box;margin:0;padding:0;font-family:sans-serif}body{background:#F5EFEB;color:#1A1A1A;padding:10px}.top{background:#3E2723;color:#fff;padding:12px;border-radius:10px;display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}.b{padding:6px 10px;border:none;border-radius:7px;font-weight:bold;cursor:pointer;font-size:12px}.g{background:#107C41;color:#fff}.r{background:#D32F2F;color:#fff}.d{background:#4A3528;color:#fff}.y{background:#D49B42}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:8px;margin-bottom:10px}.card{background:#fff;padding:12px;border-radius:10px;border:1px solid #E2D6C5;margin-bottom:10px;overflow-x:auto}.tabs{display:flex;gap:6px;margin-bottom:10px}.tab{padding:7px 12px;border-radius:14px;background:#E8DFD8;font-weight:bold;font-size:12px;cursor:pointer}.tab.on{background:#3E2723;color:#fff}table{width:100%;border-collapse:collapse;font-size:12px;margin-top:6px}th,td{text-align:left;padding:6px;border-bottom:1px solid #EFE6DE}input{padding:7px;border-radius:7px;border:1px solid #DDD4C2;margin:3px}</style></head>
<body><div class="top"><b style="color:#D49B42">NILE Live Admin</b><div><button class="b r" onclick="rst()">Reset All 0</button> <button class="b y" onclick="load()">Refresh</button></div></div>
<p id="m" style="color:red;font-weight:bold;margin-bottom:8px"></p>
<div class="grid"><div class="card"><small>Revenue</small><h3 id="s1">$0</h3></div><div class="card"><small>Coins</small><h3 id="s2">0</h3></div><div class="card"><small>Points</small><h3 id="s3">0</h3></div><div class="card"><small>Users/Agencies</small><h3 id="s4">0/0</h3></div><div class="card"><small>DT Game Profit</small><h3 id="s5">0 Coins</h3></div></div>
<div class="tabs"><div class="tab on" onclick="tb('ord',this)">Orders</div><div class="tab" onclick="tb('wdr',this)">Withdrawals</div><div class="tab" onclick="tb('usr',this)">Users</div><div class="tab" onclick="tb('agn',this)">Agencies</div></div>
<div id="p-ord"><div class="card"><b>User Orders</b><table><thead><tr><th>Ref</th><th>ID</th><th>Coins</th><th>USD</th><th>Status</th><th>Act</th></tr></thead><tbody id="t1"></tbody></table></div>
<div class="card"><b>Seller Orders</b><table><thead><tr><th>Ref</th><th>Seller</th><th>Coins</th><th>USD</th><th>Status</th><th>Act</th></tr></thead><tbody id="t2"></tbody></table></div></div>
<div id="p-wdr" style="display:none"><div class="card"><b>Withdrawals</b><table><thead><tr><th>User</th><th>Method</th><th>Account</th><th>Pts</th><th>USD</th><th>Status</th><th>Act</th></tr></thead><tbody id="t3"></tbody></table></div></div>
<div id="p-usr" style="display:none"><div class="card"><b>Users</b><br><input id="q" placeholder="Search..." oninput="du()"><table><thead><tr><th>Name</th><th>ID</th><th>Coins</th><th>Pts</th><th>Face</th><th>Act</th></tr></thead><tbody id="t4"></tbody></table></div></div>

<div id="p-agn" style="display:none"><div class="card"><b>New Agency</b><br><input id="ai" placeholder="ID"><input id="an" placeholder="Name"><input id="ao" placeholder="Owner ID"><button class="b g" onclick="ma()">Create</button></div>
<div class="card"><b>Agencies</b><table><thead><tr><th>ID</th><th>Name</th><th>Owner</th><th>Hosts</th></tr></thead><tbody id="t5"></tbody></table></div></div>
<script>
var D={userOrders:[],sellerOrders:[],withdrawals:[],users:[],agencies:[]};
function g(i){return document.getElementById(i);}
function sv(v,d){return(v===undefined)?d:(v===null)?d:(v==='')?d:String(v);}
function nv(v){var n=Number(sv(v,'0'));return isNaN(n)?0:n;}
function tb(id,el){document.querySelectorAll('.tab').forEach(x=>x.classList.remove('on'));el.classList.add('on');['ord','wdr','usr','agn'].forEach(x=>g('p-'+x).style.display='none');g('p-'+id).style.display='block';}
async function load(){g('m').innerText='Loading...';try{var r=await fetch('/api/admin/overview');var d=await r.json();if(!r.ok){g('m').innerText=sv(d.error,'Error');return;}g('m').innerText='';D=d;g('s1').innerText='$'+nv(d.stats.totalRevenueUsd);g('s2').innerText=nv(d.stats.totalUserCoins);g('s3').innerText=nv(d.stats.totalUnpaidPoints);g('s4').innerText=nv(d.stats.totalUsers)+'/'+nv(d.stats.totalAgencies);g('s5').innerText=nv(d.stats.dtNetProfit)+' Coins';draw();}catch(e){g('m').innerText=e.message;}}
function draw(){
g('t1').innerHTML=D.userOrders.map(o=>'<tr><td>'+o.orderRef+'</td><td>'+sv(o.numericId,'-')+'</td><td>+'+nv(o.coins)+'</td><td>$'+nv(o.usdAmount)+'</td><td>'+o.status+'</td><td>'+(o.status==='PENDING'?'<button class="b g" onclick="ac(\\'/api/admin/user-order\\',\\''+o.orderRef+'\\',\\'APPROVE\\')">OK</button> <button class="b r" onclick="ac(\\'/api/admin/user-order\\',\\''+o.orderRef+'\\',\\'REJECT\\')">No</button>':'-')+'</td></tr>').join('');
g('t2').innerHTML=D.sellerOrders.map(o=>'<tr><td>'+o.orderRef+'</td><td>'+sv(o.sellerName,'-')+'</td><td>+'+nv(o.coins)+'</td><td>$'+nv(o.usdAmount)+'</td><td>'+o.status+'</td><td>'+(o.status==='PENDING'?'<button class="b g" onclick="ac(\\'/api/admin/seller-order\\',\\''+o.orderRef+'\\',\\'APPROVE\\')">OK</button> <button class="b r" onclick="ac(\\'/api/admin/seller-order\\',\\''+o.orderRef+'\\',\\'REJECT\\')">No</button>':'-')+'</td></tr>').join('');
g('t3').innerHTML=D.withdrawals.map(x=>'<tr><td>'+sv(x.userName,'Host')+'</td><td>'+sv(x.method,'')+'</td><td>'+sv(x.account,'')+'</td><td>'+nv(x.points)+'</td><td>$'+nv(x.usdAmount)+'</td><td>'+x.status+'</td><td>'+(x.status==='PENDING'?'<button class="b g" onclick="wd(\\''+x.id+'\\',\\'PAID\\')">Paid</button> <button class="b r" onclick="wd(\\''+x.id+'\\',\\'REJECT\\')">No</button>':'-')+'</td></tr>').join('');
du();
g('t5').innerHTML=D.agencies.map(a=>'<tr><td>'+sv(a.agencyId,a.id)+'</td><td>'+sv(a.name,'')+'</td><td>'+sv(a.ownerNumericId,'-')+'</td><td>'+nv(a.totalHosts)+'</td></tr>').join('');}
function du(){var q=sv(g('q').value,'').toLowerCase();g('t4').innerHTML=D.users.filter(u=>{var a=sv(u.numericId,'').indexOf(q)!==-1;var b=sv(u.name,'').toLowerCase().indexOf(q)!==-1;return a?true:b;}).slice(0,100).map(u=>'<tr><td>'+sv(u.name,'User')+'</td><td>'+sv(u.numericId,'-')+'</td><td>'+nv(u.coins)+'</td><td>'+nv(u.points)+'</td><td>'+(u.isFaceVerified?'Yes':'No')+'</td><td><button class="b y" onclick="ad(\\''+u.uid+'\\')">+Coins</button> <button class="b d" onclick="ct(\\''+u.uid+'\\',{toggleFace:true})">Face</button> <button class="b r" onclick="ct(\\''+u.uid+'\\',{toggleBan:true})">'+(u.isBanned?'Unban':'Ban')+'</button></td></tr>').join('');}
async function rst(){if(!confirm('Delete ALL test users, agencies & reset all to 0/0?'))return;g('m').innerText='Clearing everything to 0...';await fetch('/api/admin/reset-all',{method:'POST'});load();}
async function ac(u,ref,a){if(!confirm(a+'?'))return;await fetch(u,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({orderRef:ref,action:a})});load();}

async function wd(id,a){if(!confirm(a+'?'))return;await fetch('/api/admin/withdrawal',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({requestId:id,action:a})});load();}
async function ad(uid){var n=parseInt(sv(prompt('Coins:'),'0'),10);if(n)await ct(uid,{addCoins:n});}
async function ct(uid,o){await fetch('/api/admin/user-control',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(Object.assign({uid:uid},o))});load();}
async function ma(){await fetch('/api/admin/create-agency',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({agencyId:g('ai').value,agencyName:g('an').value,ownerNumericId:g('ao').value})});load();}
load();</script></body></html>`;

app.get('/', (req, res) => res.json({ status: 'NILE Live Server Running', firebaseConnected: Boolean(db), adminDashboard: '/admin' }));
app.get('/admin', (req, res) => { res.setHeader('Content-Type', 'text/html; charset=utf-8'); res.send(HTML); });

// ============================================================================
// DRAGON VS TIGER API ENDPOINTS
// ============================================================================
app.all(['/api/game/dt/wake', '/api/game/dt/status'], async (req, res) => {
  ensureDtLoopRunning();
  res.json({
    success: true,
    serverNow: Date.now(),
    state: dtState
  });
});

app.post('/api/game/dt/bet', async (req, res) => {
  if (!db) return res.status(503).json({ success: false, error: 'Database offline' });
  ensureDtLoopRunning();

  try {
    const b = pick(req.body, {});
    const uid = String(pick(b.uid, '')).trim();
    const side = String(pick(b.side, '')).toLowerCase().trim();
    const amount = parseInt(String(pick(b.amount, '0')), 10);
    const userName = String(pick(b.userName, 'Player'));
    const numericId = Number(pick(b.numericId, 0));
    const roomId = String(pick(b.roomId, ''));

    if (!uid) return res.status(400).json({ success: false, error: 'Missing user ID' });
    if (['dragon', 'tiger', 'tie'].indexOf(side) === -1) {
      return res.status(400).json({ success: false, error: 'Invalid bet side' });
    }
    if (isNaN(amount)  amount < 100  amount > 500000) {
      return res.status(400).json({ success: false, error: 'Invalid bet amount (100 - 500,000)' });
    }

    const now = Date.now();
    if (dtState.phase !== 'BETTING' || now >= (dtState.roundEndTime - 800)) {
      return res.status(400).json({ success: false, error: 'Betting closed for this round' });
    }

    const activeRoundId = dtState.roundId;
    const userRef = db.collection('users').doc(uid);
    const gameRef = db.collection('games').doc('dragon_tiger');
    const betRef = gameRef.collection('rounds').doc(activeRoundId).collection('bets').doc(uid);

    let updatedCoins = 0;
    let updatedMyBets = { dragon: 0, tie: 0, tiger: 0 };

    await db.runTransaction(async (t) => {
      const userSnap = await t.get(userRef);
      const betSnap = await t.get(betRef);

      if (!userSnap.exists) throw new Error('User wallet not found');
      const currentCoins = Number(userSnap.data().coins || 0);
      if (currentCoins < amount) throw new Error('Insufficient coins balance');

      const prevBet = betSnap.exists ? betSnap.data() : {};
      updatedMyBets = {
        dragon: Number(prevBet.dragon || 0) + (side === 'dragon' ? amount : 0),
        tie: Number(prevBet.tie || 0) + (side === 'tie' ? amount : 0),
        tiger: Number(prevBet.tiger || 0) + (side === 'tiger' ? amount : 0)
      };

      updatedCoins = currentCoins - amount;

      t.update(userRef, {
        coins: FV.increment(-amount),
        wealthExp: FV.increment(amount)
      });

      t.set(betRef, {
        uid,
        userName,
        numericId,
        roomId,
        dragon: updatedMyBets.dragon,
        tie: updatedMyBets.tie,
        tiger: updatedMyBets.tiger,
        paid: false,
        updatedAt: now
      }, { merge: true });

const potField = 'pot.' + side;
      t.update(gameRef, {
        [potField]: FV.increment(amount),
        totalPot: FV.increment(amount)
      });
    });

    dtState.pot[side] = (dtState.pot[side] || 0) + amount;
    dtState.totalPot = (dtState.totalPot || 0) + amount;

    if (roomId) {
      db.collection('rooms').doc(roomId).get().then((rSnap) => {
        if (rSnap.exists && rSnap.data().hostUid) {
          const rebate = Math.floor(amount * 0.02);
          if (rebate > 0) {
            db.collection('users').doc(String(rSnap.data().hostUid)).set({
              points: FV.increment(rebate)
            }, { merge: true }).catch(() => {});
          }
        }
      }).catch(() => {});
    }

    res.json({
      success: true,
      roundId: activeRoundId,
      newCoins: updatedCoins,
      myBets: updatedMyBets,
      pot: dtState.pot
    });
  } catch (e) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// ============================================================================
// AGORA RTC TOKEN ENDPOINTS
// ============================================================================
function tok(req, res) {
  try {
    const b = pick(req.body, {});
    const ch = pick(req.query.channelName, req.query.channel, req.params.channel, b.channelName);
    const chF = pick(ch, 'habesha_vip_room');
    const uid = parseInt(String(pick(req.query.uid, req.params.uid, b.uid, '0')), 10);
    const rl = String(pick(req.query.role, req.params.role, b.role, 'publisher')).toLowerCase();
    const role = ['audience', 'subscriber', '2'].indexOf(rl) !== -1 ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
    const ts = Math.floor(Date.now() / 1000) + 86400;
    const token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERT, chF, uid, role, ts, ts);
    res.json({ token, rtcToken: token, channelName: chF, uid });
  } catch (e) { res.status(500).json({ error: e.message }); }
}
app.get(['/token', '/rtcToken', '/getToken', '/rtc/:channel/:role/:tokentype/:uid'], tok);
app.post(['/token', '/rtcToken', '/getToken'], tok);

// ============================================================================
// BINANCE PAY & ADMIN ENDPOINTS
// ============================================================================
app.post(['/create-order', '/api/create-order', '/binance/create-order', '/api/binance/create-order'], async (req, res) => {
  try {
    const b = pick(req.body, {});
    const numId = pick(b.numericId, b.userNumericId, '100000');
    const orderRef = 'BNB_' + numId + '_' + Date.now();
    const od = { orderRef, uid: pick(b.userUid, b.uid), numericId: String(numId), coins: parseInt(String(pick(b.coins, '0')), 10), usdAmount: parseFloat(String(pick(b.usdAmount, b.amount, '0'))), binancePayId: PAY_ID, status: 'PENDING', createdAt: new Date().toISOString() };
    mem.set(orderRef, od);
    if (db) await db.collection('binance_orders').doc(orderRef).set(Object.assign({}, od, { timestamp: FV.serverTimestamp() }));
    res.json({ success: true, orderRef, binancePayId: PAY_ID, status: 'PENDING' });
  } catch (e) { res.status(500).json({ success: false, error: e.message }); }
});

app.post(['/verify-payment', '/api/verify-payment', '/binance/verify', '/api/binance/verify', '/verify-order', '/api/verify-order'], async (req, res) => {
  try {
    const ref = pick(pick(req.body, {}).orderRef);
    let od = mem.get(ref);
    if (db && ref) { const s = await db.collection('binance_orders').doc(ref).get(); if (s.exists) od = s.data(); }
    if (!od) return res.status(404).json({ success: false, message: 'Order not found.' });
    if (['PAID', 'APPROVED'].indexOf(od.status) !== -1) return res.json({ success: true, verified: true, coinsAdded: od.coins });
    res.status(400).json({ success: false, verified: false, message: 'Pending confirmation.' });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

app.get('/api/admin/overview', async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  try {
    const [uS, bS, sS, wS, aS, dtStatsSnap] = await Promise.all([
      db.collection('users').limit(200).get(),
      db.collection('binance_orders').limit(100).get(),
      db.collection('coin_recharges').limit(100).get(),
      db.collection('withdraw_requests').limit(100).get(),
      db.collection('agencies').limit(100).get(),
      db.collection('games').doc('dragon_tiger_stats').get()
    ]);
    let rev = 0, coins = 0, pts = 0;
    const users = [], userOrders = [], sellerOrders = [], withdrawals = [], agencies = [];
    uS.forEach(doc => { const d = doc.data(); coins += Number(pick(d.coins, 0)); pts += Number(pick(d.points, 0)); users.push(Object.assign({ uid: doc.id }, d)); });
    bS.forEach(doc => { const d = doc.data(); if (['PAID', 'APPROVED'].indexOf(d.status) !== -1) rev += Number(pick(d.usdAmount, 0)); userOrders.push(Object.assign({ id: doc.id }, d)); });
    sS.forEach(doc => { const d = doc.data(); if (['PAID', 'APPROVED'].indexOf(d.status) !== -1) rev += Number(pick(d.usdAmount, 0)); sellerOrders.push(Object.assign({ id: doc.id }, d)); });
    wS.forEach(doc => withdrawals.push(Object.assign({ id: doc.id }, doc.data())));
    aS.forEach(doc => agencies.push(Object.assign({ id: doc.id }, doc.data())));
    const dtNetProfit = dtStatsSnap.exists ? Number(pick(dtStatsSnap.data().netProfit, 0)) : 0;
    res.json({ stats: { totalRevenueUsd: rev, totalUserCoins: coins, totalUnpaidPoints: pts, totalUsers: users.length, totalAgencies: agencies.length, dtNetProfit }, userOrders, sellerOrders, withdrawals, users, agencies });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/admin/reset-all', async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  try {
    const cols = ['users', 'agencies', 'binance_orders', 'coin_recharges', 'withdraw_requests'];
    const snaps = await Promise.all(cols.map(c => db.collection(c).get()));
    const refs = [];
    snaps.forEach(s => s.forEach(doc => refs.push(doc.ref)));
    for (let i = 0; i < refs.length; i += 400) {
      const b = db.batch();
      refs.slice(i, i + 400).forEach(r => b.delete(r));
      await b.commit();
    }
    mem.clear();
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/admin/user-order', async (req, res) => {
  const { orderRef, action } = pick(req.body, {});
  const ref = db.collection('binance_orders').doc(orderRef);
  const od = (await ref.get()).data();
  if (action === 'APPROVE') {
    let uid = pick(od.uid);
    if (!uid && od.numericId) { const q = await db.collection('users').where('numericId', '==', Number(od.numericId)).limit(1).get(); if (!q.empty) uid = q.docs[0].id; }
    const b = db.batch(); b.update(ref, { status: 'PAID' });
    if (uid) b.set(db.collection('users').doc(uid), { coins: FV.increment(Number(pick(od.coins, 0))) }, { merge: true });
    await b.commit();
  } else { await ref.update({ status: 'REJECTED' }); }
  res.json({ success: true });
});

app.post('/api/admin/seller-order', async (req, res) => {
  const { orderRef, action } = pick(req.body, {});
  const ref = db.collection('coin_recharges').doc(orderRef);
  const od = (await ref.get()).data();
  if (action === 'APPROVE') {
    const b = db.batch(); b.update(ref, { status: 'PAID' });
    if (od.uid) b.set(db.collection('users').doc(od.uid), { coins: FV.increment(Number(pick(od.coins, 0))) }, { merge: true });
    await b.commit();
  } else { await ref.update({ status: 'REJECTED' }); }
  res.json({ success: true });
});

app.post('/api/admin/withdrawal', async (req, res) => {
  const { requestId, action } = pick(req.body, {});

const ref = db.collection('withdraw_requests').doc(requestId);
  const wd = (await ref.get()).data();
  if (action === 'PAID') { await ref.update({ status: 'PAID' }); }
  else {
    const b = db.batch(); b.update(ref, { status: 'REJECTED' });
    const uid = pick(wd.userUid, wd.uid);
    if (uid) b.update(db.collection('users').doc(uid), { points: FV.increment(Number(pick(wd.points, 0))) });
    await b.commit();
  }
  res.json({ success: true });
});

app.post('/api/admin/user-control', async (req, res) => {
  const b = pick(req.body, {});
  const ref = db.collection('users').doc(b.uid);
  const d = (await ref.get()).data(); const up = {};
  if (typeof b.addCoins === 'number') up.coins = FV.increment(b.addCoins);
  if (b.toggleFace) up.isFaceVerified = !d.isFaceVerified;
  if (b.toggleBan) up.isBanned = !d.isBanned;
  await ref.update(up);
  res.json({ success: true });
});

app.post('/api/admin/create-agency', async (req, res) => {
  const { agencyId, agencyName, ownerNumericId } = pick(req.body, {});
  await db.collection('agencies').doc(agencyId).set({ agencyId, name: agencyName, ownerNumericId: Number(pick(ownerNumericId, 0)), commissionRate: 0.15, totalHosts: 0, withdrawnCommissionPoints: 0, createdAt: FV.serverTimestamp() });
  res.json({ success: true });
});

app.listen(pick(process.env.PORT, 3000), () => {
  console.log('NILE Live Server running');
  ensureDtLoopRunning();
});
