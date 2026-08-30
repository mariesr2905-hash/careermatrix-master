const nodemailer = require('nodemailer');

/**
 * Creates a reusable Nodemailer transporter from env-configured SMTP settings.
 */
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: Number(process.env.EMAIL_PORT) || 587,
    secure: Number(process.env.EMAIL_PORT) === 465, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
};

/**
 * Sends an email. In development, if SMTP credentials are not configured,
 * it logs the email to the console instead of throwing so the auth flow
 * can still be tested end-to-end without a real mail server.
 *
 * @param {Object} options - { to, subject, html, text }
 */
const sendEmail = async ({ to, subject, html, text }) => {
  const hasEmailConfig =
    process.env.EMAIL_HOST && process.env.EMAIL_USER && process.env.EMAIL_PASS;

  if (!hasEmailConfig) {
    console.warn('\n[emailService] SMTP not configured. Logging email instead of sending:');
    console.warn(`To: ${to}\nSubject: ${subject}\n${text || html}\n`);
    return { simulated: true };
  }

  const transporter = createTransporter();

  const info = await transporter.sendMail({
    from: process.env.EMAIL_FROM || `Career Matrix <no-reply@careermatrix.com>`,
    to,
    subject,
    html,
    text,
  });

  return info;
};

module.exports = { sendEmail };
