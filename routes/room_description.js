const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

router.post('/update', async (req, res) => {
  try {
    const { roomId, description, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit room description' });
    }

    room.announcement = (description || '').trim().substring(0, 100);
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_description_updated', {
        roomId: room.roomId,
        announcement: room.announcement
      });
    }

    return res.json({ success: true, announcement: room.announcement });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
