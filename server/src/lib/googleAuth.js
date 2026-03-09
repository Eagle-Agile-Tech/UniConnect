require('../config/env');

const { OAuth2Client } = require('google-auth-library');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

async function verifyGoogleToken(idToken) {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID,
  });

  const payload = ticket.getPayload();

  return {
    googleId: payload.sub,
    email: payload.email,
    emailVerified: payload.email_verified,
    firstName: payload.given_name,
    lastName: payload.family_name,
    picture: payload.picture,
  };
}

module.exports = verifyGoogleToken;
