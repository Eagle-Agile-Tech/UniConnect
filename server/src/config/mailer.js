require('./env');

const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

class Mailer {
  constructor() {
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT || 587);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;
    const secure = process.env.SMTP_SECURE
      ? process.env.SMTP_SECURE === 'true'
      : port === 465;
    const fromAddress = process.env.MAIL_FROM;

    if (!host || !user || !pass) {
      throw new Error(
        'SMTP_HOST, SMTP_USER, and SMTP_PASS must be set to send email.',
      );
    }

    if (!fromAddress) {
      throw new Error('MAIL_FROM must be set to send email.');
    }

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: { user, pass },
    });
  }

  async sendEmail({ to, subject, html, text }) {
    try {
      return await this.transporter.sendMail({
        from: `"UniConnect" <${process.env.MAIL_FROM}>`,
        to,
        subject,
        text,
        html,
      });
    } catch (error) {
      logger.error(
        {
          to,
          subject,
          message: error?.message,
          code: error?.code,
        },
        'Email delivery failed',
      );

      throw error;
    }
  }
}

module.exports = new Mailer();
