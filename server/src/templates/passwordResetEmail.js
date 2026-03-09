function passwordResetTemplate(otpCode) {
  return {
    subject: 'Your UniConnect password reset code',
    text: `Your UniConnect password reset OTP is: ${otpCode}. It expires in 5 minutes.`,
    html: `
      <h2>Password Reset Request</h2>
      <p>Use this 4-digit code to reset your UniConnect password:</p>
      <p style="font-size: 28px; font-weight: bold; letter-spacing: 6px;">${otpCode}</p>
      <p>This code expires in 5 minutes.</p>
      <p>If you didn't request this, ignore this email.</p>
      <p>— UniConnect Team</p>
    `,
  };
}

module.exports = passwordResetTemplate;
