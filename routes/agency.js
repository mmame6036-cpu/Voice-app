const express = require('express');
const router = express.Router();
const Agency = require('../models/Agency');
const AgencyHost = require('../models/AgencyHost');
const mongoose = require('mongoose');

// 1. Create a new Agency
router.post('/create', async (req, res) => {
  try {
    const { ownerId, agencyName } = req.body;

    if (!ownerId) {
      return res.status(400).json({ success: false, message: 'Owner ID is required' });
    }
    if (!agencyName) {
      return res.status(400).json({ success: false, message: 'Agency Name is required' });
    }

    const existingAgency = await Agency.findOne({ ownerId: String(ownerId) });
    if (existingAgency) {
      return res.status(400).json({ success: false, message: 'User already owns an agency', agency: existingAgency });
    }

    const randomSuffix = Math.floor(100000 + Math.random() * 900000);
    const generatedAgencyId = 'AG' + randomSuffix;

    const newAgency = new Agency({
      agencyId: generatedAgencyId,
      ownerId: String(ownerId),
      agencyName: String(agencyName).trim(),
      commissionRate: 10,
      status: 'active'
    });

    await newAgency.save();

    return res.json({
      success: true,
      message: 'Agency created successfully',
      agency: newAgency
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 2. Host Applies to Join Agency
router.post('/apply', async (req, res) => {
  try {
    const { userId, agencyId } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }
    if (!agencyId) {
      return res.status(400).json({ success: false, message: 'Agency ID is required' });
    }

    const targetAgency = await Agency.findOne({ agencyId: String(agencyId).trim(), status: 'active' });
    if (!targetAgency) {
      return res.status(404).json({ success: false, message: 'Invalid or inactive Agency ID' });
    }

    const existingRecord = await AgencyHost.findOne({ userId: String(userId) });
    if (existingRecord) {
      if (existingRecord.status === 'active') {
        return res.status(400).json({ success: false, message: 'User is already an active host in an agency' });
      }
      if (existingRecord.status === 'pending') {
        return res.status(400).json({ success: false, message: 'Application is already pending approval' });
      }

      existingRecord.agencyId = targetAgency.agencyId;
      existingRecord.status = 'pending';
      await existingRecord.save();

      return res.json({ success: true, message: 'Application submitted successfully', host: existingRecord });
    }

    let resolvedName = 'Host_' + userId;
    let resolvedAvatar = '';

    const User = mongoose.models.User;
    if (User) {
      const userDoc = await User.findOne({ userId: String(userId) });
      if (userDoc) {
        if (userDoc.name) resolvedName = userDoc.name;
        if (userDoc.avatar) resolvedAvatar = userDoc.avatar;
      }
    }

    const newHost = new AgencyHost({
      agencyId: targetAgency.agencyId,
      userId: String(userId),
      userName: resolvedName,
      avatar: resolvedAvatar,
      status: 'pending'
    });

    await newHost.save();

    return res.json({
      success: true,
      message: 'Application submitted successfully',
      host: newHost
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 3. Agency Owner Approves or Rejects Application
router.post('/manage-application', async (req, res) => {
  try {
    const { ownerId, userId, action } = req.body;

    if (!ownerId) {
      return res.status(400).json({ success: false, message: 'Owner ID is required' });
    }
    if (!userId) {
      return res.status(400).json({ success: false, message: 'Target Host User ID is required' });
    }
    if (!action) {
      return res.status(400).json({ success: false, message: 'Action (approve/reject) is required' });
    }

const agency = await Agency.findOne({ ownerId: String(ownerId) });
    if (!agency) {
      return res.status(403).json({ success: false, message: 'Unauthorized. You do not own an agency.' });
    }

    const hostRecord = await AgencyHost.findOne({ userId: String(userId), agencyId: agency.agencyId });
    if (!hostRecord) {
      return res.status(404).json({ success: false, message: 'Host application record not found' });
    }

    if (action === 'approve') {
      hostRecord.status = 'active';
      await hostRecord.save();
      return res.json({ success: true, message: 'Host approved successfully', host: hostRecord });
    }

    if (action === 'reject') {
      hostRecord.status = 'rejected';
      await hostRecord.save();
      return res.json({ success: true, message: 'Host application rejected', host: hostRecord });
    }

    return res.status(400).json({ success: false, message: 'Invalid action parameter' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 4. Remove Host from Agency
router.post('/remove-host', async (req, res) => {
  try {
    const { ownerId, userId } = req.body;

    if (!ownerId) {
      return res.status(400).json({ success: false, message: 'Owner ID is required' });
    }
    if (!userId) {
      return res.status(400).json({ success: false, message: 'Target Host User ID is required' });
    }

    const agency = await Agency.findOne({ ownerId: String(ownerId) });
    if (!agency) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const hostRecord = await AgencyHost.findOne({ userId: String(userId), agencyId: agency.agencyId });
    if (!hostRecord) {
      return res.status(404).json({ success: false, message: 'Host record not found in your agency' });
    }

    hostRecord.status = 'terminated';
    await hostRecord.save();

    return res.json({ success: true, message: 'Host removed successfully from agency' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 5. Agency Dashboard Data
router.get('/dashboard', async (req, res) => {
  try {
    const ownerId = req.query.ownerId;
    if (!ownerId) {
      return res.status(400).json({ success: false, message: 'Owner ID is required' });
    }

    let agency = await Agency.findOne({ ownerId: String(ownerId) });
    if (!agency) {
      const randomSuffix = Math.floor(100000 + Math.random() * 900000);
      agency = new Agency({
        agencyId: 'AG' + randomSuffix,
        ownerId: String(ownerId),
        agencyName: 'Agency ' + ownerId,
        commissionRate: 10,
        status: 'active'
      });
      await agency.save();
    }

    const hosts = await AgencyHost.find({ agencyId: agency.agencyId, status: 'active' }).sort({ currentMonthPoints: -1 });
    const pendingRequests = await AgencyHost.find({ agencyId: agency.agencyId, status: 'pending' }).sort({ joinedAt: -1 });

    const agencyPayload = {
      agencyId: agency.agencyId,
      agencyName: agency.agencyName,
      commissionRate: agency.commissionRate,
      balancePoints: agency.balancePoints ? agency.balancePoints : 0,
      totalEarnings: agency.totalEarnings ? agency.totalEarnings : 0,
      level: agency.level ? agency.level : 1,
      activeHostsCount: hosts.length
    };

    return res.json({
      success: true,
      agency: agencyPayload,
      hosts: hosts,
      pendingRequests: pendingRequests
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
