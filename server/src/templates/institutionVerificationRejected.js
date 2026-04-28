function institutionVerificationRejectedTemplate({
  institutionName,
  rejectionReason,
}) {
  const subject = `Your institution verification was rejected`;
  const textLines = [
    `Hi ${institutionName || "there"},`,
    ``,
    `Your institution verification request was rejected.`,
    rejectionReason ? `Reason: ${rejectionReason}` : null,
    ``,
    `Please review your submitted documents and try again.`,
  ].filter(Boolean);

  const html = `
    <p>Hi ${institutionName || "there"},</p>
    <p>Your institution verification request was rejected.</p>
    ${rejectionReason ? `<p><strong>Reason:</strong> ${rejectionReason}</p>` : ""}
    <p>Please review your submitted documents and try again.</p>
  `;

  return {
    subject,
    text: textLines.join("\n"),
    html,
  };
}

module.exports = institutionVerificationRejectedTemplate;

