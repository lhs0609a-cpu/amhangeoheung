/**
 * 담합 방지 엔진 컨트롤러
 * IP/디바이스 추적, 행동 패턴 분석, 이상 징후 모니터링
 */

const supabase = require('../config/supabase');
const {
  COLLUSION_REPEAT_BLOCK_MONTHS,
  COLLUSION_IP_MATCH_SEVERITY,
  COLLUSION_DEVICE_MATCH_SEVERITY,
} = require('../config/constants');

// Filter out known public/shared IP ranges (cafes, offices, VPN)
const isPublicIP = (ip) => {
  const publicRanges = [
    '10.', '172.16.', '172.17.', '172.18.', '172.19.',
    '172.20.', '172.21.', '172.22.', '172.23.', '172.24.',
    '172.25.', '172.26.', '172.27.', '172.28.', '172.29.',
    '172.30.', '172.31.', '192.168.'
  ];
  return publicRanges.some(range => ip.startsWith(range));
};

/**
 * 세션 핑거프린트 기록 (미들웨어에서 호출)
 */
async function recordFingerprint(userId, req) {
  try {
    const ipAddress = req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
                      req.connection?.remoteAddress ||
                      req.ip;
    const userAgent = req.headers['user-agent'] || '';
    const deviceId = req.headers['x-device-id'] || null;
    const deviceModel = req.headers['x-device-model'] || null;
    const osVersion = req.headers['x-os-version'] || null;
    const appVersion = req.headers['x-app-version'] || null;

    await supabase
      .from('session_fingerprints')
      .insert({
        user_id: userId,
        ip_address: ipAddress,
        device_id: deviceId,
        device_model: deviceModel,
        os_version: osVersion,
        app_version: appVersion,
      });
  } catch (err) {
    // 핑거프린트 기록 실패는 무시 (non-blocking)
    console.error('[FINGERPRINT] Record error:', err.message);
  }
}

/**
 * 담합 위험도 체크 (미션 배정 전 호출)
 * @returns {{ riskLevel: 'safe'|'warning'|'blocked', flags: string[] }}
 */
async function checkCollusionRisk(reviewerId, businessId) {
  const flags = [];
  let riskLevel = 'safe';

  try {
    // 1. 같은 IP 사용 이력 검사
    const { data: reviewerIps } = await supabase
      .from('session_fingerprints')
      .select('ip_address')
      .eq('user_id', reviewerId)
      .order('created_at', { ascending: false })
      .limit(50);

    const { data: business, error: businessError } = await supabase
      .from('businesses')
      .select('owner_id')
      .eq('id', businessId)
      .single();

    if (!businessError && business?.owner_id) {
      const { data: businessIps } = await supabase
        .from('session_fingerprints')
        .select('ip_address')
        .eq('user_id', business.owner_id)
        .order('created_at', { ascending: false })
        .limit(50);

      const reviewerIpSet = new Set((reviewerIps || []).map(r => r.ip_address).filter(Boolean));
      const businessIpSet = new Set((businessIps || []).map(r => r.ip_address).filter(Boolean));

      const sharedIps = [...reviewerIpSet].filter(ip => businessIpSet.has(ip));
      if (sharedIps.length > 0) {
        // If IP is private/NAT range, reduce severity from 'high' to 'low'
        const allPublic = sharedIps.every(ip => isPublicIP(ip));
        let ipSeverity = COLLUSION_IP_MATCH_SEVERITY || 'high';
        if (allPublic) {
          ipSeverity = 'low';
          console.log(`[Collusion] Private/NAT IPs ${sharedIps.join(', ')} - reducing severity`);
        }
        flags.push({
          type: 'shared_ip',
          severity: ipSeverity,
          evidence: { sharedIps, isPrivateNetwork: allPublic },
        });
        riskLevel = allPublic ? 'safe' : 'warning';
      }

      // 2. 같은 디바이스 검사
      const { data: reviewerDevices } = await supabase
        .from('session_fingerprints')
        .select('device_id')
        .eq('user_id', reviewerId)
        .not('device_id', 'is', null)
        .limit(20);

      const { data: businessDevices } = await supabase
        .from('session_fingerprints')
        .select('device_id')
        .eq('user_id', business.owner_id)
        .not('device_id', 'is', null)
        .limit(20);

      const reviewerDeviceSet = new Set((reviewerDevices || []).map(r => r.device_id));
      const businessDeviceSet = new Set((businessDevices || []).map(r => r.device_id));

      const sharedDevices = [...reviewerDeviceSet].filter(d => businessDeviceSet.has(d));
      if (sharedDevices.length > 0) {
        flags.push({
          type: 'shared_device',
          severity: COLLUSION_DEVICE_MATCH_SEVERITY || 'critical',
          evidence: { sharedDevices },
        });
        riskLevel = 'blocked'; // 같은 디바이스 = 차단
      }
    }

    // 3. 반복 배정 이력 검사
    const blockDate = new Date();
    blockDate.setMonth(blockDate.getMonth() - (COLLUSION_REPEAT_BLOCK_MONTHS || 6));

    const { data: history } = await supabase
      .from('reviewer_business_history')
      .select('id, assigned_at')
      .eq('reviewer_id', reviewerId)
      .eq('business_id', businessId)
      .gt('assigned_at', blockDate.toISOString());

    if (history && history.length > 0) {
      flags.push({
        type: 'pattern_repeat',
        severity: 'high',
        evidence: { previousAssignments: history.length },
      });
      riskLevel = 'blocked';
    }

    // 플래그가 있으면 collusion_flags에 기록
    if (flags.length > 0) {
      for (const flag of flags) {
        await supabase
          .from('collusion_flags')
          .insert({
            flag_type: flag.type,
            severity: flag.severity,
            reviewer_id: reviewerId,
            business_id: businessId,
            evidence: flag.evidence,
            auto_action: riskLevel === 'blocked' ? 'block_assignment' : 'none',
          });
      }
    }

    return { riskLevel, flags: flags.map(f => f.type) };
  } catch (err) {
    console.error('[COLLUSION_CHECK] Error:', err.message);
    return { riskLevel: 'safe', flags: [] }; // 에러 시 안전하게 통과
  }
}

/**
 * Enhanced text similarity using n-gram overlap (better than Jaccard for Korean)
 */
function calculateTextSimilarity(text1, text2) {
  if (!text1 || !text2) return 0;

  // Generate 2-gram sets (better for Korean morphology)
  const ngrams = (text, n = 2) => {
    const set = new Set();
    for (let i = 0; i <= text.length - n; i++) {
      set.add(text.substring(i, i + n));
    }
    return set;
  };

  const set1 = ngrams(text1);
  const set2 = ngrams(text2);

  let intersection = 0;
  for (const gram of set1) {
    if (set2.has(gram)) intersection++;
  }

  const union = set1.size + set2.size - intersection;
  return union === 0 ? 0 : intersection / union;
}

/**
 * 리뷰 패턴 분석 (리뷰 제출 후 호출)
 */
async function analyzeReviewPattern(reviewerId) {
  try {
    // 최근 10개 리뷰 조회
    const { data: reviews } = await supabase
      .from('reviews')
      .select(`
        id, total_score, business_id, content_pros, content_cons, content_summary, created_at,
        mission:missions(check_in_time, check_out_time)
      `)
      .eq('reviewer_id', reviewerId)
      .order('created_at', { ascending: false })
      .limit(10);

    if (!reviews || reviews.length < 3) return; // 데이터 부족

    const flags = [];

    // 1. 특정 업체만 비정상 고점
    const businessScores = {};
    reviews.forEach(r => {
      if (!businessScores[r.business_id]) businessScores[r.business_id] = [];
      businessScores[r.business_id].push(r.total_score);
    });

    const avgScoreAll = reviews.reduce((s, r) => s + (r.total_score || 0), 0) / reviews.length;
    for (const [bizId, scores] of Object.entries(businessScores)) {
      if (scores.length >= 2) {
        const bizAvg = scores.reduce((s, v) => s + v, 0) / scores.length;
        if (bizAvg > avgScoreAll + 1.0 && bizAvg >= 4.5) {
          flags.push({
            type: 'score_anomaly',
            severity: 'medium',
            evidence: { businessId: bizId, avgScore: bizAvg, overallAvg: avgScoreAll },
          });
        }
      }
    }

    // 2. 체류시간 패턴 (항상 정확히 30-35분 → 의심)
    const stayTimes = reviews
      .filter(r => r.mission?.check_in_time && r.mission?.check_out_time)
      .map(r => {
        const ms = new Date(r.mission.check_out_time) - new Date(r.mission.check_in_time);
        return Math.round(ms / 60000);
      });

    if (stayTimes.length >= 3) {
      const avgStay = stayTimes.reduce((s, t) => s + t, 0) / stayTimes.length;
      const stayVariance = stayTimes.reduce((s, t) => s + Math.pow(t - avgStay, 2), 0) / stayTimes.length;
      if (stayVariance < 25 && avgStay < 40) { // 분산이 매우 낮고 짧음
        flags.push({
          type: 'timing_anomaly',
          severity: 'low',
          evidence: { avgStayMinutes: avgStay, variance: stayVariance },
        });
      }
    }

    // 3. 리뷰 텍스트 유사도 (n-gram 기반 — 한국어에 더 적합)
    const texts = reviews.map(r => (r.content_summary || '') + ' ' + (r.content_pros?.join(' ') || ''));
    if (texts.length >= 3) {
      let highSimilarity = 0;
      for (let i = 0; i < texts.length - 1; i++) {
        for (let j = i + 1; j < texts.length; j++) {
          const similarity = calculateTextSimilarity(texts[i], texts[j]);
          if (similarity > 0.6) {
            highSimilarity++;
          }
        }
      }
      if (highSimilarity >= 3) {
        flags.push({
          type: 'text_anomaly',
          severity: 'medium',
          evidence: { highSimilarityPairs: highSimilarity },
        });
      }
    }

    // 플래그 저장
    if (flags.length > 0) {
      for (const flag of flags) {
        await supabase
          .from('collusion_flags')
          .insert({
            flag_type: flag.type,
            severity: flag.severity,
            reviewer_id: reviewerId,
            evidence: flag.evidence,
            auto_action: flag.severity === 'high' ? 'flag_review' : 'none',
          });
      }
      console.log(`[COLLUSION_ANALYZE] Reviewer ${reviewerId}: ${flags.length} flags detected`);
    }

    return flags;
  } catch (err) {
    console.error('[COLLUSION_ANALYZE] Error:', err.message);
    return [];
  }
}

/**
 * 일괄 담합 스캔 (스케줄러에서 호출)
 */
async function runDailyCollusionScan() {
  try {
    console.log('[COLLUSION_SCAN] Starting daily scan...');
    let totalFlags = 0;

    // 1. IP 교차 분석: 리뷰어와 사업자가 같은 IP를 사용한 경우
    const { data: recentFingerprints } = await supabase
      .from('session_fingerprints')
      .select('user_id, ip_address')
      .gt('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
      .not('ip_address', 'is', null);

    if (recentFingerprints && recentFingerprints.length > 0) {
      // IP별 사용자 그룹핑
      const ipUsers = {};
      recentFingerprints.forEach(f => {
        if (!ipUsers[f.ip_address]) ipUsers[f.ip_address] = new Set();
        ipUsers[f.ip_address].add(f.user_id);
      });

      // 같은 IP를 사용하는 사용자 쌍 찾기
      for (const [ip, users] of Object.entries(ipUsers)) {
        if (users.size < 2) continue;
        const userIds = [...users];

        // 리뷰어-사업자 쌍 확인
        const { data: userTypes } = await supabase
          .from('users')
          .select('id, user_type')
          .in('id', userIds);

        if (!userTypes) continue;

        const reviewers = userTypes.filter(u => u.user_type === 'reviewer');
        const businessOwners = userTypes.filter(u => u.user_type === 'business');

        for (const reviewer of reviewers) {
          for (const owner of businessOwners) {
            // 이미 이 쌍에 대한 플래그가 최근에 있는지 확인
            const { data: existingFlag } = await supabase
              .from('collusion_flags')
              .select('id')
              .eq('flag_type', 'shared_ip')
              .eq('reviewer_id', reviewer.id)
              .gt('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
              .limit(1);

            if (existingFlag && existingFlag.length > 0) continue;

            // Reduce severity for private/NAT IP ranges
            const flagSeverity = isPublicIP(ip) ? 'low' : 'high';
            if (isPublicIP(ip)) {
              console.log(`[Collusion] Private/NAT IP ${ip} in daily scan - reducing severity`);
            }

            await supabase
              .from('collusion_flags')
              .insert({
                flag_type: 'shared_ip',
                severity: flagSeverity,
                reviewer_id: reviewer.id,
                evidence: { ip, businessOwnerId: owner.id, isPrivateNetwork: isPublicIP(ip) },
              });
            totalFlags++;
          }
        }
      }
    }

    console.log(`[COLLUSION_SCAN] Daily scan complete. New flags: ${totalFlags}`);
    return { totalFlags };
  } catch (err) {
    console.error('[COLLUSION_SCAN] Error:', err.message);
    return { totalFlags: 0 };
  }
}

/**
 * 관리자용: 미해결 플래그 목록
 */
exports.getCollusionFlags = async (req, res, next) => {
  try {
    const { status = 'open', page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const { data: flags, error, count } = await supabase
      .from('collusion_flags')
      .select(`
        *,
        reviewer:users!collusion_flags_reviewer_id_fkey(id, nickname, email),
        business:businesses!collusion_flags_business_id_fkey(id, name)
      `, { count: 'exact' })
      .eq('status', status)
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (error) throw error;

    res.json({
      success: true,
      data: {
        flags: flags || [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 관리자용: 플래그 처리
 */
exports.resolveFlag = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, resolutionNote } = req.body;

    if (!['confirmed', 'dismissed', 'resolved'].includes(status)) {
      return res.status(400).json({ success: false, message: '유효하지 않은 상태입니다.' });
    }

    const updates = {
      status,
      resolution_note: resolutionNote || null,
      resolved_at: new Date().toISOString(),
    };

    // confirmed인 경우 자동 조치
    if (status === 'confirmed') {
      const { data: flag, error: flagError } = await supabase
        .from('collusion_flags')
        .select('reviewer_id, severity')
        .eq('id', id)
        .single();

      if (!flagError && flag?.reviewer_id && flag.severity === 'critical') {
        // 영구 차단
        await supabase
          .from('users')
          .update({
            status: 'banned',
            is_permanently_banned: true,
            ban_reason: '담합 확인으로 인한 영구 차단',
          })
          .eq('id', flag.reviewer_id);

        // 모든 미지급 정산금 몰수
        await supabase
          .from('escrows')
          .update({ status: 'forfeited' })
          .eq('reviewer_id', flag.reviewer_id)
          .in('status', ['paid', 'hold']);

        // 인증 취소
        await supabase
          .from('reviewer_certifications')
          .update({ status: 'revoked' })
          .eq('user_id', flag.reviewer_id);

        await supabase
          .from('users')
          .update({ is_certified: false })
          .eq('id', flag.reviewer_id);

        // 수익 이력에 몰수 기록
        await supabase
          .from('reviewer_earnings')
          .update({ status: 'forfeited' })
          .eq('reviewer_id', flag.reviewer_id)
          .eq('status', 'pending');

        updates.auto_action = 'permanent_ban';

        // 알림
        const { createNotification } = require('../utils/notificationService');
        await createNotification(
          flag.reviewer_id,
          'permanent_ban',
          '계정이 영구 차단되었습니다',
          '담합 확인으로 인해 계정이 영구 차단되었습니다. 모든 미지급 정산금이 몰수되었습니다.',
          { flagId: id }
        );
      } else if (!flagError && flag?.reviewer_id) {
        // critical이 아닌 confirmed는 일시 정지
        await supabase
          .from('users')
          .update({ status: 'suspended', ban_reason: '담합 의심으로 인한 정지' })
          .eq('id', flag.reviewer_id);

        updates.auto_action = 'suspend_reviewer';
      }
    }

    const { error } = await supabase
      .from('collusion_flags')
      .update(updates)
      .eq('id', id);

    if (error) throw error;

    res.json({ success: true, message: '플래그가 처리되었습니다.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  recordFingerprint,
  checkCollusionRisk,
  analyzeReviewPattern,
  runDailyCollusionScan,
  getCollusionFlags: exports.getCollusionFlags,
  resolveFlag: exports.resolveFlag,
};
