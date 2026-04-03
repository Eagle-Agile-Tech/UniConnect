function idVerificationApprovedTemplate(name, loginUrl) {
  const displayName = name || 'there';
  return {
    subject: 'Your ID verification is approved',
    text: `Hi ${displayName},\n\nYour ID verification has been approved. You can now log in using your email and password.\n\nLogin: ${loginUrl}\n\nThanks,\nUniConnect team`,
    html: `
      <div style="font-family: Arial, sans-serif; color:#111;">
        <p>Hi ${displayName},</p>
        <p>Your ID verification has been approved. You can now log in using your email and password.</p>
        <p><a href="${loginUrl}">Log in to UniConnect</a></p>
        <p>Thanks,<br/>UniConnect team</p>
      </div>
    `,
  };
}

module.exports = idVerificationApprovedTemplate;
