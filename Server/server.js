KEDER:
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// የማዕከላዊ ዳታቤዝ ማከማቻ (In-Memory Central Storage)
const db = {
  users: {
    "1000": {
      id: "1000",
      name: "KEDIR (Super Owner)",
      role: "owner",
      coins: 50000,
      points: 0,
      faceVerified: false,
      faceVerifiedAt: null,
      taxCycleDay: 0
    }
  },
  rooms: {}
};

// 1. የፊት አሻራ ማረጋገጫ እና የ7 ቀን ታክስ ማስጀመሪያ API
app.post('/api/verify-face', (req, res) => {
  const { userId, faceImageData } = req.body;

  if (!userId) {
    return res.status(400).json({ success: false, message: "የተጠቃሚ መለያ ያስፈልጋል!" });
  }

  let user = db.users[userId];
  if (!user) {
    user = {
      id: userId,
      name: User_${userId},
      role: "user",
      coins: 500,
      points: 0,
      faceVerified: false,
      faceVerifiedAt: null,
      taxCycleDay: 0
    };
    db.users[userId] = user;
  }

  if (user.faceVerified) {
    return res.status(200).json({
      success: true,
      message: "የፊት አሻራዎ አስቀድሞ ተረጋግጧል!",
      verifiedAt: user.faceVerifiedAt
    });
  }

  const now = new Date();
  user.faceVerified = true;
  user.faceVerifiedAt = now.toISOString(); // የ7 ቀኑ ዴሊ ታክስ መነሻ
  user.taxCycleDay = 1;

  return res.status(200).json({
    success: true,
    message: "የፊት አሻራዎ ጸድቋል! የ7 ቀን ታክስ ቆጣሪ ተጀምሯል።",
    verifiedAt: user.faceVerifiedAt
  });
});

// 2. ክፍል መክፈቻ API (አሻራ ካልተሰጠ ይከለክላል)
app.post('/api/rooms/create', (req, res) => {
  const { userId, roomTitle, dailyTax } = req.body;
  const user = db.users[userId];

  if (!user || !user.faceVerified) {
    return res.status(403).json({
      success: false,
      message: "ክፍል ለመክፈት መጀመሪያ የፊት አሻራዎን ማረጋገጥ አለብዎት!"
    });
  }

  const roomId = room_${Date.now()};
  const newRoom = {
    roomId,
    ownerId: userId,
    title: roomTitle || "የቀጥታ ድምጽ ክፍል",
    dailyTax: dailyTax || 20,
    createdAt: new Date().toISOString(),
    seats: Array(8).fill(null).map((_, i) => ({ seatIndex: i + 1, occupantId: null }))
  };

  db.rooms[roomId] = newRoom;
  return res.status(201).json({ success: true, message: "ክፍሉ ተከፍቷል!", room: newRoom });
});

// 3. ወንበር መያዣ API (ተጠቃሚዎች ነፃ ወንበር ይይዛሉ፣ ምንም ኮይን/ፖይንት አያገኙም)
app.post('/api/rooms/take-seat', (req, res) => {
  const { roomId, seatIndex, userId } = req.body;
  const room = db.rooms[roomId];

  if (!room) {
    return res.status(404).json({ success: false, message: "ክፍሉ አልተገኘም!" });
  }

  const targetSeat = room.seats.find(s => s.seatIndex === seatIndex);
  if (!targetSeat) {
    return res.status(400).json({ success: false, message: "ትክክለኛ ያልሆነ የወንበር ቁጥር!" });
  }

  if (targetSeat.occupantId) {
    return res.status(400).json({ success: false, message: "ወንበሩ ተይዟል!" });
  }

  targetSeat.occupantId = userId;
  return res.status(200).json({
    success: true,
    message: ወንበር ${seatIndex} ተይዟል (ነፃ ማውሪያ ነው፤ ምንም ኮይን አያመነጭም)።,
    seats: room.seats
  });
});

// 4. የ7 ቀን ዴሊ ታክስ ቆጣሪ ስሌት (ከክፍሉ ባለቤት ብቻ ይቆርጣል)
function processDailyTax() {
  const now = new Date();
  Object.values(db.rooms).forEach(room => {
    const owner = db.users[room.ownerId];
    if (!owner || !owner.faceVerifiedAt) return;

    const verifiedDate = new Date(owner.faceVerifiedAt);
    const passedDays = Math.floor((now - verifiedDate) / (1000 * 60 * 60 * 24));
    const currentDay = (passedDays % 7) + 1;

    if (owner.coins >= room.dailyTax) {
      owner.coins -= room.dailyTax;
      console.log([ዴሊ ታክስ] ቀን ${currentDay}፡ ከባለቤት ${owner.id} ${room.dailyTax} ኮይን ተቆርጧል);
    } else {
      console.log([ማስጠንቀቂያ] ባለቤት ${owner.id} በቂ ኮይን ስለሌለው ክፍሉ ይዘጋል);
    }
  });
}

// በየሰዓቱ ታክሱን ማረጋገጥ
setInterval(processDailyTax, 1000 * 60 * 60);

// Socket.io ግንኙነት
io.on('connection', (socket) => {
  console.log('አዲስ ተጠቃሚ ተገናኝቷል:', socket.id);
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(ሰርቨሩ በፖርት ${PORT} ላይ በተሳካ ሁኔታ ስራ ጀምሯል);
});
