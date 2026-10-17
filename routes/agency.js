const express = require('express');
const router = express.Router();
const Agency = require('../models/Agency');
const AgencyHost = require('../models/AgencyHost');
const User = require('../models/User');

// 1. Create a new Agency
router.post('/create', async (req, res) => {
  try {
    const { ownerId, agencyName, commissionRate } = req.body;

    if (!ownerId || !agencyName) {
      return res.status(400).json({ success: false, message: 'Owner ID and Agency Name are required' });
    }

    const existingAgency = await Agency.findOne({ ownerId: String(ownerId) });
    if (existingAgency) {
      return res.status(400).json({ success: false, message: 'User already owns an agency' });
    }

    const agencyId = 'AG' + Math.floor(100000 + Math.random() * 900000);

    const agency = new Agency({
      agencyId,
      ownerId: String(ownerId),
      agencyName: String(agencyName).trim(),
      commissionRate: commissionRate ? Number(commissionRate) : 10
    });

    await agency.save();

    await User.findOneAndUpdate(
      { userId: String(ownerId) },
      { $set: { isAgent: true } }
    );

    return res.json({ success: true, message: 'Agency created successfully', agency });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Host applies to join Agency
router.post('/apply', async (req, res) => {
  try {
    const { agencyId, userId } = req.body;

    if (!agencyId || !userId) {
      return res.status(400).json({ success: false, message: 'Agency ID and User ID are required' });
    }

    const agency = await Agency.findOne({ agencyId: String(agencyId).trim() });
    if (!agency || agency.status !== 'active') {
      return res.status(404).json({ success: false, message: 'Active Agency not found' });
    }

    const existingHost = await AgencyHost.findOne({ userId: String(userId).trim() });
    if (existingHost) {
      if (existingHost.status === 'active') {
        return res.status(400).json({ success: false, message: 'User already belongs to an agency' });
      }
      if (existingHost.status === 'pending') {
        return res.status(400).json({ success: false, message: 'Application is already pending' });
      }
    }

    const user = await User.findOne({ userId: String(userId).trim() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const newHostApplication = new AgencyHost({
      agencyId: agency.agencyId,
      userId: user.userId,
      userName: user.name,
      avatar: user.avatar,
      status: 'pending'
    });

    await newHostApplication.save();

    return res.json({ success: true, message: 'Application submitted successfully' });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 3. Agency approves or rejects host application
router.post('/manage-application', async (req, res) => {
  try {
    const { ownerId, userId, action } = req.body; // action: 'approve' | 'reject'

    if (!ownerId  !userId  !action) {
      return res.status(400).json({ success: false, message: 'Missing required parameters' });
    }

    const agency = await Agency.findOne({ ownerId: String(ownerId) });
    if (!agency) {
      return res.status(403).json({ success: false, message: 'Only agency owner can manage applications' });
    }

    const hostRecord = await AgencyHost.findOne({ 
      agencyId: agency.agencyId, 
      userId: String(userId) 
    });

    if (!hostRecord) {
      return res.status(404).json({ success: false, message: 'Application record not found' });
    }

    if (action === 'approve') {
      hostRecord.status = 'active';
    } else if (action === 'reject') {
      hostRecord.status = 'rejected';
    } else {
      return res.status(400).json({ success: false, message: 'Invalid action. Use "approve" or "reject"' });
    }

    await hostRecord.save();

return res.json({ success: true, message: 'Host application status updated', status: hostRecord.status });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 4. Get Agency Dashboard Details
router.get('/dashboard', async (req, res) => {
  try {
    const { ownerId } = req.query;

    if (!ownerId) {
      return res.status(400).json({ success: false, message: 'Owner ID is required' });
    }

    const agency = await Agency.findOne({ ownerId: String(ownerId) });
    if (!agency) {
      return res.status(404).json({ success: false, message: 'Agency not found for this user' });
    }

    const hosts = await AgencyHost.find({ agencyId: agency.agencyId, status: 'active' });
    const pendingRequests = await AgencyHost.find({ agencyId: agency.agencyId, status: 'pending' });

    const totalHostPoints = hosts.reduce((sum, h) => sum + (h.currentMonthPoints || 0), 0);

    return res.json({
      success: true,
      agency: {
        agencyId: agency.agencyId,
        agencyName: agency.agencyName,
        logo: agency.logo,
        commissionRate: agency.commissionRate,
        balancePoints: agency.balancePoints,
        totalEarnings: agency.totalEarnings,
        activeHostsCount: hosts.length,
        pendingRequestsCount: pendingRequests.length,
        monthlyTeamPoints: totalHostPoints
      },
      hosts,
      pendingRequests
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 5. Remove or Terminate Host from Agency
router.post('/remove-host', async (req, res) => {
  try {
    const { ownerId, userId } = req.body;

    if (!ownerId || !userId) {
      return res.status(400).json({ success: false, message: 'Owner ID and Target User ID are required' });
    }

    const agency = await Agency.findOne({ ownerId: String(ownerId) });
    if (!agency) {
      return res.status(403).json({ success: false, message: 'Unauthorized. Only agency owner can remove hosts' });
    }

    const result = await AgencyHost.findOneAndDelete({
      agencyId: agency.agencyId,
      userId: String(userId)
    });

    if (!result) {
      return res.status(404).json({ success: false, message: 'Host not found in this agency' });
    }

    return res.json({ success: true, message: 'Host removed successfully' });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
