const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      error: 'Access denied. Authentication token required.' 
    });
  }

  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET || 'nile_super_secret_key_2026');
    req.user = verified;
    next();
  } catch (err) {
    return res.status(403).json({ 
      success: false, 
      error: 'Invalid or expired token.' 
    });
  }
};

module.exports = verifyToken;
