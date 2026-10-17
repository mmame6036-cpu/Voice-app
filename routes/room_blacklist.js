const express = require('express');
const router = express.Router();
const Room = require('../models/Room');
const User = require('../models/User');

// Get Blacklist and Kickout lists
router.get('/list', async (req, res) => {
  try {
    const { roomId } = req.query;

    if (!roomId) {
      return res.status(400).json({ success: false, message: 'Room ID is required' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    const blacklistedUsers = await User.find({ userId: { $in: room.blacklistedUsers || [] } }).select('userId name avatar');
    const kickedUsers = await User.find({ userId: { $in: room.kickedUsers || [] } }).select('userId name avatar');

    return res.json({
      success: true,
      blacklist: blacklistedUsers,
      kickOutList: kickedUsers
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Toggle Block or Kickout action
router.post('/toggle', async (req, res) => {
  try {
    const { roomId, targetUserId, type, action, hostId } = req.body;

    if (!roomId  !targetUserId  !type || !action) {
      return res.status(400).json({ success: false, message: 'Missing required parameters' });
    }

    if (!['blacklist', 'kickout'].includes(type) || !['add', 'remove'].includes(action)) {
      return res.status(400).json({ success: false, message: 'Invalid action or block type' });
    }

    const room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    if (hostId && room.hostId && String(room.hostId) !== String(hostId)) {
      return res.status(403).json({ success: false, message: 'Unauthorized: Only host can manage blacklist' });
    }

    if (!room.blacklistedUsers) room.blacklistedUsers = [];
    if (!room.kickedUsers) room.kickedUsers = [];

    const field = type === 'blacklist' ? 'blacklistedUsers' : 'kickedUsers';

    if (action === 'add') {
      if (!room[field].includes(String(targetUserId))) {
        room[field].push(String(targetUserId));
      }

      const io = req.app.get('io');
      if (io) {
        io.to(String(roomId)).emit
