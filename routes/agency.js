const express = require('express');
const router = express.Router();
const Agency = require('../models/Agency');
const AgencyHost = require('../models/AgencyHost');
const mongoose = require('mongoose');

function calculateCommissionRate(totalPoints) {
  if (totalPoints >= 150000000) return 20;
  if (totalPoints >= 50000000) return 16;
  if (totalPoints >= 10000000) return 12;
  if (totalPoints >= 2000000) return 8;
  return 4;
}

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
        totalEarnings: totalPoints
      },
      hosts: hosts
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

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
      if (targetUser) {
        resolvedName = targetUser.name || resolvedName;
        resolvedAvatar = targetUser.avatar || '';
      }
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
        validHours: 0
      });
      await hostRecord.save();
    }

    return res.json({
      success: true,
      message: 'Host successfully recruited to agency',
      host: hostRecord
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

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

module.exports = router;
