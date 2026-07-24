const supabase = require('../config/supabase');
const { WHISTLEBLOWER_REWARD } = require('../config/constants');

/**
 * POST /api/whistleblower/report
 * 리뷰어가 업체의 뒷돈 제안 등 담합 시도를 신고
 */
exports.createReport = async (req, res, next) => {
  try {
    const { businessId, missionId, reportType, description, evidenceUrls } = req.body;

    if (!businessId || !reportType || !description) {
      return res.status(400).json({
        success: false,
        message: '업체 ID, 신고 유형, 설명은 필수입니다.',
      });
    }

    const validTypes = ['kickback_offer', 'bribe_attempt', 'review_manipulation', 'threat'];
    if (!validTypes.includes(reportType)) {
      return res.status(400).json({
        success: false,
        message: '유효하지 않은 신고 유형입니다.',
      });
    }

    // 동일 미션에 대한 중복 신고 방지
    if (missionId) {
      const { data: existing, error: existingError } = await supabase
        .from('whistleblower_reports')
        .select('id')
        .eq('reporter_id', req.user.id)
        .eq('reported_mission_id', missionId)
        .single();

      if (existing && !existingError) {
        return res.status(400).json({
          success: false,
          message: '이미 해당 미션에 대해 신고한 이력이 있습니다.',
        });
      }
    }

    const { data: report, error } = await supabase
      .from('whistleblower_reports')
      .insert({
        reporter_id: req.user.id,
        reported_business_id: businessId,
        reported_mission_id: missionId || null,
        report_type: reportType,
        description,
        evidence_urls: evidenceUrls || [],
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;

    console.log(`[WHISTLEBLOWER] New report: id=${report.id}, type=${reportType}, reporter=${req.user.id}`);

    res.status(201).json({
      success: true,
      message: '신고가 접수되었습니다. 운영팀에서 검토 후 조치합니다.',
      data: { reportId: report.id },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/whistleblower
 * 관리자: 신고 목록 조회
 */
exports.getReports = async (req, res, next) => {
  try {
    const { status = 'pending', page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('whistleblower_reports')
      .select(`
        *,
        reporter:users!whistleblower_reports_reporter_id_fkey(id, nickname, email),
        business:businesses!whistleblower_reports_reported_business_id_fkey(id, name, category)
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (status !== 'all') {
      query = query.eq('status', status);
    }

    const { data: reports, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data: { reports: reports || [] },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/whistleblower/:id
 * 관리자: 신고 처리 (confirmed → 영구차단 + 보상)
 */
exports.resolveReport = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;

    if (!['investigating', 'confirmed', 'dismissed'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: '유효하지 않은 상태입니다. (investigating, confirmed, dismissed)',
      });
    }

    const { data: report, error: reportError } = await supabase
      .from('whistleblower_reports')
      .select('*')
      .eq('id', id)
      .single();

    if (reportError || !report) {
      return res.status(404).json({
        success: false,
        message: '신고를 찾을 수 없습니다.',
      });
    }

    // 업데이트
    const { error: updateError } = await supabase
      .from('whistleblower_reports')
      .update({
        status,
        admin_notes: adminNotes || null,
        resolved_at: status === 'confirmed' || status === 'dismissed'
          ? new Date().toISOString()
          : null,
      })
      .eq('id', id);

    if (updateError) throw updateError;

    // confirmed 시: 업체 영구 차단 + 신고자 보상
    if (status === 'confirmed') {
      // 1. 업체 소유자 영구 차단
      const { data: business, error: businessError } = await supabase
        .from('businesses')
        .select('owner_id')
        .eq('id', report.reported_business_id)
        .single();

      if (!businessError && business?.owner_id) {
        await supabase.from('users')
          .update({
            status: 'banned',
            is_permanently_banned: true,
            ban_reason: `내부 고발 확인: ${report.report_type}`,
          })
          .eq('id', business.owner_id);

        // 업체 비활성화
        await supabase.from('businesses')
          .update({ status: 'banned' })
          .eq('id', report.reported_business_id);
      }

      // 2. 신고자에게 보상
      await supabase.from('reviewer_earnings').insert({
        reviewer_id: report.reporter_id,
        earning_type: 'whistleblower_reward',
        base_amount: WHISTLEBLOWER_REWARD,
        total_amount: WHISTLEBLOWER_REWARD,
        status: 'paid',
        paid_at: new Date().toISOString(),
      });

      // 총 수익 업데이트
      const { data: reporter, error: reporterError } = await supabase
        .from('users')
        .select('total_earnings')
        .eq('id', report.reporter_id)
        .single();

      await supabase.from('users')
        .update({
          total_earnings: ((!reporterError && reporter) ? reporter.total_earnings : 0) + WHISTLEBLOWER_REWARD,
        })
        .eq('id', report.reporter_id);

      // 알림
      const { createNotification } = require('../utils/notificationService');
      await createNotification(
        report.reporter_id,
        'whistleblower_reward',
        '내부 고발 보상 지급',
        `신고가 확인되어 ${WHISTLEBLOWER_REWARD.toLocaleString()}원의 보상이 지급되었습니다. 플랫폼의 신뢰를 지켜주셔서 감사합니다.`,
        { reportId: id, reward: WHISTLEBLOWER_REWARD }
      );

      console.log(`[WHISTLEBLOWER] Confirmed: report=${id}, business=${report.reported_business_id}, reward=${WHISTLEBLOWER_REWARD}`);
    }

    res.json({
      success: true,
      message: `신고가 '${status}' 상태로 처리되었습니다.`,
    });
  } catch (error) {
    next(error);
  }
};
