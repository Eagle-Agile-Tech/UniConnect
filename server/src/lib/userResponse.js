function toLowerRole(role) {
  if (!role) return null;
  return String(role).toLowerCase();
}

function normalizeString(value) {
  if (value === null || value === undefined) return null;
  const trimmed = String(value).trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeInterests(interests) {
  if (!Array.isArray(interests)) return null;
  const cleaned = interests
    .map(value => (typeof value === 'string' ? value.trim() : ''))
    .filter(value => value.length > 0);
  return cleaned.length > 0 ? cleaned : null;
}

function buildUserResponse({
  user,
  profile,
  universityName,
  expertProfile,
  accessToken,
  refreshToken,
  sessionId,
  networkCount,
}) {
  const resolvedUniversity =
    universityName || profile?.university?.name || profile?.universityName || null;

  const resolvedNetworkCount =
    typeof networkCount === 'number'
      ? networkCount
      : typeof profile?.networkCount === 'number'
        ? profile.networkCount
        : 0;

  const response = {
    id: normalizeString(user?.id),
    role: normalizeString(user?.role),
    firstName: normalizeString(user?.firstName),
    lastName: normalizeString(user?.lastName),
    email: normalizeString(user?.email),
    username: normalizeString(profile?.username),
    university: normalizeString(resolvedUniversity),
    bio: normalizeString(profile?.bio ?? expertProfile?.bio ?? null),
    profilePicture: normalizeString(profile?.profileImage ?? expertProfile?.profileImage ?? null),
    networkCount: resolvedNetworkCount,
  };

  const currentYearValue =
    typeof profile?.yearOfStudy === 'number'
      ? String(profile.yearOfStudy)
      : profile?.level
        ? String(profile.level).toLowerCase()
        : null;
  const graduationYearValue =
    typeof profile?.graduationYear === 'number' ? profile.graduationYear : null;
  

  response.STUDENT = {
    degree: normalizeString(profile?.department ?? null),
    currentYear: normalizeString(currentYearValue),
    expectedGraduationYear: graduationYearValue,
    interests: normalizeInterests(profile?.interests),
    
  };

  if (accessToken !== undefined || refreshToken !== undefined || sessionId !== undefined) {
    response.accessToken = accessToken ?? null;
    response.refreshToken = refreshToken ?? null;
    if (sessionId !== undefined) response.sessionId = sessionId ?? null;

    // Add expiresIn and issuedAt if possible
    try {
      const jwt = require('jsonwebtoken');
      if (accessToken) {
        const decoded = jwt.decode(accessToken, { complete: true });
        if (decoded && decoded.payload) {
          response.accessTokenExpiresIn = decoded.payload.exp ? decoded.payload.exp - decoded.payload.iat : null;
          response.accessTokenIssuedAt = decoded.payload.iat || null;
        }
      }
      if (refreshToken) {
        const decoded = jwt.decode(refreshToken, { complete: true });
        if (decoded && decoded.payload) {
          response.refreshTokenExpiresIn = decoded.payload.exp ? decoded.payload.exp - decoded.payload.iat : null;
          response.refreshTokenIssuedAt = decoded.payload.iat || null;
        }
      }
    } catch (e) {
      // ignore if jsonwebtoken is not available or decode fails
    }
  }

  if (expertProfile || user?.role === 'EXPERT') {
    response.EXPERT = {
      expertise: normalizeString(expertProfile?.expertise ?? null),
      honor: normalizeString(expertProfile?.honor ?? null),
    };
  }

  return response;
}

module.exports = buildUserResponse;
