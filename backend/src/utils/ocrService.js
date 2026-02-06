const https = require('https');

const GOOGLE_VISION_API_KEY = process.env.GOOGLE_VISION_API_KEY;

/**
 * Google Vision API로 영수증 OCR 분석
 */
async function analyzeReceipt(imageBase64) {
  if (!GOOGLE_VISION_API_KEY || GOOGLE_VISION_API_KEY === 'your_google_vision_api_key_here') {
    console.warn('[OCR] Google Vision API key not configured, skipping OCR');
    return { success: false, error: 'OCR service not configured' };
  }

  try {
    const requestBody = JSON.stringify({
      requests: [{
        image: { content: imageBase64 },
        features: [{ type: 'TEXT_DETECTION', maxResults: 1 }],
      }],
    });
    const result = await new Promise((resolve, reject) => {
      const req = https.request({
        hostname: 'vision.googleapis.com',
        path: `/v1/images:annotate?key=${GOOGLE_VISION_API_KEY}`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(requestBody),
        },
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error('Failed to parse Vision API response'));
          }
        });
      });

      req.on('error', reject);
      req.write(requestBody);
      req.end();
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    const responses = result.responses;
    if (!responses || responses.length === 0 || !responses[0].textAnnotations) {
      return { success: true, rawText: '', storeName: null, amount: null, date: null, confidence: 0 };
    }

    const rawText = responses[0].textAnnotations[0].description || '';
    const parsed = parseReceiptText(rawText);

    return {
      success: true,
      rawText,
      storeName: parsed.storeName,
      amount: parsed.amount,
      date: parsed.date,
      confidence: parsed.confidence,
    };
  } catch (error) {
    console.error('[OCR] Google Vision API error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * OCR 텍스트에서 영수증 정보 추출
 */
function parseReceiptText(text) {
  let storeName = null;
  let amount = null;
  let date = null;
  let confidence = 0;

  const lines = text.split('\n').map(l => l.trim()).filter(Boolean);

  // 업체명 추출 (보통 첫 몇 줄에 위치)
  if (lines.length > 0) {
    // 사업자번호, 전화번호가 아닌 첫 번째 의미있는 라인
    for (const line of lines.slice(0, 5)) {
      if (!/^\d{3}-\d{2}-\d{5}/.test(line) && !/^(tel|TEL|전화|T\.)/.test(line) && line.length >= 2 && line.length <= 30) {
        storeName = line;
        confidence += 0.3;
        break;
      }
    }
  }

  // 금액 추출 (합계, 총액, 결제금액 등 키워드 기반)
  const amountPatterns = [
    /(?:합계|총[액계]|결제.?금액|총.?금액|TOTAL)\s*[:\s]*[\D]*?([\d,]+)\s*원?/i,
    /(?:카드|현금|승인).?금액\s*[:\s]*[\D]*?([\d,]+)\s*원?/i,
  ];

  for (const pattern of amountPatterns) {
    const match = text.match(pattern);
    if (match) {
      amount = parseInt(match[1].replace(/,/g, ''), 10);
      if (!isNaN(amount)) {
        confidence += 0.3;
        break;
      }
      amount = null;
    }
  }

  // 날짜 추출
  const datePatterns = [
    /(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})/,
    /(\d{2})[.\-/](\d{1,2})[.\-/](\d{1,2})/,
  ];

  for (const pattern of datePatterns) {
    const match = text.match(pattern);
    if (match) {
      let year = parseInt(match[1], 10);
      if (year < 100) year += 2000;
      const month = parseInt(match[2], 10);
      const day = parseInt(match[3], 10);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        date = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        confidence += 0.3;
        break;
      }
    }
  }

  // confidence는 0~1 범위
  confidence = Math.min(1, confidence);

  return { storeName, amount, date, confidence };
}

module.exports = { analyzeReceipt };
