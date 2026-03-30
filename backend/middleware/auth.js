const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Make sure the decoded token has the user ID
    if (!decoded.id) {
      return res.status(401).json({ error: 'Invalid token structure' });
    }
    
    req.user = { id: decoded.id };
    console.log(` User authenticated: ${req.user.id}`);
    next();
  } catch (err) {
    console.error('Token verification failed:', err.message);
    res.status(401).json({ error: 'Invalid token' });
  }
};