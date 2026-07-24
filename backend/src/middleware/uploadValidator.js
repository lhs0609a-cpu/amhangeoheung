/**
 * 파일 업로드 유효성 검사 미들웨어
 * base64 업로드에 대한 크기, 타입, 매직넘버 검증
 */

// 허용된 이미지 MIME 타입과 매직넘버
const IMAGE_SIGNATURES = {
  'image/jpeg': [0xFF, 0xD8, 0xFF],
  'image/png': [0x89, 0x50, 0x4E, 0x47],
  'image/gif': [0x47, 0x49, 0x46],
  'image/webp': null, // RIFF header 별도 체크
};

const VIDEO_SIGNATURES = {
  'video/mp4': null, // ftyp 체크
  'video/quicktime': null,
};

// 매직넘버로 파일 타입 확인
const detectFileType = (buffer) => {
  if (buffer.length < 4) return null;

  // JPEG
  if (buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF) {
    return 'image/jpeg';
  }
  // PNG
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47) {
    return 'image/png';
  }
  // GIF
  if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) {
    return 'image/gif';
  }
  // WebP (RIFF....WEBP)
  if (buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46 &&
      buffer.length > 11 && buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50) {
    return 'image/webp';
  }
  // MP4/MOV (ftyp box)
  if (buffer.length > 7) {
    const ftyp = buffer.slice(4, 8).toString('ascii');
    if (ftyp === 'ftyp') return 'video/mp4';
  }
  // PDF
  if (buffer[0] === 0x25 && buffer[1] === 0x50 && buffer[2] === 0x44 && buffer[3] === 0x46) {
    return 'application/pdf';
  }

  return null;
};

// base64 이미지 검증
const validateBase64Image = (base64, maxSizeMB = 5) => {
  if (!base64 || typeof base64 !== 'string') {
    return { valid: false, error: '이미지 데이터가 필요합니다.' };
  }

  // data URL prefix 제거
  const raw = base64.replace(/^data:image\/\w+;base64,/, '');

  // base64 크기 계산 (대략 원본의 4/3)
  const sizeBytes = Math.ceil(raw.length * 0.75);
  const maxSizeBytes = maxSizeMB * 1024 * 1024;

  if (sizeBytes > maxSizeBytes) {
    return { valid: false, error: `이미지 크기는 ${maxSizeMB}MB 이하여야 합니다.` };
  }

  // 매직넘버 확인
  try {
    const buffer = Buffer.from(raw, 'base64');
    const detectedType = detectFileType(buffer);

    if (!detectedType || !IMAGE_SIGNATURES.hasOwnProperty(detectedType)) {
      return { valid: false, error: '허용되지 않은 이미지 형식입니다. (JPEG, PNG, GIF, WebP만 허용)' };
    }

    return { valid: true, buffer, mimeType: detectedType };
  } catch (e) {
    return { valid: false, error: '유효하지 않은 이미지 데이터입니다.' };
  }
};

// base64 비디오 검증
const validateBase64Video = (base64, maxSizeMB = 50) => {
  if (!base64 || typeof base64 !== 'string') {
    return { valid: false, error: '영상 데이터가 필요합니다.' };
  }

  const raw = base64.replace(/^data:video\/\w+;base64,/, '');
  const sizeBytes = Math.ceil(raw.length * 0.75);
  const maxSizeBytes = maxSizeMB * 1024 * 1024;

  if (sizeBytes > maxSizeBytes) {
    return { valid: false, error: `영상 크기는 ${maxSizeMB}MB 이하여야 합니다.` };
  }

  try {
    const buffer = Buffer.from(raw, 'base64');
    const detectedType = detectFileType(buffer);

    if (!detectedType || (!detectedType.startsWith('video/') && detectedType !== 'video/mp4')) {
      return { valid: false, error: '허용되지 않은 영상 형식입니다. (MP4만 허용)' };
    }

    return { valid: true, buffer, mimeType: detectedType };
  } catch (e) {
    return { valid: false, error: '유효하지 않은 영상 데이터입니다.' };
  }
};

// 아바타 업로드 미들웨어
const validateAvatarUpload = (req, res, next) => {
  const { base64 } = req.body;
  const result = validateBase64Image(base64, 5); // 5MB

  if (!result.valid) {
    return res.status(400).json({
      success: false,
      message: result.error
    });
  }

  req.validatedFile = result;
  next();
};

// 업체 이미지 업로드 미들웨어
const validateBusinessImages = (req, res, next) => {
  const { images } = req.body;

  if (!Array.isArray(images) || images.length === 0) {
    return res.status(400).json({
      success: false,
      message: '이미지가 필요합니다.'
    });
  }

  if (images.length > 10) {
    return res.status(400).json({
      success: false,
      message: '이미지는 최대 10장까지 업로드할 수 있습니다.'
    });
  }

  for (let i = 0; i < images.length; i++) {
    const result = validateBase64Image(images[i].base64 || images[i], 5);
    if (!result.valid) {
      return res.status(400).json({
        success: false,
        message: `이미지 ${i + 1}: ${result.error}`
      });
    }
  }

  next();
};

// 리뷰 사진 업로드 미들웨어
const validateReviewPhotos = (req, res, next) => {
  const { photos } = req.body;

  if (!Array.isArray(photos) || photos.length === 0) {
    return res.status(400).json({
      success: false,
      message: '사진이 필요합니다.'
    });
  }

  if (photos.length > 20) {
    return res.status(400).json({
      success: false,
      message: '사진은 최대 20장까지 업로드할 수 있습니다.'
    });
  }

  for (let i = 0; i < photos.length; i++) {
    const result = validateBase64Image(photos[i].base64 || photos[i], 5);
    if (!result.valid) {
      return res.status(400).json({
        success: false,
        message: `사진 ${i + 1}: ${result.error}`
      });
    }
  }

  next();
};

// 영수증 업로드 미들웨어
const validateReceiptUpload = (req, res, next) => {
  const { base64 } = req.body;
  const result = validateBase64Image(base64, 10); // 10MB

  if (!result.valid) {
    return res.status(400).json({
      success: false,
      message: result.error
    });
  }

  req.validatedFile = result;
  next();
};

// 영상 업로드 미들웨어
const validateVideoUpload = (req, res, next) => {
  const { base64 } = req.body;
  const result = validateBase64Video(base64, 50); // 50MB

  if (!result.valid) {
    return res.status(400).json({
      success: false,
      message: result.error
    });
  }

  req.validatedFile = result;
  next();
};

module.exports = {
  validateBase64Image,
  validateBase64Video,
  detectFileType,
  validateAvatarUpload,
  validateBusinessImages,
  validateReviewPhotos,
  validateReceiptUpload,
  validateVideoUpload,
};
