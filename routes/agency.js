const express = require('express');
const router = express.Router();
const Agency = require('../models/Agency');
const AgencyHost = require('../models/AgencyHost');
const mongoose = require('mongoose');

// Helper: Calculate Dynamic Commission Rate
function calculateCommissionRate(totalPoints) {
  if (totalPoints >= 150000000) return 20;
  if (totalPoints >= 50000000) return 16;
  if (totalPoints >= 10000000) return 12;
  if (totalPoints >= 2000000) return 8;
  return 4; // Base rate
}

// Helper: Get or Create Agency
async function getOrCreateAgency(ownerId) {
  let agency = await Agency.findOne({ ownerId: String(ownerId) });
  if (!agency) {
    const randomSuffix = Math.floor(100000 + Math.random() * 900000);
    agency = new Agency({
      agencyId: 'AG' + randomSuffix,
      ownerId: String(ownerId),
      agencyName: 'Medina Agency',
      commissionRate: 4,
      status: 'active'
    });
    await agency.save();
  }
  return agency;
}

// 1. Dashboard Endpoint (Matches Flutter UI: /api/agency/dashboard?ownerId=...)
router.get('/dashboard', async (req, res) => {
  try {
    const ownerId = req.query.ownerId || req.query.agentId;

    if (!ownerId) {
      return res.status(400).json({ success: false, message: 'Owner ID is required' });
    }

    const agency = await getOrCreateAgency(ownerId);
    const hosts = await AgencyHost.find({ agencyId: agency.agencyId, status: 'active' }).sort({ currentMonthPoints: -1 });

    const totalPoints = hosts.reduce((sum, h) => sum + (h.currentMonthPoints || 0), 0);
    const dynamicRate = calculateCommissionRate(totalPoints);

    if (agency.commissionRate !== dynamicRate) {
      agency.commissionRate = dynamicRate;
      await agency.save();
    }

    return res.json({
      success: true,
      agency: {
        agencyId: agency.agencyId,
        agencyName: agency.agencyName || 'Medina Agency',
        commissionRate: dynamicRate,
        totalEarnings: totalPoints,
      },
      hosts: hosts,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 2. Direct Add Host
router.post('/add-host', async (req, res) => {
  try {
    const { agentId, hostUserId } = req.body;

    if (!agentId || !hostUserId) {
      return res.status(400).json({ success: false, message: 'agentId and hostUserId are required' });
    }

    const agency = await getOrCreateAgency(agentId);
    const cleanHostId = String(hostUserId).trim();

    let resolvedName = 'Host_' + cleanHostId;
    let resolvedAvatar = '';
    const User = mongoose.models.User;
    if (User) {
      const targetUser = await User.findOne({ userId: cleanHostId });
      if (!targetUser) {
        return res.status(404).json({ success: false, message: 'Host user not found' });
      }
      resolvedName = targetUser.name || resolvedName;
      resolvedAvatar = targetUser.avatar || '';
    }

    let hostRecord = await AgencyHost.findOne({ userId: cleanHostId });
    if (hostRecord) {
      if (hostRecord.status === 'active' && hostRecord.agencyId === agency.agencyId) {
        return res.status(400).json({ success: false, message: 'Host is already active in your agency' });
      }
      hostRecord.agencyId = agency.agencyId;
      hostRecord.userName = resolvedName;
      hostRecord.avatar = resolvedAvatar;
      hostRecord.status = 'active';
      await hostRecord.save();
    } else {
      hostRecord = new AgencyHost({
        agencyId: agency.agencyId,
        userId: cleanHostId,
        userName: resolvedName,
        avatar: resolvedAvatar,
        status: 'active',
        currentMonthPoints: 0,
        validHours: 0,
      });
      await hostRecord.save();
    }

    return res.json({
      success: true,
      message: 'Host successfully recruited to agency!',
      host: hostRecord,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 3. Create Agency
router.post('/create', async (req, res) => {
  try {
    const { ownerId, agencyName } = req.body;

if (!ownerId || !agencyName) {
      return res.status(400).json({ success: false, message: 'ownerId and agencyName are required' });
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
      commissionRate: 4,
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

// 4. Host Applies to Join Agency
router.post('/apply', async (req, res) => {
  try {
    const { userId, agencyId } = req.body;

    if (!userId || !agencyId) {
      return res.status(400).json({ success: false, message: 'userId and agencyId are required' });
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
        resolvedName = userDoc.name || resolvedName;
        resolvedAvatar = userDoc.avatar || '';
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

// 5. Manage Application (Approve / Reject)
router.post('/manage-application', async (req, res) => {
  try {
    const { ownerId, userId, action } = req.body;

    if (!ownerId  !userId  !action) {
      return res.status(400).json({ success: false, message: 'ownerId, userId, and action are required' });
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

// 6. Remove Host
router.post('/remove-host', async (req, res) => {
  try {
    const { ownerId, userId } = req.body;

    if (!ownerId || !userId) {
      return res.status(400).json({ success: false, message: 'ownerId and userId are required' });
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

module.exports = router;
