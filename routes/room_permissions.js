const express = require('express');
const router = express.Router();
const Room = require('../models/Room');

router.post('/update', async (req, res) => {
  try {
    const { roomId, permissionType, password, hostId } = req.body;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    if (!['everyone', 'password'].includes(permissionType)) {
      return res.status(400).json({ success: false, message: 'Invalid permission type' });
    }

    if (permissionType === 'password' && (!password || !password.trim())) {
      return res.status(400).json({ success: false, message: 'Password is required for locked room' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can edit permissions' });
    }

    room.joinPermission = permissionType;
    room.isLocked = permissionType === 'password';
    room.password = permissionType === 'password' ? password.trim() : '';
    await room.save();

    const io = req.app.get('io');
    if (io) {
      io.to(String(roomId)).emit('room_permissions_updated', {
        roomId: room.roomId,
        joinPermission: room.joinPermission,
        isLocked: room.isLocked
      });
    }

    return res.json({
      success: true,
      joinPermission: room.joinPermission,
      isLocked: room.isLocked
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
