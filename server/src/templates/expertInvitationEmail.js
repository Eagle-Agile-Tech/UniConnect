function expertInvitationTemplate({ institutionName, inviteUrl, expiresAt }) {
  const formattedExpiry = expiresAt
    ? new Date(expiresAt).toLocaleString('en-US', { timeZone: 'UTC' }) + ' UTC'
    : 'soon';

  const subject = `You have been invited to join ${institutionName} on UniConnect`;
  const text = [
    `You have been invited to join ${institutionName} as an expert on UniConnect.`,
    `Use this link to complete your expert signup:`,
    inviteUrl,
    '',
    `This invitation expires on ${formattedExpiry}.`,
  ].join('\n');

  const html = `
    <p>You have been invited to join <strong>${institutionName}</strong> as an expert on UniConnect.</p>
    <p><a href="${inviteUrl}">Click here to complete your expert signup</a></p>
    <p>This invitation expires on <strong>${formattedExpiry}</strong>.</p>
  `;

  return { subject, text, html };
}

module.exports = expertInvitationTemplate;
