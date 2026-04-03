function getAppUrl() {
  const raw = process.env.FRONTEND_URL || process.env.CLIENT_URL || process.env.WEB_URL || 'http://localhost:3000';
  return raw.replace(/\/+$/, '');
}

function buildLoginUrl() {
  return `${getAppUrl()}/login`;
}

module.exports = {
  getAppUrl,
  buildLoginUrl,
};
