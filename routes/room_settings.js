const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

// Update Room Settings
router.post('/update-settings', async (req, res) => {
  try {
    const { 
      roomId, 
      title, 
      announcement, 
      coverUrl, 
      backgroundUrl, 
      roomType, 
      joinPermission, 
      password,
      micMode, 
      seatCount,
      hostId 
    } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit settings' });
    }

    if (title !== undefined) room.title = title.substring(0, 30);
    if (announcement !== undefined) room.announcement = announcement.substring(0, 100);
    if (coverUrl !== undefined) room.coverUrl = coverUrl;
    if (backgroundUrl !== undefined) room.backgroundUrl = backgroundUrl;
    if (roomType !== undefined) room.roomType = roomType;
    if (joinPermission !== undefined) room.joinPermission = joinPermission;
    if (password !== undefined) room.password = password;
    if (micMode !== undefined) room.micMode = micMode;
    if (seatCount !== undefined) room.seatCount = Number(seatCount);

    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_settings_updated', {
        roomId: room.roomId,
        title: room.title,
        announcement: room.announcement,
        coverUrl: room.coverUrl,
        backgroundUrl: room.backgroundUrl,
        roomType: room.roomType,
        joinPermission: room.joinPermission,
        micMode: room.micMode,
        seatCount: room.seatCount
      });
    }

    return res.json({ success: true, message: 'Room settings updated successfully', room });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Get Block Lists (Blacklist and Kickout)
router.get('/block-list', async (req, res) => {
  try {
    const { roomId } = req.query;
    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    return res.json({ 
      success: true, 
      blacklist: room.blacklistedUsers || [], 
      kickOutList: room.kickedUsers || [] 
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Toggle Block / Kickout
router.post('/toggle-block', async (req, res) => {
  try {
    const { roomId, targetUserId, type, action, hostId } = req.body;
    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) return res.status(404).json({ success: false, message: 'Room not found' });

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    if (!room.blacklistedUsers) room.blacklistedUsers = [];
    if (!room.kickedUsers) room.kickedUsers = [];

    const listKey = type === 'blacklist' ? 'blacklistedUsers' : 'kickedUsers';

    if (action === 'add') {
      if (!room[listKey].includes(String(targetUserId))) {
        room[listKey].push(String(targetUserId));
      }
      const io = req.app.get('io');
      if (io) {
        io.to(String(roomId)).emit('user_kicked', { targetUserId: String(targetUserId) });
      }
    } else {
      room[listKey] = room[listKey].filter(id => id !== String(targetUserId));
    }

    await room.save();
    return res.json({ success: true, list: room[listKey] });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
