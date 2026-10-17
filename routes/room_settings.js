const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

const ALLOWED_SEAT_COUNTS = [9, 16, 20, 24, 25, 30];

router.post('/update', async (req, res) => {
  try {
    const { roomId, seatCount, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    const count = Number(seatCount);
    if (!ALLOWED_SEAT_COUNTS.includes(count)) {
      return res.status(400).json({ success: false, message: 'Invalid seat count' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit seat count' });
    }

    room.seatCount = count;
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_seats_updated', {
        roomId: room.roomId,
        seatCount: room.seatCount
      });
    }

    return res.json({ success: true, seatCount: room.seatCount });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
