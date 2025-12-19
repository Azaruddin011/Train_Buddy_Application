module.exports = function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.replace('Bearer ', '').trim();

  if (!token) {
    return res.status(401).json({
      success: false,
      errorCode: 'UNAUTHORIZED',
      message: 'Missing or invalid token.'
    });
  }

  // TODO: replace with real token validation
  req.user = { id: 'user_123', phone: '+910000000000' };
  next();
};
