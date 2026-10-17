const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

// 1. የክፍሉን ስም፣ መግለጫ፣ Cover እና Background መቀየሪያ
router.post('/update-settings', async (req, res) => {
  try {
    const { roomId, title, description, coverUrl, backgroundUrl, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    // ሆስቱ ብቻ እንዲቀይር መቆጣጠሪያ
    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit settings' });
    }

    if (title !== undefined) room.title = title;
    if (description !== undefined) room.announcement = description;
    if (coverUrl !== undefined) room.coverUrl = coverUrl;
    if (backgroundUrl !== undefined) room.backgroundUrl = backgroundUrl;

    await room.save();

    // በክፍሉ ውስጥ ላሉ ሰዎች በሙሉ በቅጽበት በ Socket.io ማሳወቅ
    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_settings_updated', {
        roomId: room.roomId,
        title: room.title,
        announcement: room.announcement,
        coverUrl: room.coverUrl,
        backgroundUrl: room.backgroundUrl,
      });
    }

    return res.json({ success: true, message: 'Room settings updated successfully', room });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 2. የክፍሉን የይለፍ ቃል (Password) ማዘጋጃ/ማጥፊያ
router.post('/set-password', async (req, res) => {
  try {
    const { roomId, password, isLocked, hostId } = req.body;

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    room.isLocked = Boolean(isLocked);
    room.password = isLocked ? String(password || '') : '';
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_lock_status', {
        roomId: room.roomId,
        isLocked: room.isLocked,
      });
    }

    return res.json({ success: true, message: 'Password updated', isLocked: room.isLocked });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
