/**
 * 모집 중인 미션의 업체명을 가린다.
 *
 * `/missions/available` 은 애초에 name 을 선택하지 않아 블라인드였는데,
 * `/missions` 목록은 `business:businesses(id, name, ...)` 을 그대로
 * 내려주고 있었다. 로그인한 리뷰어라면 누구나 이 엔드포인트를 직접 불러
 * "어느 가게의 미션인지" 를 모집 단계에서 알 수 있었다는 뜻이다. 그러면
 * 골라 지원하게 되고, 무작위 배정과 담합 방지가 통째로 무의미해진다.
 *
 * 자기 업체 미션을 보는 사장님은 이름을 알아도 무방하므로 예외로 둔다.
 * owner_id 는 판정에만 쓰고 응답에서는 항상 뺀다.
 */
function blindRecruitingMissions(missions, viewerId) {
  return missions.map(m => {
    if (!m.business) return m;

    const { owner_id: ownerId, ...business } = m.business;

    const isRecruiting = m.status === 'recruiting';
    const isOwner = Boolean(ownerId) && ownerId === viewerId;
    if (!isRecruiting || isOwner) return { ...m, business };

    const { name, ...blindBusiness } = business;
    return { ...m, business: blindBusiness };
  });
}

module.exports = { blindRecruitingMissions };
