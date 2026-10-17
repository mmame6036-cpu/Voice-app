const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

const ALLOWED_TYPES = [
  'Emotion',
  'Chatting',
  'Music',
  'Friends',
  'Fitness',
  'Lifestyle',
  'Fashion'
];

router.post('/update', async (req, res) => {
  try {
    const { roomId, roomType, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    if (!roomType || !ALLOWED_TYPES.includes(roomType)) {
      return res.status(400).json({ success: false, message: 'Invalid room type' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit room type' });
    }

    room.roomType = roomType;
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_type_updated', {
        roomId: room.roomId,
        roomType: room.roomType
      });
    }

    return res.json({ success: true, roomType: room.roomType });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
