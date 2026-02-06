const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM_EMAIL = 'noreply@amhangeoheung.com';
const APP_NAME = '암행어흥';

/**
 * 비밀번호 재설정 이메일 발송
 */
async function sendPasswordResetEmail(email, token, userName) {
  try {
    const resetUrl = `${process.env.APP_URL || 'https://amhangeoheung.com'}/reset-password?token=${token}`;
    
    await resend.emails.send({
      from: `${APP_NAME} <${FROM_EMAIL}>`,
      to: email,
      subject: `[${APP_NAME}] 비밀번호 재설정 안내`,
      html: `
        <div style="font-family: 'Apple SD Gothic Neo', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #6366f1;">비밀번호 재설정</h2>
          <p>${userName || '회원'}님, 안녕하세요.</p>
          <p>비밀번호 재설정을 요청하셨습니다. 아래 버튼을 클릭하여 새 비밀번호를 설정해주세요.</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetUrl}" style="background-color: #6366f1; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: bold;">
              비밀번호 재설정하기
            </a>
          </div>
          <p style="color: #6b7280; font-size: 14px;">이 링크는 6시간 동안 유효합니다.</p>
          <p style="color: #6b7280; font-size: 14px;">본인이 요청하지 않은 경우 이 이메일을 무시해주세요.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;" />
          <p style="color: #9ca3af; font-size: 12px;">${APP_NAME} | support@amhangeoheung.com</p>
        </div>
      `,
    });
    
    console.log(`[EMAIL] Password reset email sent to ${email}`);
    return { success: true };
  } catch (error) {
    console.error(`[EMAIL] Failed to send password reset email to ${email}:`, error);
    return { success: false, error: error.message };
  }
}

/**
 * 가입 환영 이메일
 */
async function sendWelcomeEmail(email, userName) {
  try {
    await resend.emails.send({
      from: `${APP_NAME} <${FROM_EMAIL}>`,
      to: email,
      subject: `[${APP_NAME}] 가입을 환영합니다!`,
      html: `
        <div style="font-family: 'Apple SD Gothic Neo', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #6366f1;">환영합니다, ${userName || '회원'}님!</h2>
          <p>${APP_NAME}에 가입해주셔서 감사합니다.</p>
          <p>이제 리뷰 신뢰 플랫폼의 다양한 기능을 이용하실 수 있습니다.</p>
          <ul>
            <li>미스터리 쇼핑 미션 참여</li>
            <li>검증된 리뷰 작성 및 수익 창출</li>
            <li>업체 신뢰도 분석</li>
          </ul>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;" />
          <p style="color: #9ca3af; font-size: 12px;">${APP_NAME} | support@amhangeoheung.com</p>
        </div>
      `,
    });

    console.log(`[EMAIL] Welcome email sent to ${email}`);
    return { success: true };
  } catch (error) {
    console.error(`[EMAIL] Failed to send welcome email to ${email}:`, error);
    return { success: false, error: error.message };
  }
}

/**
 * 결제 확인 이메일
 */
async function sendPaymentConfirmEmail(email, orderName, amount) {
  try {
    const formattedAmount = amount.toLocaleString('ko-KR');

    await resend.emails.send({
      from: `${APP_NAME} <${FROM_EMAIL}>`,
      to: email,
      subject: `[${APP_NAME}] 결제 완료 안내`,
      html: `
        <div style="font-family: 'Apple SD Gothic Neo', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #6366f1;">결제가 완료되었습니다</h2>
          <div style="background-color: #f9fafb; padding: 16px; border-radius: 8px; margin: 20px 0;">
            <p><strong>주문명:</strong> ${orderName}</p>
            <p><strong>결제 금액:</strong> ${formattedAmount}원</p>
            <p><strong>결제 일시:</strong> ${new Date().toLocaleString('ko-KR')}</p>
          </div>
          <p>결제 관련 문의사항이 있으시면 고객센터로 연락해주세요.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;" />
          <p style="color: #9ca3af; font-size: 12px;">${APP_NAME} | support@amhangeoheung.com</p>
        </div>
      `,
    });

    console.log(`[EMAIL] Payment confirmation email sent to ${email}`);
    return { success: true };
  } catch (error) {
    console.error(`[EMAIL] Failed to send payment confirmation email to ${email}:`, error);
    return { success: false, error: error.message };
  }
}

module.exports = {
  sendPasswordResetEmail,
  sendWelcomeEmail,
  sendPaymentConfirmEmail,
};
