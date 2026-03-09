function verificationTemplate(otpCode) {
  return {
    subject: 'Your UniConnect verification code',
    text: `Your UniConnect OTP is: ${otpCode}. It expires in 5 minutes.`,
    html: `
      <h2>Welcome to UniConnect 🎓</h2>
      <p>Your academic network is almost ready.</p>
      <p>Use this 4-digit verification code:</p>
      <p style="font-size: 28px; font-weight: bold; letter-spacing: 6px;">${otpCode}</p>
      <p>This code expires in 5 minutes.</p>

      <p>If you didn't create this account, ignore this email.</p>

      <p>— UniConnect Team</p>
    `
  };
}

module.exports = verificationTemplate;
