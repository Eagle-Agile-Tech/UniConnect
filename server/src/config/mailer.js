require('./env');

const nodemailer = require('nodemailer');

class Mailer {
  constructor() {
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT || 587);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      return;
    }

    this.transporter = nodemailer.createTransport({ jsonTransport: true });
  }

  async sendEmail({ to, subject, html, text }) {
    return this.transporter.sendMail({
      from: `"UniConnect" <${process.env.MAIL_FROM || 'no-reply@uniconnect.local'}>`,
      to,
      subject,
      text,
      html,
    });
  }
}

module.exports = new Mailer();
