require('./env');

const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

function normalizeEmailDomain(email) {
  const domain = String(email || "")
    .trim()
    .toLowerCase()
    .split("@")[1];
  return domain || null;
}

class Mailer {
  constructor() {
    this.defaultTransport = this.createTransport({
      prefix: "SMTP",
      required: true,
    });

    this.mailtrapTransport = this.createTransport({
      prefix: "MAILTRAP",
      required: false,
    });

    this.defaultFromAddress = process.env.MAIL_FROM;
    this.mailtrapFromAddress = process.env.MAILTRAP_FROM || this.defaultFromAddress;

    if (!this.defaultFromAddress) {
      throw new Error('MAIL_FROM must be set to send email.');
    }
  }

  parseHostList(rawValue, fallbackHosts = []) {
    const hosts = String(rawValue || "")
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);

    return hosts.length ? hosts : fallbackHosts;
  }

  createTransport({ prefix, required }) {
    return this.createTransportForHost({
      prefix,
      required,
      host: process.env[`${prefix}_HOST`],
    });
  }

  createTransportForHost({ prefix, required, host }) {
    const port = Number(process.env[`${prefix}_PORT`] || 587);
    const user = process.env[`${prefix}_USER`];
    const pass = process.env[`${prefix}_PASS`];
    const secure = process.env[`${prefix}_SECURE`]
      ? process.env[`${prefix}_SECURE`] === 'true'
      : port === 465;

    if (!host || !user || !pass) {
      if (required) {
        throw new Error(
          `${prefix}_HOST, ${prefix}_USER, and ${prefix}_PASS must be set to send email.`,
        );
      }

      return null;
    }

    return {
      provider:
        prefix === "MAILTRAP" ? "mailtrap" : "gmail",
      host,
      port,
      secure,
      user,
      pass,
      transporter: nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass },
      }),
    };
  }

  isGmailRecipient(to) {
    const domain = normalizeEmailDomain(to);
    return domain === "gmail.com" || domain === "googlemail.com";
  }

  selectTransport(to) {
    if (!this.isGmailRecipient(to) && this.mailtrapTransport) {
      return {
        transport: this.mailtrapTransport,
        fromAddress: this.mailtrapFromAddress,
      };
    }

    return {
      transport: this.defaultTransport,
      fromAddress: this.defaultFromAddress,
    };
  }

  async sendEmail({ to, subject, html, text }) {
    let selectedTransport = null;
    try {
      const { transport, fromAddress } = this.selectTransport(to);
      selectedTransport = transport;

      if (!transport?.transporter) {
        throw new Error(
          !this.isGmailRecipient(to)
            ? "Non-Gmail email detected but MAILTRAP_* is not configured."
            : "Default SMTP transport is not configured.",
        );
      }

      const result = await transport.transporter.sendMail({
        from: `"UniConnect" <${fromAddress}>`,
        to,
        subject,
        text,
        html,
      });

      logger.info(
        {
          to,
          subject,
          provider: transport.provider,
          host: transport.host,
          messageId: result?.messageId,
          accepted: result?.accepted,
          rejected: result?.rejected,
          response: result?.response,
        },
        "Email delivery accepted by SMTP",
      );

      if (!Array.isArray(result?.accepted) || result.accepted.length === 0) {
        const error = new Error("SMTP did not accept any recipients");
        error.response = result?.response;
        error.accepted = result?.accepted || [];
        error.rejected = result?.rejected || [];
        throw error;
      }

      return result;
    } catch (error) {
      logger.error(
        {
          to,
          subject,
          provider: selectedTransport?.provider,
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
