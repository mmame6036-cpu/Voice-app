const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

const ALLOWED_MIC_MODES = ['free', 'apply'];

router.post('/update', async (req, res) => {
  try {
    const { roomId, micMode, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    if (!micMode || !ALLOWED_MIC_MODES.includes(micMode)) {
      return res.status(400).json({ success: false, message: 'Invalid mic mode. Use "free" or "apply"' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit mic mode' });
    }

    room.micMode = micMode;
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_mic_mode_updated', {
        roomId: room.roomId,
        micMode: room.micMode
      });
    }

    return res.json({ success: true, micMode: room.micMode });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
