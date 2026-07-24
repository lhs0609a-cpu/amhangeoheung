const nodemailer = require('nodemailer');

// 이메일 전송 설정
// 프로덕션에서는 SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS 환경변수 사용
// 개발 환경에서는 콘솔 로그로 대체
const createTransporter = () => {
  if (process.env.SMTP_HOST) {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  // 개발 환경: Ethereal 또는 콘솔 로그 사용
  return null;
};

const transporter = createTransporter();

const FROM_EMAIL = process.env.FROM_EMAIL || 'noreply@amhangeoheung.com';
const FROM_NAME = '암행어흥';

// Rate limiting: 수신자당 5분에 최대 3회
const EMAIL_RATE_LIMIT = { maxPerWindow: 3, windowMs: 5 * 60 * 1000 };
const emailRateMap = new Map(); // key: email, value: [timestamp, ...]

// 30분마다 만료된 rate limit 엔트리 정리
setInterval(() => {
  const now = Date.now();
  for (const [key, timestamps] of emailRateMap.entries()) {
    const valid = timestamps.filter(t => now - t < EMAIL_RATE_LIMIT.windowMs);
    if (valid.length === 0) emailRateMap.delete(key);
    else emailRateMap.set(key, valid);
  }
}, 30 * 60 * 1000);

function checkEmailRateLimit(to) {
  const now = Date.now();
  const timestamps = (emailRateMap.get(to) || []).filter(
    t => now - t < EMAIL_RATE_LIMIT.windowMs
  );
  if (timestamps.length >= EMAIL_RATE_LIMIT.maxPerWindow) {
    return false;
  }
  timestamps.push(now);
  emailRateMap.set(to, timestamps);
  return true;
}

/**
 * 이메일 전송
 */
const sendEmail = async ({ to, subject, html }) => {
  // Rate limit 체크
  if (!checkEmailRateLimit(to)) {
    console.warn(`[EMAIL] Rate limited: ${to} (max ${EMAIL_RATE_LIMIT.maxPerWindow} per ${EMAIL_RATE_LIMIT.windowMs / 60000}min)`);
    return;
  }

  if (transporter) {
    await transporter.sendMail({
      from: `"${FROM_NAME}" <${FROM_EMAIL}>`,
      to,
      subject,
      html,
    });
    console.log(`[EMAIL] Sent to ${to}: ${subject}`);
  } else {
    // 개발 환경: 콘솔에 내용 출력
    console.log(`\n[EMAIL - DEV MODE] Would send to: ${to}`);
    console.log(`  Subject: ${subject}`);
    console.log(`  Preview: ${html.substring(0, 200)}...\n`);
  }
};

/**
 * 비밀번호 재설정 이메일
 */
const sendPasswordResetEmail = async (email, name, resetToken) => {
  // 실제 서비스에서는 프론트엔드 URL로 교체
  const resetUrl = `${process.env.FRONTEND_URL || 'https://amhangeoheung.com'}/reset-password?token=${resetToken}`;

  const html = `
    <div style="max-width:600px;margin:0 auto;font-family:'Pretendard',sans-serif;background:#fafafc;padding:40px 20px;">
      <div style="background:#fff;border-radius:16px;padding:40px;border:1px solid #eee;">
        <div style="text-align:center;margin-bottom:32px;">
          <h1 style="color:#6C5CE7;font-size:24px;margin:0;">암행어흥</h1>
          <p style="color:#6B6B80;font-size:14px;margin-top:8px;">비밀번호 재설정 안내</p>
        </div>

        <p style="color:#1A1A2E;font-size:16px;line-height:1.6;">
          안녕하세요${name ? ', ' + name + '님' : ''}.
        </p>

        <p style="color:#1A1A2E;font-size:16px;line-height:1.6;">
          비밀번호 재설정이 요청되었습니다. 아래 버튼을 클릭하여 새 비밀번호를 설정해주세요.
        </p>

        <div style="text-align:center;margin:32px 0;">
          <a href="${resetUrl}"
             style="display:inline-block;background:#6C5CE7;color:#fff;padding:14px 40px;
                    border-radius:12px;text-decoration:none;font-size:16px;font-weight:600;">
            비밀번호 재설정
          </a>
        </div>

        <p style="color:#A0A0B0;font-size:13px;line-height:1.5;">
          이 링크는 6시간 동안 유효합니다.<br>
          본인이 요청하지 않은 경우 이 이메일을 무시해주세요.
        </p>

        <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">

        <p style="color:#A0A0B0;font-size:12px;text-align:center;">
          이 이메일은 암행어흥에서 자동으로 발송되었습니다.<br>
          문의: support@amhangeoheung.com
        </p>
      </div>
    </div>
  `;

  await sendEmail({
    to: email,
    subject: '[암행어흥] 비밀번호 재설정 안내',
    html,
  });
};

/**
 * 환영 이메일
 */
const sendWelcomeEmail = async (email, name) => {
  const html = `
    <div style="max-width:600px;margin:0 auto;font-family:'Pretendard',sans-serif;background:#fafafc;padding:40px 20px;">
      <div style="background:#fff;border-radius:16px;padding:40px;border:1px solid #eee;">
        <div style="text-align:center;margin-bottom:32px;">
          <h1 style="color:#6C5CE7;font-size:24px;margin:0;">암행어흥에 오신 것을 환영합니다!</h1>
        </div>

        <p style="color:#1A1A2E;font-size:16px;line-height:1.6;">
          안녕하세요, ${name}님! 암행어흥에 가입해 주셔서 감사합니다.
        </p>

        <p style="color:#1A1A2E;font-size:16px;line-height:1.6;">
          지금 바로 앱에서 첫 미션을 시작해보세요.
        </p>

        <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">

        <p style="color:#A0A0B0;font-size:12px;text-align:center;">
          문의: support@amhangeoheung.com
        </p>
      </div>
    </div>
  `;

  await sendEmail({
    to: email,
    subject: '[암행어흥] 가입을 환영합니다!',
    html,
  });
};

/**
 * 이메일 인증 코드 (6자리)
 */
const sendVerificationCodeEmail = async (email, code) => {
  const html = `
    <div style="max-width:600px;margin:0 auto;font-family:'Pretendard',sans-serif;background:#fafafc;padding:40px 20px;">
      <div style="background:#fff;border-radius:16px;padding:40px;border:1px solid #eee;">
        <div style="text-align:center;margin-bottom:24px;">
          <h1 style="color:#6C5CE7;font-size:24px;margin:0;">암행어흥</h1>
          <p style="color:#6B6B80;font-size:14px;margin-top:8px;">이메일 인증</p>
        </div>

        <p style="color:#1A1A2E;font-size:16px;line-height:1.6;text-align:center;">
          아래 인증 코드를 앱에 입력해주세요.
        </p>

        <div style="text-align:center;margin:28px 0;">
          <span style="display:inline-block;background:#F1EEFF;color:#6C5CE7;
                       padding:16px 32px;border-radius:12px;font-size:32px;
                       font-weight:700;letter-spacing:8px;">
            ${code}
          </span>
        </div>

        <p style="color:#A0A0B0;font-size:13px;line-height:1.5;text-align:center;">
          이 코드는 30분 동안 유효합니다.<br>
          본인이 요청하지 않은 경우 이 이메일을 무시해주세요.
        </p>

        <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">

        <p style="color:#A0A0B0;font-size:12px;text-align:center;">
          문의: support@amhangeoheung.com
        </p>
      </div>
    </div>
  `;

  await sendEmail({
    to: email,
    subject: '[암행어흥] 이메일 인증 코드',
    html,
  });
};

module.exports = {
  sendEmail,
  sendPasswordResetEmail,
  sendWelcomeEmail,
  sendVerificationCodeEmail,
};
