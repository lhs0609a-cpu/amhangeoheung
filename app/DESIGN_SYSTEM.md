# 암행어흥 디자인 시스템

모바일 우선. 화면을 새로 만들거나 고칠 때 이 문서의 컴포넌트를 먼저 찾고,
없을 때만 새로 만든다.

```dart
import '../../../../shared/widgets/ui/ui.dart';   // 이 한 줄이면 전부 들어온다
```

---

## 1. 토큰

### 모션 — `AppMotion`

| 토큰 | 값 | 쓰는 곳 |
|---|---|---|
| `instant` | 90ms | 눌림, 색 변화 |
| `fast` | 140ms | 아이콘 토글, 체크, 뱃지 |
| `base` | 220ms | 기본. 카드 확장, 항목 등장 |
| `slow` | 320ms | 시트/다이얼로그 |
| `deliberate` | 480ms | 온보딩 히어로 연출 |

커브는 `standard`(기본) / `decelerate`(진입) / `accelerate`(이탈) /
`emphasized`(오버슈트) / `spring`(눌림 해제).

**300ms 를 넘는 마이크로 인터랙션은 만들지 않는다.** 모바일에서 느리게 느껴진다.

### 레이아웃 — `AppLayout`

- `gutter` 16 / `gutterCompact` 12 (360dp 미만 기기) — `AppLayout.gutterOf(context)`
- `sectionGap` 28 / `headerGap` 12 / `cardGap` 12
- `minTapTarget` **48** — 모든 탭 가능한 요소가 지켜야 하는 값
- `maxContentWidth` 560 — 태블릿에서 본문이 늘어지지 않게

`BuildContext` 확장으로 짧게 쓸 수 있다:

```dart
context.gutter          // 화면 폭에 맞는 좌우 여백
context.isShortHeight   // 세로가 짧은 기기 → 히어로 영역 축소
context.bottomInset     // 홈 인디케이터 높이
context.isKeyboardOpen
```

### 고도 — `AppElevation`

`level1`(칩·리스트 카드) → `level2`(기본 카드) → `level3`(떠 있는 바) →
`level4`(모달). 모두 **중립 그림자**다.
브랜드 컬러 그림자는 `AppElevation.glow(color)` 로만 쓰고, **화면당 한 곳**으로 제한한다.

---

## 2. 컴포넌트

### 버튼 — `AppButton`

```dart
AppButton.primary(label: '미션 신청', onPressed: _apply)     // 화면당 1개
AppButton.outline(label: '취소', onPressed: _cancel)
AppButton.tonal(label: '더보기', onPressed: _more)
AppButton.ghost(label: '건너뛰기', onPressed: _skip)
AppButton.danger(label: '해지하기', onPressed: _cancel)
```

- 크기: `small`(36) / `medium`(48, 기본) / `large`(56, 하단 주 CTA)
- `isLoading: true` → 스피너로 바뀌지만 **버튼 폭은 유지**된다 (레이아웃 점프 없음)
- 누르면 자동으로 축소 + 햅틱
- 글로우는 `primary` + `large` 조합에서만 켜진다

아이콘만 필요하면 `AppIconButton` — 아이콘이 16px 여도 터치 영역은 48dp 다.
`badgeCount` 로 알림 배지를 붙인다.

### 카드 — `AppCard`

```dart
AppCard(
  style: AppCardStyle.elevated,   // elevated | outlined | sunken | gradient | glass
  onTap: () => context.push('/missions/$id'),   // 주면 눌림 반응 + 햅틱이 자동
  child: ...,
)
```

- `AppStatTile` — 라벨 + 값 + 증감률
- `AppListRow` — 설정/메뉴 행 (최소 높이 56 보장)

### 섹션 — `AppSection` / `AppSectionHeader`

```dart
AppSection(
  title: '오늘의 추천 미션',
  emoji: '🎯',
  onAction: () => context.push('/missions'),   // 우측 '전체보기'
  child: ...,
)
```

`AppNotice` / `AppNotice.warning` / `AppNotice.success` — 안내 배너.
`AppDivider` — 좌우 여백이 들어간 구분선.

### 칩 — `AppChip` / `AppChipBar` / `AppBadge` / `AppProgressBar`

```dart
AppChipBar(labels: categories, selectedIndex: i, onSelected: (i) => ...)
AppBadge.missionType('hidden')       // 유형별 색/아이콘 자동
AppProgressBar(value: 0.7, autoColor: true)   // 마감 임박이면 빨강
```

### 시트 — 다이얼로그 대신 하단 시트

모바일에서 확인/선택은 화면 중앙 다이얼로그보다 **하단 시트**가 낫다.
엄지 도달 범위 안이고, 드래그로 닫을 수 있고, 맥락을 덜 가린다.

```dart
final ok = await showAppConfirm(
  context: context,
  title: '구독을 해지할까요?',
  message: '남은 기간은 그대로 사용할 수 있어요.',
  confirmLabel: '해지하기',
  destructive: true,
);

final picked = await showAppOptionSheet(
  context: context,
  title: '은행 선택',
  options: bankNames,
  selectedIndex: current,
);
```

### 토스트 — `AppToast`

`ScaffoldMessenger.showSnackBar` 를 직접 부르지 않는다.

```dart
AppToast.success(context, '미션 신청이 완료되었습니다');
AppToast.error(context, '네트워크 오류가 발생했습니다');   // 4초 + 강한 햅틱
AppToast.warning(context, '세션이 만료되었습니다');
AppToast.info(context, '임시 저장되었습니다');
```

하단 플로팅 네비게이션 위로 띄워지므로 CTA 를 가리지 않는다.

### 상태 — `AppEmptyState` / `AppErrorState` / `AppLoadingOverlay`

빈 상태는 "없음"으로 끝내지 말고 **다음 행동**을 준다.

```dart
AppEmptyState(
  icon: Icons.flag_outlined,
  title: '참여 가능한 미션이 없어요',
  message: '새 미션이 열리면 알려드릴게요',
  actionLabel: '알림 켜기',
  onAction: _enableAlerts,
)

// 메시지에서 네트워크 오류를 추정해 문구/아이콘을 바꾼다
AppErrorState.fromMessage(state.error!, onRetry: _reload)
```

### 화면 셸 — `AppScreen`

새 화면은 이걸로 시작한다. 하단 여백·제스처 인셋·당겨서 새로고침·
스크롤 반응 앱바·하단 고정 CTA 가 전부 붙어 있다.

```dart
AppScreen(
  title: '정산 내역',
  hasBottomNav: false,          // push 로 연 화면이면 false
  onRefresh: _reload,
  slivers: [...],
  bottomBar: AppBottomActionBar(
    child: AppButton.primary(label: '정산 신청', onPressed: _request),
  ),
)
```

---

## 3. 모바일 규칙

1. **하단 여백은 직접 계산하지 않는다.**
   `SizedBox(height: 120)` 대신 `AppBottomSpacer()`(탭 화면) /
   `AppBottomSpacer.plain()`(push 화면), sliver 안에서는 `SliverBottomSpacer`.
   기기별 홈 인디케이터 높이가 자동 반영된다.

2. **탭 가능한 모든 것은 48dp 이상.**
   시각적으로 작아야 하면 `Pressable` + `constraints: BoxConstraints(minHeight: 48)`.

3. **탭에는 반응이 있어야 한다.**
   `InkWell`/`GestureDetector` 대신 `Pressable` 을 쓰면 축소 애니메이션과
   햅틱이 함께 붙는다.

4. **햅틱은 의미 단위로.**
   `AppHaptics.tap()`(선택) / `press()`(확정) / `success()` / `error()`.

5. **키보드를 가리지 않는다.**
   하단 고정 바는 `AppBottomActionBar` / `AppStickyBar` 를 쓴다 —
   키보드가 올라오면 그 위로 따라 붙고, 닫히면 홈 인디케이터를 피한다.

6. **글자 크기 설정을 존중하되 상한을 둔다.**
   `main.dart` 에서 텍스트 배율을 0.9~1.3 으로 클램프한다.
   그 이상에서는 카드 안 2줄 레이아웃이 깨진다.

7. **긴 리스트에 순차 등장 애니메이션을 남용하지 않는다.**
   `FadeSlideIn.staggered(index: i, ...)` 는 앞의 8개까지만 지연을 준다
   (`AppMotion.staggerMaxItems`). 스크롤 성능 때문이다.

---

## 4. 레거시

`HwahaePrimaryButton` / `HwahaeSecondaryButton` / `HwahaeTextButton` 은
`AppButton` 의 얇은 래퍼로 남아 있다. 기존 호출부를 고치지 않고도 새 인터랙션을
물려받게 하기 위한 것이다. **새 코드에서는 `AppButton` 을 직접 쓴다.**

`HwahaeMissionCard` / `HwahaeInfoCard` / `HwahaeStatCard` 는 그대로 쓰되,
새로 만드는 카드는 `AppCard` 를 조합한다.
