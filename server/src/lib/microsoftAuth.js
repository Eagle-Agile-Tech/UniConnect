require('../config/env');

const axios = require('axios');
const jwt = require('jsonwebtoken');

const discoveryUrl =
  process.env.MICROSOFT_OPENID_CONFIG_URL ||
  `https://login.microsoftonline.com/${
    process.env.MICROSOFT_TENANT_ID || "common"
  }/v2.0/.well-known/openid-configuration`;

let discoveryCache = null;
const jwksCache = new Map();

function certToPem(x5c) {
  const wrapped = String(x5c || "")
    .match(/.{1,64}/g)
    ?.join("\n");

  if (!wrapped) {
    throw new Error("Microsoft signing certificate is missing");
  }

  return `-----BEGIN CERTIFICATE-----\n${wrapped}\n-----END CERTIFICATE-----\n`;
}

async function getDiscovery() {
  if (discoveryCache) return discoveryCache;

  const { data } = await axios.get(discoveryUrl, { timeout: 5000 });
  if (!data?.jwks_uri) {
    throw new Error("Microsoft OpenID discovery document is invalid");
  }

  discoveryCache = data;
  return data;
}

async function getPublicKey(kid) {
  const cached = jwksCache.get(kid);
  if (cached) return cached;

  const discovery = await getDiscovery();
  const { data } = await axios.get(discovery.jwks_uri, { timeout: 5000 });
  const key = data?.keys?.find((entry) => entry.kid === kid);

  if (!key?.x5c?.length) {
    throw new Error("Microsoft signing key not found");
  }

  const pem = certToPem(key.x5c[0]);
  jwksCache.set(kid, pem);
  return pem;
}

async function verifyMicrosoftToken(idToken) {
  const decoded = jwt.decode(idToken, { complete: true });
  const header = decoded?.header || {};

  if (!header.kid || header.alg !== "RS256") {
    throw new Error("Invalid Microsoft ID token");
  }

  const publicKey = await getPublicKey(header.kid);
  const audience = process.env.MICROSOFT_CLIENT_ID;

  if (!audience) {
    throw new Error("MICROSOFT_CLIENT_ID must be set");
  }

  const payload = jwt.verify(idToken, publicKey, {
    algorithms: ["RS256"],
    audience,
  });

  const email =
    String(payload.preferred_username || payload.email || payload.upn || "")
      .trim()
      .toLowerCase();

  if (!email) {
    throw new Error("Microsoft token does not include an email address");
  }

  return {
    microsoftId: payload.oid || payload.sub,
    email,
    emailVerified: true,
    firstName: payload.given_name || "",
    lastName: payload.family_name || "",
    picture: payload.picture || null,
    tenantId: payload.tid || null,
  };
}

module.exports = verifyMicrosoftToken;
