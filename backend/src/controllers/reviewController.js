const supabase = require('../config/supabase');

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
    const { missionId, scores, content } = req.body;

    const { data: mission } = await supabase
      .from('missions')
      .select('id, business_id, assigned_reviewer_id')
      .eq('id', missionId)
      .single();

    if (!mission || mission.assigned_reviewer_id !== req.user.id) {
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
    const { data: review } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .eq('status', 'draft')
      .single();

    if (!review) {
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
    const { data: review } = await supabase
      .from('reviews')
      .select('*')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .eq('status', 'draft')
      .single();

    if (!review) {
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

    // 업체 선공개 시작 시간 설정
    const previewStartAt = new Date();
    previewStartAt.setHours(previewStartAt.getHours() + 72); // 3일 후

    const { error } = await supabase
      .from('reviews')
      .update({
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        preview_start_at: previewStartAt.toISOString()
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
    const { data: mission } = await supabase
      .from('missions')
      .select('business:businesses(owner_id)')
      .eq('id', review.mission_id)
      .single();

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
    const { data: review } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (!review) {
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
        const buffer = Buffer.from(photo.base64, 'base64');

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
exports.uploadReceipt = async (req, res, next) => {
  try {
    const { data: review } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (!review) {
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
      const buffer = Buffer.from(imageBase64, 'base64');

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

    // OCR 분석 실행
    let ocrData = null;
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
        }
      } catch (ocrError) {
        // OCR 실패해도 이미지는 저장 (수동 검토 가능)
        console.error('[OCR] Receipt analysis failed:', ocrError);
      }
    }

    const { error } = await supabase
      .from('reviews')
      .update({
        receipt_image_url: receiptImageUrl,
        receipt_ocr_data: ocrData,
        receipt_verified: ocrData ? ocrData.confidence >= 0.6 : false,
        receipt_uploaded_at: new Date().toISOString(),
      })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: '영수증이 업로드되었습니다.',
      data: {
        imageUrl: receiptImageUrl,
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

// 언박싱 영상 업로드
exports.uploadVideo = async (req, res, next) => {
  try {
    const { data: review } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (!review) {
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
    const { data: review } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', req.params.id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (!review) {
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
        business:businesses(id, name, category, address_city, badge_level),
        reviewer:users!reviews_reviewer_id_fkey(id, nickname, reviewer_grade)
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

    res.json({
      success: true,
      data: {
        review: {
          ...review,
          scores,
          photos
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
    const { data: existingVote } = await supabase
      .from('review_votes')
      .select('id, vote_type')
      .eq('review_id', reviewId)
      .eq('user_id', userId)
      .single();

    if (existingVote) {
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
        const { data: review } = await supabase
          .from('reviews')
          .select('helpful_count, not_helpful_count')
          .eq('id', reviewId)
          .single();

        await supabase
          .from('reviews')
          .update({
            helpful_count: (review?.helpful_count || 0) + 1,
            not_helpful_count: Math.max(0, (review?.not_helpful_count || 0) - 1)
          })
          .eq('id', reviewId);

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

    const { data: review } = await supabase
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
    const { data: existingVote } = await supabase
      .from('review_votes')
      .select('id, vote_type')
      .eq('review_id', reviewId)
      .eq('user_id', userId)
      .single();

    if (existingVote) {
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
        const { data: review } = await supabase
          .from('reviews')
          .select('helpful_count, not_helpful_count')
          .eq('id', reviewId)
          .single();

        await supabase
          .from('reviews')
          .update({
            helpful_count: Math.max(0, (review?.helpful_count || 0) - 1),
            not_helpful_count: (review?.not_helpful_count || 0) + 1
          })
          .eq('id', reviewId);

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

    const { data: review } = await supabase
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
    const { data: existingReport } = await supabase
      .from('review_reports')
      .select('id')
      .eq('review_id', reviewId)
      .eq('reporter_id', userId)
      .single();

    if (existingReport) {
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
    const { data: review } = await supabase
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

    // 신고가 5건 이상이면 관리자에게 알림 (로그)
    if (newReportedCount >= 5) {
      console.log(`[ALERT] Review ${reviewId} has been auto-hidden due to ${newReportedCount} reports`);
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
    const { data: existingRequest } = await supabase
      .from('review_requests')
      .select('id')
      .eq('business_id', businessId)
      .eq('requester_id', req.user.id)
      .eq('status', 'pending')
      .single();

    if (existingRequest) {
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
    const { data: currentBusiness } = await supabase
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

// 업체 답변
exports.submitBusinessResponse = async (req, res, next) => {
  try {
    const { content, improvementPromise } = req.body;

    const { data: review } = await supabase
      .from('reviews')
      .select(`
        id,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (!review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
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

// 이의 제기
exports.disputeReview = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const { data: review } = await supabase
      .from('reviews')
      .select(`
        id, mission_id,
        business:businesses(id, owner_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (!review || review.business.owner_id !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: '리뷰를 찾을 수 없습니다.'
      });
    }

    const { error } = await supabase
      .from('reviews')
      .update({
        is_disputed: true,
        dispute_reason: reason,
        dispute_filed_by: 'business',
        dispute_filed_at: new Date().toISOString(),
        status: 'disputed'
      })
      .eq('id', req.params.id);

    if (error) throw error;

    // 에스크로 보류
    await supabase
      .from('escrows')
      .update({
        status: 'held',
        hold_reason: reason,
        held_at: new Date().toISOString()
      })
      .eq('mission_id', review.mission_id);

    res.json({
      success: true,
      message: '이의 제기가 접수되었습니다. 운영팀에서 검토합니다.'
    });
  } catch (error) {
    next(error);
  }
};

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
