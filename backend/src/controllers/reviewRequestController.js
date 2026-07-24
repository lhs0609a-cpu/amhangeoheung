const supabase = require('../config/supabase');
const { createNotification } = require('../utils/notificationService');
const NOTIFICATION_TYPES = require('../config/notificationTypes');

const REQUEST_THRESHOLD = 5;

// 리뷰 요청 생성
exports.createRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { businessId, message } = req.body;

    if (!businessId) {
      return res.status(400).json({ success: false, message: 'businessId가 필요합니다.' });
    }

    // 업체 정보 가져오기
    const { data: business, error: businessError } = await supabase
      .from('businesses')
      .select('id, owner_id, name, category, address')
      .eq('id', businessId)
      .single();

    if (businessError || !business) {
      return res.status(404).json({ success: false, message: '업체를 찾을 수 없습니다.' });
    }

    // 중복 요청 방지 (같은 사용자가 같은 업체에 24시간 내)
    const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { data: recentRequest, error: recentRequestError } = await supabase
      .from('review_requests')
      .select('id')
      .eq('requester_id', userId)
      .eq('business_id', businessId)
      .gt('created_at', dayAgo)
      .single();

    if (recentRequest && !recentRequestError) {
      return res.status(400).json({ success: false, message: '24시간 내 이미 요청했습니다.' });
    }

    const { data: request, error } = await supabase
      .from('review_requests')
      .insert({
        requester_id: userId,
        business_id: businessId,
        business_name: business.name,
        category: business.category,
        region: business.address,
        message,
      })
      .select()
      .single();

    if (error) throw error;

    // 요청 수 확인 후 임계치 초과 시 업체에 알림
    const { count } = await supabase
      .from('review_requests')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .eq('status', 'pending');

    if (count >= REQUEST_THRESHOLD && business.owner_id) {
      await createNotification(
        business.owner_id,
        NOTIFICATION_TYPES.REVIEW_REQUEST_THRESHOLD,
        '리뷰 요청이 쌓이고 있어요!',
        `${count}명의 소비자가 ${business.name}의 리뷰를 원하고 있습니다. 미션을 등록해보세요!`,
        { businessId, requestCount: count }
      );
    }

    res.status(201).json({ success: true, data: request });
  } catch (error) {
    console.error('createRequest error:', error);
    res.status(500).json({ success: false, message: '리뷰 요청에 실패했습니다.' });
  }
};

// 업체 수신 요청 목록
exports.getRequestsForBusiness = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: requests, error } = await supabase
      .from('review_requests')
      .select('*')
      .eq('business_id', id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;

    res.json({ success: true, data: requests || [] });
  } catch (error) {
    console.error('getRequestsForBusiness error:', error);
    res.status(500).json({ success: false, message: '요청 목록 조회에 실패했습니다.' });
  }
};

// 인기 요청 목록 (공개)
exports.getPopularRequests = async (req, res) => {
  try {
    const { data, error } = await supabase
      .rpc('get_popular_review_requests', { min_count: 3 });

    // RPC가 없을 경우 직접 쿼리
    if (error) {
      const { data: requests, error: err2 } = await supabase
        .from('review_requests')
        .select('business_id, business_name, category, region')
        .eq('status', 'pending');

      if (err2) throw err2;

      // 수동 집계
      const counts = {};
      (requests || []).forEach(r => {
        if (!counts[r.business_id]) {
          counts[r.business_id] = {
            business_id: r.business_id,
            business_name: r.business_name,
            category: r.category,
            region: r.region,
            count: 0,
          };
        }
        counts[r.business_id].count++;
      });

      const popular = Object.values(counts)
        .filter(c => c.count >= 3)
        .sort((a, b) => b.count - a.count)
        .slice(0, 20);

      return res.json({ success: true, data: popular });
    }

    res.json({ success: true, data: data || [] });
  } catch (error) {
    console.error('getPopularRequests error:', error);
    res.status(500).json({ success: false, message: '인기 요청 조회에 실패했습니다.' });
  }
};
