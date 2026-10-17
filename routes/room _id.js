const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

// Get Room ID details
router.get('/info', async (req, res) => {
  try {
    const { roomId } = req.query;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    const room = await Room.findOne({ roomId: String(roomId) }).select('roomId hostId title');
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    return res.json({ success: true, roomId: room.roomId });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Update or Customize Room ID (VIP / Vanity ID)
router.post('/update', async (req, res) => {
  try {
    const { currentRoomId, newRoomId, hostId } = req.body;

    if (!currentRoomId || !newRoomId) {
      return res.status(400).json({ success: false, message: 'Both current and new Room ID are required' });
    }

    const cleanNewId = String(newRoomId).trim();

    const existingRoom = await Room.findOne({ roomId: cleanNewId });
    if (existingRoom) {
      return res.status(400).json({ success: false, message: 'Room ID is already taken' });
    }

    const room = await Room.findOne({ roomId: String(currentRoomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can change Room ID' });
    }

    const oldRoomId = room.roomId;
    room.roomId = cleanNewId;
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(oldRoomId)).emit('room_id_updated', {
        oldRoomId: oldRoomId,
        newRoomId: cleanNewId
      });
    }

    return res.json({ success: true, newRoomId: cleanNewId });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
