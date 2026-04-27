const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

function normalizePath(url = '') {
  return String(url).split('?')[0];
}

function isLimitedAccessRoute(method, path) {
  const normalizedMethod = String(method || '').toUpperCase();
  const normalizedPath = normalizePath(path);

  if (normalizedMethod === 'POST' && normalizedPath === '/api/auth/verify-id') {
    return true;
  }

  if (normalizedMethod === 'GET' && normalizedPath === '/api/users/username-availability') {
    return true;
  }

  if (
    normalizedMethod === 'GET' &&
    /^\/api\/users\/username\/[^/]+\/available$/.test(normalizedPath)
  ) {
    return true;
  }

  if (
    (normalizedMethod === 'POST' || normalizedMethod === 'PATCH') &&
    normalizedPath === '/api/users/profile'
  ) {
    return true;
  }

  if (normalizedMethod === 'POST' && normalizedPath === '/api/users/profile/image') {
    return true;
  }

  return false;
}

const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.id || decoded.sub || decoded.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        role: true,
        isDeleted: true,
        verificationStatus: true,
        verificationMethod: true,
      },
    });

    if (!user || user.isDeleted) {
      return res.status(401).json({ message: 'User not found or inactive.' });
    }

    const isPendingIdReview =
      user.verificationMethod === 'ID_DOCUMENT_ADMIN' &&
      (user.verificationStatus === 'PENDING' ||
        user.verificationStatus === 'REJECTED');

    if (isPendingIdReview && !isLimitedAccessRoute(req.method, req.originalUrl)) {
      return res.status(403).json({
        message:
          user.verificationStatus === 'REJECTED'
            ? 'ID verification rejected. Resubmit your ID to continue.'
            : 'ID verification pending. Access is limited until admin review.',
        verificationStatus: user.verificationStatus,
        verificationMethod: user.verificationMethod,
      });
    }

    req.user = {
      ...decoded,
      id: user.id,
      role: user.role,
      verificationStatus: user.verificationStatus,
      verificationMethod: user.verificationMethod,
    };
    return next();
  } catch (error) {
    console.error('Token verification error:', error);
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Authentication token expired.' });
    }
    return res.status(403).json({ message: 'Invalid authentication token.' });
  }
};

module.exports = authenticate;
