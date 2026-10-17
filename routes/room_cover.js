const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Room = require('../models/Room');

const uploadDir = path.join(__dirname, '../uploads/covers');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, 'cover_' + Date.now() + ext);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }
});

router.post('/upload', upload.single('coverImage'), async (req, res) => {
  try {
    const { roomId, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No image uploaded' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can change cover' });
    }

    const coverUrl = '/uploads/covers/' + req.file.filename;
    room.coverUrl = coverUrl;
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_cover_updated', {
        roomId: room.roomId,
        coverUrl: room.coverUrl
      });
    }

    return res.json({ success: true, coverUrl: room.coverUrl });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
