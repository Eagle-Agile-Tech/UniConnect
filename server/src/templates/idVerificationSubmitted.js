function idVerificationSubmittedTemplate(name) {
  const displayName = name || 'there';
  return {
    subject: 'We received your ID verification request',
    text: `Hi ${displayName},\n\nWe received your ID verification request. Our team will review it and notify you once a decision is made.\n\nIf you have questions, reply to this email.\n\nThanks,\nUniConnect team`,
    html: `
      <div style="font-family: Arial, sans-serif; color:#111;">
        <p>Hi ${displayName},</p>
        <p>We received your ID verification request. Our team will review it and notify you once a decision is made.</p>
        <p>If you have questions, reply to this email.</p>
        <p>Thanks,<br/>UniConnect team</p>
      </div>
    `,
  };
}

module.exports = idVerificationSubmittedTemplate;
