function idVerificationRejectedTemplate(name, rejectionReason) {
  const displayName = name || 'there';
  const reason = rejectionReason ? rejectionReason.trim() : '';
  return {
    subject: 'Your ID verification was rejected',
    text: `Hi ${displayName},\n\nYour ID verification was rejected. Your account cannot be used to log in at this time.${reason ? `\n\nReason: ${reason}` : ''}\n\nIf you believe this is a mistake or want to resubmit, please contact support.\n\nThanks,\nUniConnect team`,
    html: `
      <div style="font-family: Arial, sans-serif; color:#111;">
        <p>Hi ${displayName},</p>
        <p>Your ID verification was rejected. Your account cannot be used to log in at this time.</p>
        ${reason ? `<p><strong>Reason:</strong> ${reason}</p>` : ''}
        <p>If you believe this is a mistake or want to resubmit, please contact support.</p>
        <p>Thanks,<br/>UniConnect team</p>
      </div>
    `,
  };
}

module.exports = idVerificationRejectedTemplate;
