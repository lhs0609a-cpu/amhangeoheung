const supabase = require('../config/supabase');
const sharp = require('sharp');
const {
  stripPhotoMetadata,
  fuzzyDate,
  getTimeSlot,
  anonymizeReviewText,
  generateAnonymousId,
} = require('../utils/anonymizer');
const { auditReview } = require('./qualityAuditController');
const { createDetectionTest } = require('./detectionTestController');
const { analyzeReviewPattern } = require('./collusionController');
const { updateTrustWeightedRating } = require('../services/trustScoreService');

const PREVIEW_PERIOD_HOURS = 72; // 3일

/**
 * 리뷰 선공개 프로세스 설명
 *
 * 1. 리뷰어가 리뷰 제출 (status: submitted)
 * 2. 업체에 선공개 시작 (72시간 동안)
 *    - 업체는 리뷰를 미리 볼 수 있음
 *    - 업체는 답변 및 개선 약속을 작성할 수 있음
 *    - 문제가 있으면 이의 제기 가능
 * 3. 72시간 후 자동 공개 (status: published)
 *    - 이의 제기 없으면 자동 공개
 *    - 리뷰어에게 보상 지급
 * 4. 이의 제기 시
 *    - 운영팀 검토 (status: disputed)
 *    - 에스크로 보류
 *    - 검토 결과에 따라 공개/비공개 결정
 */

// 리뷰 작성
exports.createReview = async (req, res, next) => {
  try {
    const { missionId, scores, content, topics, tips } = req.body;

    const { data: mission, error: missionError } = await supabase
      .from('missions')
      .select('id, business_id, assigned_reviewer_id')
      .eq('id', missionId)
      .single();

    if (missionError || !mission || mission.assigned_reviewer_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '미션을 찾을 수 없습니다.'
      });
    }

    // 단점 필수 체크
    if (!content.cons || content.cons.length === 0) {
      return res.status(400).json({
        success: false,
        message: '개선점/단점을 최소 1개 이상 작성해야 합니다.'
      });
    }

    // 총점 계산
    const scoreValues = Object.values(scores);
    const totalScore = scoreValues.reduce((a, b) => a + b, 0) / scoreValues.length;

    const { data: review, error } = await supabase
      .from('reviews')
      .insert({
        mission_id: missionId,
        business_id: mission.business_id,
        reviewer_id: req.user.id,
        content_pros: content.pros,
        content_cons: content.cons,
        content_summary: content.summary,
        content_tips: tips || null,
        total_score: totalScore,
        status: 'draft',
        drafted_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    // 개별 점수 저장
    const scoreEntries = Object.entries(scores).map(([category, score]) => ({
      review_id: review.id,
      category,
      score
    }));

    await supabase.from('review_scores').insert(scoreEntries);

    // 토픽 저장
    if (topics && Array.isArray(topics) && topics.length > 0) {
      const topicEntries = topics.map(t => ({
        review_id: review.id,
        topic_key: t.topicKey || t.topic_key,
        topic_label: t.topicLabel || t.topic_label,
        topic_type: t.topicType || t.topic_type || 'positive',
      }));
      await supabase.from('review_topics').insert(topicEntries);
    }

    res.status(201).json({
      success: true,
      message: '리뷰 초안이 저장되었습니다.',
      data: { review }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 수정
exports.updateReview = async (req, res, next) => {
  try {
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .eq('status', 'draft')
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '수정할 수 없는 리뷰입니다.'
      });
    }

    const { scores, content } = req.body;
    const updates = {};

    if (content) {
      if (content.pros) updates.content_pros = content.pros;
      if (content.cons) updates.content_cons = content.cons;
      if (content.summary) updates.content_summary = content.summary;
    }

    if (scores) {
      const scoreValues = Object.values(scores);
      updates.total_score = scoreValues.reduce((a, b) => a + b, 0) / scoreValues.length;

      // 점수 업데이트
      await supabase.from('review_scores').delete().eq('review_id', req.params.id);
      const scoreEntries = Object.entries(scores).map(([category, score]) => ({
        review_id: req.params.id,
        category,
        score
      }));
      await supabase.from('review_scores').insert(scoreEntries);
    }

    const { data: updatedReview, error } = await supabase
      .from('reviews')
      .update(updates)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      data: { review: updatedReview }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 제출
exports.submitReview = async (req, res, next) => {
  try {
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('*')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .eq('status', 'draft')
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '제출할 수 없는 리뷰입니다.'
      });
    }

    // 필수 항목 체크 - 사진 확인
    const { count: photoCount } = await supabase
      .from('review_photos')
      .select('*', { count: 'exact', head: true })
      .eq('review_id', req.params.id);

    if (!photoCount || photoCount < 3) {
      return res.status(400).json({
        success: false,
        message: '사진을 최소 3장 이상 첨부해야 합니다.'
      });
    }

    // 익명화 처리: 방문 날짜/시간 퍼지
    const mission = await supabase
      .from('missions')
      .select('check_in_time, business:businesses(owner_id)')
      .eq('id', review.mission_id)
      .single()
      .then(r => r.data);

    let displayVisitDate = null;
    let displayTimeSlot = null;
    if (mission?.check_in_time) {
      displayVisitDate = fuzzyDate(mission.check_in_time);
      displayTimeSlot = getTimeSlot(mission.check_in_time);
    }

    // 리뷰 텍스트 익명화 (공개 버전)
    const anonymizedSummary = anonymizeReviewText(review.content_summary);

    // 업체 선공개 시작 시간 설정
    const previewStartAt = new Date();
    previewStartAt.setHours(previewStartAt.getHours() + 72); // 3일 후

    const { error } = await supabase
      .from('reviews')
      .update({
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        preview_start_at: previewStartAt.toISOString(),
        display_visit_date: displayVisitDate,
        display_time_slot: displayTimeSlot,
        anonymized_at: new Date().toISOString(),
      })
      .eq('id', req.params.id);

    if (error) throw error;

    // 미션 상태 업데이트
    await supabase
      .from('missions')
      .update({
        status: 'review_submitted',
        review_submitted_at: new Date().toISOString()
      })
      .eq('id', review.mission_id);

    // 업체에게 선공개 알림
    if (mission?.business?.owner_id) {
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        mission.business.owner_id,
        'review_submitted',
        '새 리뷰가 제출되었습니다',
        '72시간 선공개 기간 동안 리뷰를 확인하고 답변할 수 있습니다.',
        { reviewId: req.params.id, missionId: review.mission_id }
      );
    }

    // 비동기: 품질 감사 + 역탐지 테스트 생성 + 담합 패턴 분석
    Promise.all([
      auditReview(req.params.id).catch(e => console.error('[SUBMIT_REVIEW] Audit error:', e.message)),
      createDetectionTest(review.mission_id).catch(e => console.error('[SUBMIT_REVIEW] Detection test error:', e.message)),
      analyzeReviewPattern(req.user.id).catch(e => console.error('[SUBMIT_REVIEW] Collusion analyze error:', e.message)),
    ]);

    res.json({
      success: true,
      message: '리뷰가 제출되었습니다. 검토 후 업체에 선공개됩니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 사진 업로드
exports.uploadPhotos = async (req, res, next) => {
  try {
    // S7: UUID 형식 검증
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(req.params.id)) {
      return res.status(400).json({ success: false, message: '잘못된 리뷰 ID입니다.' });
    }

    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    const { photos } = req.body; // [{url, caption}] 또는 base64 데이터

    // 기존 사진 삭제
    const { data: existingPhotos } = await supabase
      .from('review_photos')
      .select('photo_url')
      .eq('review_id', req.params.id);

    // Storage에서 기존 파일 삭제
    if (existingPhotos && existingPhotos.length > 0) {
      const filesToDelete = existingPhotos
        .map(p => p.photo_url)
        .filter(url => url && url.includes('review-photos/'))
        .map(url => {
          const parts = url.split('review-photos/');
          return parts.length > 1 ? parts[1] : null;
        })
        .filter(Boolean);

      if (filesToDelete.length > 0) {
        await supabase.storage.from('review-photos').remove(filesToDelete);
      }
    }

    // DB에서 기존 레코드 삭제
    await supabase.from('review_photos').delete().eq('review_id', req.params.id);

    // 새 사진 업로드 및 저장
    const uploadedPhotos = [];
    for (let i = 0; i < photos.length; i++) {
      const photo = photos[i];
      let photoUrl = photo.url;

      // base64 데이터인 경우 Storage에 업로드
      if (photo.base64) {
        const fileName = `${req.params.id}/${Date.now()}_${i}.jpg`;
        let buffer = Buffer.from(photo.base64, 'base64');

        // Strip EXIF metadata for anonymity
        try {
          buffer = await sharp(buffer).jpeg({ quality: 90 }).toBuffer();
        } catch (stripErr) {
          console.warn('EXIF strip failed, using original:', stripErr.message);
        }

        // EXIF 메타데이터 제거 (GPS, 촬영시간, 카메라 정보 등)
        buffer = await stripPhotoMetadata(buffer);

        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('review-photos')
          .upload(fileName, buffer, {
            contentType: 'image/jpeg',
            upsert: true
          });

        if (uploadError) {
          console.error('Photo upload error:', uploadError);
          continue;
        }

        // Public URL 생성
        const { data: urlData } = supabase.storage
          .from('review-photos')
          .getPublicUrl(fileName);

        photoUrl = urlData.publicUrl;
      }

      uploadedPhotos.push({
        review_id: req.params.id,
        photo_url: photoUrl,
        caption: photo.caption || '',
        sort_order: i
      });
    }

    if (uploadedPhotos.length > 0) {
      const { error } = await supabase.from('review_photos').insert(uploadedPhotos);
      if (error) throw error;
    }

    res.json({
      success: true,
      message: `${uploadedPhotos.length}장의 사진이 업로드되었습니다.`,
      data: {
        count: uploadedPhotos.length,
        photos: uploadedPhotos.map(p => ({ url: p.photo_url, caption: p.caption }))
      }
    });
  } catch (error) {
    next(error);
  }
};

// 영수증 업로드 + OCR 분석
// 영수증 사용 등록 (재사용 방지용 기록). :id 는 미션 ID.
// 클라이언트는 fire-and-forget 로 호출하므로 실패해도 흐름을 막지 않는다.
exports.registerReceiptUsage = async (req, res, next) => {
  try {
    const missionId = req.params.id;

    await supabase.from('analytics_events').insert({
      user_id: req.user.id,
      event_name: 'receipt_usage',
      event_category: 'review',
      event_data: { mission_id: missionId },
    });

    res.json({
      success: true,
      message: '영수증 사용이 기록되었습니다.',
    });
  } catch (error) {
    next(error);
  }
};

exports.uploadReceipt = async (req, res, next) => {
  try {
    // S7: UUID 형식 검증
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(req.params.id)) {
      return res.status(400).json({ success: false, message: '잘못된 리뷰 ID입니다.' });
    }

    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    const { imageBase64, imageUrl } = req.body;

    if (!imageBase64 && !imageUrl) {
      return res.status(400).json({
        success: false,
        message: '영수증 이미지가 필요합니다.'
      });
    }

    // 이미지를 Supabase Storage에 업로드
    let receiptImageUrl = imageUrl;
    if (imageBase64) {
      const fileName = `receipts/${req.params.id}/${Date.now()}.jpg`;
      let buffer = Buffer.from(imageBase64, 'base64');

      // Strip EXIF metadata for anonymity
      try {
        buffer = await sharp(buffer).jpeg({ quality: 90 }).toBuffer();
      } catch (stripErr) {
        console.warn('EXIF strip failed, using original:', stripErr.message);
      }

      const { error: uploadError } = await supabase.storage
        .from('review-photos')
        .upload(fileName, buffer, {
          contentType: 'image/jpeg',
          upsert: true,
        });

      if (!uploadError) {
        const { data: urlData } = supabase.storage
          .from('review-photos')
          .getPublicUrl(fileName);
        receiptImageUrl = urlData.publicUrl;
      }
    }

    // OCR 분석 실행 및 검증 상태 결정
    //
    // 정책(fail-closed): OCR 이 성공적으로 실행되고 신뢰도가 임계값 이상일 때만
    // 자동 승인한다. OCR 미설정 / 런타임 실패 / 낮은 신뢰도는 절대 자동 승인하지
    // 않고 'manual_review_required' 로 표시해 사람이 검토하도록 한다.
    const OCR_AUTO_VERIFY_THRESHOLD = 0.6;
    let ocrData = null;
    let reviewStatus = 'manual_review_required'; // 기본값: 안전측
    let receiptVerified = false;

    if (imageBase64) {
      try {
        const { analyzeReceipt } = require('../utils/ocrService');
        const ocrResult = await analyzeReceipt(imageBase64);
        if (ocrResult.success) {
          ocrData = {
            storeName: ocrResult.storeName,
            totalAmount: ocrResult.amount,
            purchaseDate: ocrResult.date,
            rawText: ocrResult.rawText,
            confidence: ocrResult.confidence,
          };
          if (ocrResult.confidence >= OCR_AUTO_VERIFY_THRESHOLD) {
            reviewStatus = 'auto_verified';
            receiptVerified = true;
          } else {
            // OCR 은 됐지만 신뢰도가 낮음 → 수동 검토
            reviewStatus = 'manual_review_required';
          }
        } else if (ocrResult.notConfigured) {
          // OCR 연동 미설정 → 수동 검토 큐 (자동 승인 절대 금지)
          console.warn('[OCR] not configured — routing receipt to manual review');
          reviewStatus = 'manual_review_required';
        } else {
          // OCR 런타임 실패 → 수동 검토 큐
          reviewStatus = 'manual_review_required';
        }
      } catch (ocrError) {
        // OCR 실패해도 이미지는 저장하고 수동 검토로 보낸다
        console.error('[OCR] Receipt analysis failed:', ocrError);
        reviewStatus = 'manual_review_required';
      }
    }

    const { error } = await supabase
      .from('reviews')
      .update({
        receipt_image_url: receiptImageUrl,
        receipt_ocr_data: ocrData,
        receipt_verified: receiptVerified,
        receipt_review_status: reviewStatus,
        receipt_uploaded_at: new Date().toISOString(),
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: reviewStatus === 'auto_verified'
        ? '영수증이 업로드되어 자동 검증되었습니다.'
        : '영수증이 업로드되었습니다. 검토 후 승인됩니다.',
      data: {
        imageUrl: receiptImageUrl,
        reviewStatus,
        ocr: ocrData ? {
          storeName: ocrData.storeName,
          amount: ocrData.totalAmount,
          date: ocrData.purchaseDate,
          confidence: ocrData.confidence,
        } : null,
      },
    });
  } catch (error) {
    next(error);
  }
};

// [관리자] 수동 검토 대기 영수증 큐 조회
exports.getReceiptReviewQueue = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error, count } = await supabase
      .from('reviews')
      .select(
        'id, mission_id, business_id, reviewer_id, receipt_image_url, receipt_ocr_data, receipt_uploaded_at, receipt_review_status',
        { count: 'exact' }
      )
      .eq('receipt_review_status', 'manual_review_required')
      .order('receipt_uploaded_at', { ascending: true })
      .range(from, to);

    if (error) throw error;

    res.json({
      success: true,
      data: {
        reviews: data || [],
        pagination: { page, limit, total: count || 0 },
      },
    });
  } catch (error) {
    next(error);
  }
};

// [관리자] 영수증 수동 검토 결정 (승인/반려)
exports.decideReceiptReview = async (req, res, next) => {
  try {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(req.params.id)) {
      return res.status(400).json({ success: false, message: '잘못된 리뷰 ID입니다.' });
    }

    const { decision, reason } = req.body;
    if (!['approve', 'reject'].includes(decision)) {
      return res.status(400).json({
        success: false,
        message: 'decision 은 approve 또는 reject 여야 합니다.',
      });
    }

    const isApprove = decision === 'approve';
    const { data, error } = await supabase
      .from('reviews')
      .update({
        receipt_review_status: isApprove ? 'approved' : 'rejected',
        receipt_verified: isApprove,
        receipt_review_reason: reason || null,
        receipt_reviewed_by: req.user.id,
        receipt_reviewed_at: new Date().toISOString(),
      })
      .eq('id', req.params.id)
      .eq('receipt_review_status', 'manual_review_required')
      .select('id, receipt_review_status');

    if (error) throw error;
    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: '검토 대기 중인 영수증을 찾을 수 없습니다.',
      });
    }

    res.json({
      success: true,
      message: isApprove ? '영수증을 승인했습니다.' : '영수증을 반려했습니다.',
      data: { reviewId: data[0].id, status: data[0].receipt_review_status },
    });
  } catch (error) {
    next(error);
  }
};

// 언박싱 영상 업로드
exports.uploadVideo = async (req, res, next) => {
  try {
    // S7: UUID 형식 검증
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(req.params.id)) {
      return res.status(400).json({ success: false, message: '잘못된 리뷰 ID입니다.' });
    }

    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    const { url, duration, thumbnailUrl } = req.body;

    const { error } = await supabase
      .from('reviews')
      .update({
        unboxing_video_url: url,
        unboxing_video_duration: duration,
        unboxing_video_thumbnail: thumbnailUrl
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '영상이 업로드되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 7일 후 추가 리뷰
exports.submitFollowUpReview = async (req, res, next) => {
  try {
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    const { durabilityScore, usageNotes, issues, photos } = req.body;

    const { error } = await supabase
      .from('follow_up_reviews')
      .insert({
        review_id: req.params.id,
        durability_score: durabilityScore,
        usage_notes: usageNotes,
        issues,
        photos
      });

    if (error) throw error;

    res.json({
      success: true,
      message: '추가 리뷰가 등록되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 내 리뷰 목록
exports.getMyReviews = async (req, res, next) => {
  try {
    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name)
      `)
      .eq('reviewer_id', req.user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 목록 (공개)
exports.getReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name, category, badge_level),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade)
      `)
      .eq('status', 'published')
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (error) throw error;

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 상세
exports.getReview = async (req, res, next) => {
  try {
    const { data: review, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name, category, address_city, badge_level, trust_weighted_rating),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade, trust_score)
      `)
      .eq('id', req.params.id)
      .eq('status', 'published')
      .single();

    if (error || !review) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    // 점수 조회
    const { data: scores } = await supabase
      .from('review_scores')
      .select('category, score')
      .eq('review_id', req.params.id);

    // 사진 조회
    const { data: photos } = await supabase
      .from('review_photos')
      .select('photo_url, caption')
      .eq('review_id', req.params.id)
      .order('sort_order');

    // 토픽 조회
    const { data: topics } = await supabase
      .from('review_topics')
      .select('topic_key, topic_label, topic_type')
      .eq('review_id', req.params.id);

    // 대안 업체 (리뷰 총점 3.0 미만일 때)
    let alternatives = null;
    if (review.total_score < 3.0 && review.business) {
      const { data: altBusinesses } = await supabase
        .from('businesses')
        .select('id, name, category, address_city, badge_level, trust_weighted_rating, average_rating')
        .eq('category', review.business.category)
        .eq('address_city', review.business.address_city)
        .eq('status', 'active')
        .neq('id', review.business_id)
        .order('trust_weighted_rating', { ascending: false })
        .limit(5);

      alternatives = altBusinesses || [];
    }

    res.json({
      success: true,
      data: {
        review: {
          ...review,
          scores,
          photos,
          topics: topics || [],
          contentTips: review.content_tips || null,
          trustWeight: review.trust_weight || 1.0,
          // 업체 답변 (공개 리뷰에서도 노출)
          businessResponse: review.business_response || null,
          improvementPromise: review.improvement_promise || null,
          respondedAt: review.responded_at || null,
          // 대안 업체 (낮은 평점 시)
          alternatives,
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 유용성 투표
exports.markHelpful = async (req, res, next) => {
  try {
    const reviewId = req.params.id;
    const userId = req.user.id;

    // 기존 투표 확인
    const { data: existingVote, error: existingVoteError } = await supabase
      .from('review_votes')
      .select('id, vote_type')
      .eq('review_id', reviewId)
      .eq('user_id', userId)
      .single();

    if (existingVote && !existingVoteError) {
      if (existingVote.vote_type === 'helpful') {
        // 이미 helpful 투표함 - 취소
        await supabase.from('review_votes').delete().eq('id', existingVote.id);
        await supabase.rpc('decrement_helpful_count', { review_id: reviewId });
        return res.json({
          success: true,
          message: '투표가 취소되었습니다.',
          action: 'removed'
        });
      } else {
        // not_helpful에서 helpful로 변경
        await supabase
          .from('review_votes')
          .update({ vote_type: 'helpful', updated_at: new Date().toISOString() })
          .eq('id', existingVote.id);

        // 카운트 업데이트
        const { data: review, error: reviewFetchError } = await supabase
          .from('reviews')
          .select('helpful_count, not_helpful_count')
          .eq('id', reviewId)
          .single();

        if (!reviewFetchError && review) {
          await supabase
            .from('reviews')
            .update({
              helpful_count: (review.helpful_count || 0) + 1,
              not_helpful_count: Math.max(0, (review.not_helpful_count || 0) - 1)
            })
            .eq('id', reviewId);
        }

        return res.json({
          success: true,
          message: '투표가 변경되었습니다.',
          action: 'changed'
        });
      }
    }

    // 새 투표
    await supabase.from('review_votes').insert({
      review_id: reviewId,
      user_id: userId,
      vote_type: 'helpful'
    });

    const { data: review, error: reviewFetchError2 } = await supabase
      .from('reviews')
      .select('helpful_count')
      .eq('id', reviewId)
      .single();

    await supabase
      .from('reviews')
      .update({ helpful_count: (review?.helpful_count || 0) + 1 })
      .eq('id', reviewId);

    res.json({
      success: true,
      message: '도움이 됨으로 투표했습니다.',
      action: 'added'
    });
  } catch (error) {
    next(error);
  }
};

exports.markNotHelpful = async (req, res, next) => {
  try {
    const reviewId = req.params.id;
    const userId = req.user.id;

    // 기존 투표 확인
    const { data: existingVote, error: existingVoteError } = await supabase
      .from('review_votes')
      .select('id, vote_type')
      .eq('review_id', reviewId)
      .eq('user_id', userId)
      .single();

    if (existingVote && !existingVoteError) {
      if (existingVote.vote_type === 'not_helpful') {
        // 이미 not_helpful 투표함 - 취소
        await supabase.from('review_votes').delete().eq('id', existingVote.id);
        await supabase.rpc('decrement_not_helpful_count', { review_id: reviewId });
        return res.json({
          success: true,
          message: '투표가 취소되었습니다.',
          action: 'removed'
        });
      } else {
        // helpful에서 not_helpful로 변경
        await supabase
          .from('review_votes')
          .update({ vote_type: 'not_helpful', updated_at: new Date().toISOString() })
          .eq('id', existingVote.id);

        // 카운트 업데이트
        const { data: review, error: reviewFetchError } = await supabase
          .from('reviews')
          .select('helpful_count, not_helpful_count')
          .eq('id', reviewId)
          .single();

        if (!reviewFetchError && review) {
          await supabase
            .from('reviews')
            .update({
              helpful_count: Math.max(0, (review.helpful_count || 0) - 1),
              not_helpful_count: (review.not_helpful_count || 0) + 1
            })
            .eq('id', reviewId);
        }

        return res.json({
          success: true,
          message: '투표가 변경되었습니다.',
          action: 'changed'
        });
      }
    }

    // 새 투표
    await supabase.from('review_votes').insert({
      review_id: reviewId,
      user_id: userId,
      vote_type: 'not_helpful'
    });

    const { data: review, error: reviewFetchError2 } = await supabase
      .from('reviews')
      .select('not_helpful_count')
      .eq('id', reviewId)
      .single();

    await supabase
      .from('reviews')
      .update({ not_helpful_count: (review?.not_helpful_count || 0) + 1 })
      .eq('id', reviewId);

    res.json({
      success: true,
      message: '도움이 안됨으로 투표했습니다.',
      action: 'added'
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 신고
exports.reportReview = async (req, res, next) => {
  try {
    const reviewId = req.params.id;
    const userId = req.user.id;
    const { reason, category, description } = req.body;

    // 이미 신고했는지 확인
    const { data: existingReport, error: existingReportError } = await supabase
      .from('review_reports')
      .select('id')
      .eq('review_id', reviewId)
      .eq('reporter_id', userId)
      .single();

    if (existingReport && !existingReportError) {
      return res.status(400).json({
        success: false,
        message: '이미 신고한 리뷰입니다.'
      });
    }

    // 신고 내역 저장
    const { error: reportError } = await supabase.from('review_reports').insert({
      review_id: reviewId,
      reporter_id: userId,
      category: category || 'other', // spam, inappropriate, fake, harassment, other
      reason: reason || '',
      description: description || '',
      status: 'pending', // pending, reviewed, resolved, dismissed
      created_at: new Date().toISOString()
    });

    if (reportError) throw reportError;

    // 리뷰 신고 카운트 증가
    const { data: review, error: reviewFetchError } = await supabase
      .from('reviews')
      .select('reported_count')
      .eq('id', reviewId)
      .single();

    const newReportedCount = (review?.reported_count || 0) + 1;

    await supabase
      .from('reviews')
      .update({
        reported_count: newReportedCount,
        // 신고가 5건 이상이면 자동으로 숨김 처리
        is_hidden: newReportedCount >= 5 ? true : undefined
      })
      .eq('id', reviewId);

    // 신고가 5건 이상이면 관리자에게 알림 (로그) + 리뷰어에게 알림
    if (newReportedCount >= 5) {
      console.log(`[ALERT] Review ${reviewId} has been auto-hidden due to ${newReportedCount} reports`);

      // L4: 리뷰어에게 검토 알림 발송
      const { data: hiddenReview, error: hiddenReviewError } = await supabase
        .from('reviews')
        .select('reviewer_id')
        .eq('id', reviewId)
        .single();

      if (hiddenReview?.reviewer_id) {
        const { createNotification } = require('../utils/notificationService');
        await createNotification(
          hiddenReview.reviewer_id,
          'system',
          '리뷰 검토 알림',
          '작성하신 리뷰가 다수의 신고로 인해 검토 중입니다. 문제가 없으면 다시 공개됩니다.',
          { reviewId }
        );
      }
    }

    res.json({
      success: true,
      message: '신고가 접수되었습니다. 검토 후 조치하겠습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 리뷰 요청
exports.requestReview = async (req, res, next) => {
  try {
    const { businessId, reason } = req.body;

    if (!businessId) {
      return res.status(400).json({
        success: false,
        message: '업체 ID가 필요합니다.'
      });
    }

    // 업체 존재 확인
    const { data: business, error: businessError } = await supabase
      .from('businesses')
      .select('id, name')
      .eq('id', businessId)
      .eq('status', 'active')
      .single();

    if (businessError || !business) {
      return res.status(404).json({
        success: false,
        message: '업체를 찾을 수 없습니다.'
      });
    }

    // 이미 요청했는지 확인
    const { data: existingRequest, error: existingRequestError } = await supabase
      .from('review_requests')
      .select('id')
      .eq('business_id', businessId)
      .eq('requester_id', req.user.id)
      .eq('status', 'pending')
      .single();

    if (existingRequest && !existingRequestError) {
      return res.status(400).json({
        success: false,
        message: '이미 해당 업체에 리뷰를 요청했습니다.'
      });
    }

    // 리뷰 요청 저장
    const { error: insertError } = await supabase
      .from('review_requests')
      .insert({
        business_id: businessId,
        requester_id: req.user.id,
        reason: reason || '',
        status: 'pending',
        created_at: new Date().toISOString()
      });

    if (insertError) throw insertError;

    // 업체의 리뷰 요청 수 증가
    const { data: currentBusiness, error: currentBusinessError } = await supabase
      .from('businesses')
      .select('review_request_count')
      .eq('id', businessId)
      .single();

    await supabase
      .from('businesses')
      .update({
        review_request_count: (currentBusiness?.review_request_count || 0) + 1
      })
      .eq('id', businessId);

    res.json({
      success: true,
      message: '리뷰 요청이 등록되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 선공개 리뷰 목록 (업체용)
exports.getPreviewReviews = async (req, res, next) => {
  try {
    // 사용자가 소유한 업체 조회
    const { data: businesses } = await supabase
      .from('businesses')
      .select('id')
      .eq('owner_id', req.user.id);

    if (!businesses || businesses.length === 0) {
      return res.json({
        success: true,
        data: {
          reviews: [],
          previewInfo: {
            title: '선공개 리뷰란?',
            description: '리뷰가 공개되기 전 72시간 동안 미리 확인할 수 있는 기간입니다.',
            benefits: [
              '리뷰 내용을 미리 확인',
              '업체 답변 작성 가능',
              '개선 약속 등록 가능',
              '문제 시 이의 제기 가능'
            ]
          }
        }
      });
    }

    const businessIds = businesses.map(b => b.id);

    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade),
        scores:review_scores(category, score),
        photos:review_photos(photo_url, caption)
      `)
      .in('business_id', businessIds)
      .in('status', ['submitted', 'preview'])
      .order('submitted_at', { ascending: false });

    if (error) throw error;

    const now = new Date();
    const reviewsWithCountdown = (reviews || []).map(review => {
      // 익명화: 리뷰어 정보 숨김
      if (review.reviewer) {
        review.reviewer = {
          id: null,
          nickname: generateAnonymousId(review.reviewer.id),
          reviewer_grade: review.reviewer.reviewer_grade,
          profile_image: null,
        };
      }

      // submitted_at 시점으로부터 72시간이 선공개 종료 시점
      const submittedAt = new Date(review.submitted_at);
      const previewEndsAt = new Date(submittedAt.getTime() + PREVIEW_PERIOD_HOURS * 3600000);
      const remainingMs = previewEndsAt.getTime() - now.getTime();
      const remainingHours = Math.max(0, Math.ceil(remainingMs / 3600000));

      return {
        ...review,
        preview: {
          submittedAt: review.submitted_at,
          endsAt: previewEndsAt.toISOString(),
          remainingHours,
          remainingFormatted: formatRemainingTime(remainingMs),
          status: remainingHours > 0 ? 'active' : 'expired',
          canRespond: !review.business_response,
          canDispute: remainingHours > 0 && !review.is_disputed,
          timeline: buildPreviewTimeline(review, previewEndsAt)
        }
      };
    });

    res.json({
      success: true,
      data: {
        reviews: reviewsWithCountdown,
        previewInfo: {
          title: '선공개 리뷰',
          description: '리뷰가 공개되기 전 72시간 동안 미리 확인하고 대응할 수 있습니다.',
          benefits: [
            '리뷰 내용을 미리 확인',
            '업체 답변 작성 가능',
            '개선 약속 등록 가능',
            '문제 시 이의 제기 가능'
          ],
          processSteps: [
            { step: 1, title: '리뷰 제출', description: '리뷰어가 미션을 완료하고 리뷰를 제출합니다.' },
            { step: 2, title: '선공개 시작', description: '업체에 리뷰가 선공개되어 72시간 동안 확인 가능합니다.' },
            { step: 3, title: '업체 대응', description: '답변 작성, 개선 약속, 이의 제기를 할 수 있습니다.' },
            { step: 4, title: '자동 공개', description: '72시간 후 이의 제기가 없으면 자동으로 공개됩니다.' }
          ]
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 남은 시간 포맷팅 헬퍼
function formatRemainingTime(ms) {
  if (ms <= 0) return '만료됨';

  const hours = Math.floor(ms / 3600000);
  const minutes = Math.floor((ms % 3600000) / 60000);

  if (hours >= 24) {
    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;
    return `${days}일 ${remainingHours}시간`;
  }

  return `${hours}시간 ${minutes}분`;
}

// 선공개 타임라인 생성 헬퍼
function buildPreviewTimeline(review, previewEndsAt) {
  const timeline = [];

  // 1. 리뷰 제출
  timeline.push({
    event: 'submitted',
    title: '리뷰 제출',
    date: review.submitted_at,
    completed: true
  });

  // 2. 선공개 시작
  timeline.push({
    event: 'preview_started',
    title: '선공개 시작',
    date: review.submitted_at,
    completed: true
  });

  // 3. 업체 답변 (선택)
  timeline.push({
    event: 'business_response',
    title: '업체 답변',
    date: review.responded_at,
    completed: !!review.business_response
  });

  // 4. 자동 공개 예정
  timeline.push({
    event: 'auto_publish',
    title: '자동 공개',
    date: previewEndsAt.toISOString(),
    completed: false,
    isPending: true
  });

  return timeline;
}

// 선공개 리뷰 조회 (업체용)
exports.getPreviewReview = async (req, res, next) => {
  try {
    const { data: review, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name, owner_id),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade),
        scores:review_scores(category, score),
        photos:review_photos(photo_url, caption)
      `)
      .eq('id', req.params.id)
      .in('status', ['preview', 'submitted'])
      .single();

    if (error || !review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    // 익명화: 사업자에게 리뷰어 정보 숨김
    if (review.reviewer) {
      review.reviewer = {
        id: null,
        nickname: generateAnonymousId(review.reviewer.id),
        reviewer_grade: review.reviewer.reviewer_grade,
        profile_image: null, // 프로필 사진 미노출
      };
    }

    const submittedAt = new Date(review.submitted_at);
    const previewEndsAt = new Date(submittedAt.getTime() + PREVIEW_PERIOD_HOURS * 3600000);
    const now = new Date();
    const remainingMs = previewEndsAt.getTime() - now.getTime();

    res.json({
      success: true,
      data: {
        review,
        preview: {
          submittedAt: review.submitted_at,
          endsAt: previewEndsAt.toISOString(),
          remainingHours: Math.max(0, Math.ceil(remainingMs / 3600000)),
          remainingFormatted: formatRemainingTime(remainingMs),
          status: remainingMs > 0 ? 'active' : 'expired',
          canRespond: !review.business_response,
          canDispute: remainingMs > 0 && !review.is_disputed,
          timeline: buildPreviewTimeline(review, previewEndsAt)
        },
        actions: {
          respond: {
            available: !review.business_response,
            description: '리뷰에 대한 답변과 개선 약속을 작성할 수 있습니다.'
          },
          dispute: {
            available: remainingMs > 0 && !review.is_disputed,
            description: '리뷰 내용에 문제가 있다면 이의를 제기할 수 있습니다.',
            warning: '이의 제기 시 운영팀 검토가 진행되며, 검토 기간 동안 리뷰 공개가 보류됩니다.'
          }
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// 업체 답변 (선공개 + 공개된 리뷰 모두 가능)
exports.submitBusinessResponse = async (req, res, next) => {
  try {
    const { content, improvementPromise } = req.body;

    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select(`
        id, status,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (reviewError || !review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    // 선공개, 공개, 이의제기 상태에서만 답변 가능
    const allowedStatuses = ['submitted', 'preview', 'published', 'disputed'];
    if (!allowedStatuses.includes(review.status)) {
      return res.status(400).json({
        success: false,
        message: '답변을 등록할 수 없는 상태입니다.'
      });
    }

    const { error } = await supabase
      .from('reviews')
      .update({
        business_response: content,
        improvement_promise: improvementPromise,
        responded_at: new Date().toISOString()
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '답변이 등록되었습니다.'
    });
  } catch (error) {
    next(error);
  }
};

// 이의 제기 (증거 첨부 지원)
exports.disputeReview = async (req, res, next) => {
  try {
    const { reason, evidences } = req.body;
    // evidences: [{fileUrl, fileType, description}] (선택)

    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select(`
        id, mission_id,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (reviewError || !review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    // 72시간 해결 기한 설정
    const resolutionDeadline = new Date();
    resolutionDeadline.setHours(resolutionDeadline.getHours() + 72);

    const { error } = await supabase
      .from('reviews')
      .update({
        is_disputed: true,
        dispute_reason: reason,
        dispute_filed_by: 'business',
        dispute_filed_at: new Date().toISOString(),
        dispute_status: 'pending',
        dispute_resolution_deadline: resolutionDeadline.toISOString(),
        status: 'disputed'
      })
      .eq('id', req.params.id);

    if (error) throw error;

    // 증거 첨부 저장
    if (evidences && evidences.length > 0) {
      const evidenceRows = evidences.map(e => ({
        review_id: req.params.id,
        uploaded_by: req.user.id,
        file_url: e.fileUrl,
        file_type: e.fileType || 'image',
        description: e.description || '',
      }));
      await supabase.from('dispute_evidences').insert(evidenceRows);
    }

    // 에스크로 보류
    await supabase
      .from('escrows')
      .update({
        status: 'held',
        hold_reason: reason,
        held_at: new Date().toISOString()
      })
      .eq('mission_id', review.mission_id);

    // 운영팀 알림
    const { createNotification } = require('../utils/notificationService');
    // 관리자에게 알림 (시스템 알림으로 처리)
    console.log(`[DISPUTE] Review ${req.params.id} disputed by business. Deadline: ${resolutionDeadline.toISOString()}`);

    res.json({
      success: true,
      message: '이의 제기가 접수되었습니다. 72시간 내에 운영팀에서 검토합니다.',
      data: {
        disputeStatus: 'pending',
        resolutionDeadline: resolutionDeadline.toISOString(),
      }
    });
  } catch (error) {
    next(error);
  }
};

// 이의 제기에 증거 추가 업로드
exports.uploadDisputeEvidence = async (req, res, next) => {
  try {
    const { fileUrl, fileType, description } = req.body;

    // 리뷰 소유 확인 (업체)
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select(`
        id, is_disputed,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (reviewError || !review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    if (!review.is_disputed) {
      return res.status(400).json({
        success: false,
        message: '이의 제기된 리뷰에만 증거를 첨부할 수 있습니다.'
      });
    }

    const { data: evidence, error } = await supabase
      .from('dispute_evidences')
      .insert({
        review_id: req.params.id,
        uploaded_by: req.user.id,
        file_url: fileUrl,
        file_type: fileType || 'image',
        description: description || '',
      })
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: '증거 자료가 업로드되었습니다.',
      data: { evidence }
    });
  } catch (error) {
    next(error);
  }
};

// 이의 제기 상태 조회 (업체용)
exports.getDisputeStatus = async (req, res, next) => {
  try {
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select(`
        id, dispute_reason, dispute_filed_at, dispute_status,
        dispute_outcome, dispute_resolution, dispute_resolved_at,
        dispute_resolution_deadline, dispute_admin_notes,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (reviewError || !review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    // 증거 자료 조회
    const { data: evidences } = await supabase
      .from('dispute_evidences')
      .select('id, file_url, file_type, description, created_at')
      .eq('review_id', req.params.id)
      .order('created_at', { ascending: true });

    // 남은 시간 계산
    let remainingHours = null;
    if (review.dispute_resolution_deadline) {
      const deadline = new Date(review.dispute_resolution_deadline);
      const now = new Date();
      remainingHours = Math.max(0, Math.ceil((deadline.getTime() - now.getTime()) / 3600000));
    }

    res.json({
      success: true,
      data: {
        disputeStatus: review.dispute_status || 'pending',
        reason: review.dispute_reason,
        filedAt: review.dispute_filed_at,
        resolutionDeadline: review.dispute_resolution_deadline,
        remainingHours,
        outcome: review.dispute_outcome,
        resolution: review.dispute_resolution,
        resolvedAt: review.dispute_resolved_at,
        evidences: evidences || [],
        timeline: buildDisputeTimeline(review),
      }
    });
  } catch (error) {
    next(error);
  }
};

// 이의 제기 목록 (관리자용)
exports.getDisputes = async (req, res, next) => {
  try {
    const { status = 'pending', page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('reviews')
      .select(`
        id, dispute_reason, dispute_filed_at, dispute_status,
        dispute_outcome, dispute_resolution_deadline,
        total_score, content_summary,
        business:businesses(id, name, category),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade)
      `)
      .eq('is_disputed', true)
      .order('dispute_filed_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (status !== 'all') {
      query = query.eq('dispute_status', status);
    }

    const { data: disputes, error } = await query;

    if (error) throw error;

    // 각 분쟁에 증거 개수 추가
    const disputesWithMeta = await Promise.all((disputes || []).map(async (d) => {
      const { count } = await supabase
        .from('dispute_evidences')
        .select('*', { count: 'exact', head: true })
        .eq('review_id', d.id);

      const deadline = d.dispute_resolution_deadline ? new Date(d.dispute_resolution_deadline) : null;
      const now = new Date();
      const remainingHours = deadline ? Math.max(0, Math.ceil((deadline.getTime() - now.getTime()) / 3600000)) : null;

      return {
        ...d,
        evidenceCount: count || 0,
        remainingHours,
        isOverdue: remainingHours !== null && remainingHours <= 0 && d.dispute_status !== 'resolved',
      };
    }));

    res.json({
      success: true,
      data: { disputes: disputesWithMeta }
    });
  } catch (error) {
    next(error);
  }
};

// 이의 제기 해결 (관리자용)
exports.resolveDispute = async (req, res, next) => {
  try {
    const { outcome, resolution, adminNotes, partialRefundPercent } = req.body;
    // outcome: 'upheld' (리뷰 유지), 'modified' (수정 요청), 'removed' (삭제)

    const validOutcomes = ['upheld', 'modified', 'removed'];
    if (!validOutcomes.includes(outcome)) {
      return res.status(400).json({
        success: false,
        message: '유효하지 않은 판정 결과입니다. (upheld, modified, removed 중 선택)'
      });
    }

    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id, mission_id, reviewer_id, business_id, dispute_status, business:businesses(owner_id)')
      .eq('id', req.params.id)
      .eq('is_disputed', true)
      .single();

    if (reviewError || !review) {
      return res.status(404).json({
        success: false,
        message: '이의 제기된 리뷰를 찾을 수 없습니다.'
      });
    }

    // D2: 중복 해결 방지
    if (review.dispute_status === 'resolved') {
      return res.status(400).json({
        success: false,
        message: '이미 해결된 이의 제기입니다.'
      });
    }

    // 판정 결과에 따른 리뷰 상태 변경
    let newReviewStatus;
    let escrowAction;
    switch (outcome) {
      case 'upheld':
        // 리뷰 유지 → 공개 처리
        newReviewStatus = 'published';
        escrowAction = 'released'; // 리뷰어에게 정산
        break;
      case 'modified':
        // 수정 요청 → 리뷰어에게 수정 요청, 보류 유지
        newReviewStatus = 'under_review';
        escrowAction = 'held';
        break;
      case 'removed':
        // 삭제 → 숨김 처리, 에스크로 환불
        newReviewStatus = 'hidden';
        escrowAction = 'refunded';
        break;
    }

    const { error } = await supabase
      .from('reviews')
      .update({
        dispute_status: 'resolved',
        dispute_outcome: outcome,
        dispute_resolution: resolution,
        dispute_resolved_at: new Date().toISOString(),
        dispute_investigated_by: req.user.id,
        dispute_admin_notes: adminNotes,
        status: newReviewStatus,
      })
      .eq('id', req.params.id);

    if (error) throw error;

    // 에스크로 상태 업데이트
    await supabase
      .from('escrows')
      .update({
        status: escrowAction,
        updated_at: new Date().toISOString()
      })
      .eq('mission_id', review.mission_id);

    // V8: Partial refund support for 'modified' outcome
    if (outcome === 'modified' && partialRefundPercent) {
      const { data: escrow, error: escrowError } = await supabase
        .from('escrows')
        .select('total_amount')
        .eq('mission_id', review.mission_id)
        .single();

      if (!escrowError && escrow) {
        const refundAmount = Math.round(escrow.total_amount * (partialRefundPercent / 100));
        // Update escrow with partial refund
        await supabase
          .from('escrows')
          .update({
            refund_amount: refundAmount,
            status: 'partial_refund',
            refund_reason: adminNotes
          })
          .eq('mission_id', review.mission_id);
      }
    }

    // 업체에게 결과 알림
    const { createNotification } = require('../utils/notificationService');
    const outcomeMessages = {
      upheld: '이의 제기 검토 결과, 리뷰가 유지되었습니다.',
      modified: '이의 제기 검토 결과, 리뷰어에게 수정을 요청했습니다.',
      removed: '이의 제기 검토 결과, 리뷰가 삭제되었습니다.',
    };

    if (review.business?.owner_id) {
      await createNotification(
        review.business.owner_id,
        'dispute_resolved',
        '이의 제기 결과 알림',
        outcomeMessages[outcome],
        { reviewId: req.params.id, outcome }
      );
    }

    // 리뷰어에게도 알림
    if (review.reviewer_id) {
      const reviewerMessages = {
        upheld: '이의 제기 검토 결과, 리뷰가 정상 공개되었습니다.',
        modified: '이의 제기 검토 결과, 리뷰 수정이 요청되었습니다. 리뷰를 수정해주세요.',
        removed: '이의 제기 검토 결과, 리뷰가 삭제되었습니다.',
      };
      await createNotification(
        review.reviewer_id,
        'dispute_resolved',
        '리뷰 이의 제기 결과',
        reviewerMessages[outcome],
        { reviewId: req.params.id, outcome }
      );
    }

    res.json({
      success: true,
      message: `이의 제기가 '${outcome}'으로 해결되었습니다.`,
      data: {
        outcome,
        reviewStatus: newReviewStatus,
        escrowStatus: escrowAction,
      }
    });
  } catch (error) {
    next(error);
  }
};

// 이의 제기 타임라인 헬퍼
function buildDisputeTimeline(review) {
  const timeline = [];

  if (review.dispute_filed_at) {
    timeline.push({
      event: 'filed',
      title: '이의 제기 접수',
      date: review.dispute_filed_at,
      completed: true,
    });
  }

  timeline.push({
    event: 'investigating',
    title: '운영팀 조사 중',
    date: null,
    completed: review.dispute_status === 'investigating' || review.dispute_status === 'resolved',
  });

  if (review.dispute_resolution_deadline) {
    timeline.push({
      event: 'deadline',
      title: '해결 기한',
      date: review.dispute_resolution_deadline,
      completed: review.dispute_status === 'resolved',
    });
  }

  timeline.push({
    event: 'resolved',
    title: '판정 완료',
    date: review.dispute_resolved_at,
    completed: review.dispute_status === 'resolved',
    outcome: review.dispute_outcome,
  });

  return timeline;
}

// 카테고리별 리뷰
exports.getReviewsByCategory = async (req, res, next) => {
  try {
    const { category } = req.params;

    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses!inner(id, name, category)
      `)
      .eq('status', 'published')
      .eq('business.category', category)
      .limit(50);

    if (error) throw error;

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    next(error);
  }
};

// 트렌딩 리뷰
exports.getTrendingReviews = async (req, res, next) => {
  try {
    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname)
      `)
      .eq('status', 'published')
      .order('helpful_count', { ascending: false })
      .limit(20);

    if (error) throw error;

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    next(error);
  }
};

// 최근 리뷰
exports.getRecentReviews = async (req, res, next) => {
  try {
    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        business:businesses(id, name),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname)
      `)
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .limit(20);

    if (error) throw error;

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    next(error);
  }
};

// === Feature 7: 공유용 리뷰 포맷 ===
exports.getShareableReview = async (req, res, next) => {
  try {
    const { data: review, error } = await supabase
      .from('reviews')
      .select(`
        id, summary, recommendation, total_score, pros, cons,
        gps_verified, receipt_verified, stay_duration_minutes,
        published_at,
        business:businesses(id, name, category, address_city, badge_level),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade, completed_missions)
      `)
      .eq('id', req.params.id)
      .eq('status', 'published')
      .single();

    if (error || !review) {
      return res.status(404).json({ success: false, message: '리뷰를 찾을 수 없습니다.' });
    }

    // 증거 배지 구성
    const evidenceBadges = [];
    if (review.gps_verified) evidenceBadges.push({ type: 'gps', label: 'GPS 인증' });
    if (review.receipt_verified) evidenceBadges.push({ type: 'receipt', label: '영수증 인증' });
    if (review.stay_duration_minutes > 0) evidenceBadges.push({ type: 'stay', label: `${review.stay_duration_minutes}분 체류` });

    const shareData = {
      id: review.id,
      businessName: review.business?.name,
      businessCategory: review.business?.category,
      businessBadge: review.business?.badge_level,
      reviewerNickname: review.reviewer?.nickname,
      reviewerGrade: review.reviewer?.reviewer_grade,
      summary: review.summary,
      score: review.total_score,
      recommendation: review.recommendation,
      pros: review.pros,
      cons: review.cons,
      evidenceBadges,
      publishedAt: review.published_at,
      shareUrl: `https://amhangeoheung.com/reviews/${review.id}`,
    };

    res.json({ success: true, data: shareData });
  } catch (error) {
    next(error);
  }
};
