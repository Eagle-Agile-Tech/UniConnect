function institutionVerificationApprovedTemplate({
  institutionName,
  secretCode,
  secretCodeExpiresAt,
}) {
  const expiresText = secretCodeExpiresAt
    ? new Date(secretCodeExpiresAt).toISOString()
    : null;

  const subject = `Your institution is verified on UniConnect`;
  const textLines = [
    `Hi ${institutionName || "there"},`,
    ``,
    `Your institution account has been verified on UniConnect.`,
    secretCode ? `Secret code: ${secretCode}` : `Secret code: (missing)`,
    expiresText ? `Expires at: ${expiresText}` : null,
    ``,
    `You can share this secret code with experts so they can join your institution.`,
  ].filter(Boolean);

  const html = `
    <p>Hi ${institutionName || "there"},</p>
    <p>Your institution account has been verified on UniConnect.</p>
    <p><strong>Secret code:</strong> ${secretCode || ""}</p>
    ${expiresText ? `<p><strong>Expires at:</strong> ${expiresText}</p>` : ""}
    <p>You can share this secret code with experts so they can join your institution.</p>
  `;

  return {
    subject,
    text: textLines.join("\n"),
    html,
  };
}

module.exports = institutionVerificationApprovedTemplate;

