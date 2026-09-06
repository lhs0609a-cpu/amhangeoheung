import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_typography.dart';
import 'app_button.dart';

/// 화면 공통 셸.
///
/// 앱 전체가 이 셸을 쓰면 아래가 자동으로 해결된다.
///   - 하단 플로팅 네비게이션에 콘텐츠가 가리지 않는 스크롤 여백
///   - 홈 인디케이터/제스처 인셋 회피
///   - 당겨서 새로고침
///   - 스크롤에 반응하는 반투명 앱바(뒤 콘텐츠가 비쳐 보임)
///   - 하단 고정 CTA
///
/// [slivers] 를 주면 CustomScrollView 로, [child] 를 주면 단일 스크롤로 그린다.
class AppScreen extends StatefulWidget {
  /// 앱바 제목. null 이면 앱바를 그리지 않는다.
  final String? title;

  /// 제목 아래 작은 설명. 스크롤을 내리면 사라진다.
  final String? subtitle;

  /// 뒤로가기 버튼 표시 (기본: Navigator 스택이 있으면 자동 표시)
  final bool? showBack;
  final VoidCallback? onBack;

  /// 앱바 우측 액션들
  final List<Widget> actions;

  /// 단일 위젯 본문 (스크롤됨)
  final Widget? child;

  /// sliver 목록 본문. [child] 보다 우선한다.
  final List<Widget>? slivers;

  /// 당겨서 새로고침 핸들러
  final Future<void> Function()? onRefresh;

  /// 하단 고정 액션 바 (예: "미션 참여하기" 버튼)
  final Widget? bottomBar;

  /// 하단 플로팅 네비게이션이 있는 탭 화면인지.
  /// true 면 스크롤 하단에 네비게이션 높이만큼 여백을 자동으로 넣는다.
  final bool hasBottomNav;

  /// 본문 좌우 여백을 자동 적용할지 ([child] 모드에서만 유효)
  final bool applyGutter;

  final Color? backgroundColor;

  /// 스크롤 없이 고정된 본문 (폼처럼 자체 스크롤을 갖는 화면)
  final bool scrollable;

  const AppScreen({
    super.key,
    this.title,
    this.subtitle,
    this.showBack,
    this.onBack,
    this.actions = const [],
    this.child,
    this.slivers,
    this.onRefresh,
    this.bottomBar,
    this.hasBottomNav = false,
    this.applyGutter = true,
    this.backgroundColor,
    this.scrollable = true,
  });

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final ScrollController _controller = ScrollController();

  /// 앱바 아래로 콘텐츠가 지나갔는지. 그림자/블러를 켜는 기준.
  bool _scrolledUnder = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _controller.hasClients && _controller.offset > 4;
    if (scrolled != _scrolledUnder) {
      setState(() => _scrolledUnder = scrolled);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool get _canPop => Navigator.of(context).canPop();

  bool get _showBack => widget.showBack ?? _canPop;

  double get _bottomPadding {
    return AppLayout.bottomScrollInset(
      context,
      withNavBar: widget.hasBottomNav,
      // 하단 고정 바가 있으면 그 높이만큼 더 띄운다.
      extra: widget.bottomBar != null ? 76 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutterOf(context);

    Widget body;
    if (widget.slivers != null) {
      body = CustomScrollView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          ...widget.slivers!,
          SliverToBoxAdapter(child: SizedBox(height: _bottomPadding)),
        ],
      );
    } else if (widget.scrollable) {
      body = SingleChildScrollView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          widget.applyGutter ? gutter : 0,
          0,
          widget.applyGutter ? gutter : 0,
          _bottomPadding,
        ),
        child: widget.child ?? const SizedBox.shrink(),
      );
    } else {
      body = widget.child ?? const SizedBox.shrink();
    }

    if (widget.onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: () async {
          AppHaptics.tap();
          await widget.onRefresh!();
        },
        color: HwahaeColors.primary,
        backgroundColor: HwahaeColors.surface,
        // 앱바 아래에서 인디케이터가 나타나도록
        displacement: 24,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? HwahaeColors.background,
      // 앱바를 반투명으로 쓰기 위해 본문을 앱바 뒤까지 확장한다.
      extendBodyBehindAppBar: widget.title != null,
      appBar: widget.title == null
          ? null
          : AppTopBar(
              title: widget.title!,
              subtitle: widget.subtitle,
              showBack: _showBack,
              onBack: widget.onBack,
              actions: widget.actions,
              scrolledUnder: _scrolledUnder,
            ),
      body: SafeArea(
        // 하단은 스크롤 패딩으로 직접 처리하므로 SafeArea 에서 제외한다.
        bottom: false,
        child: AppLayout.constrain(body),
      ),
      bottomNavigationBar: widget.bottomBar,
    );
  }
}

/// 스크롤에 반응하는 반투명 앱바.
///
/// 스크롤 전에는 배경과 완전히 섞이고, 콘텐츠가 뒤로 지나가면 블러 + 미세한
/// 구분선이 켜진다. iOS 의 large title 축소와 같은 계열의 신호다.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool scrolledUnder;

  /// 제목을 가운데 정렬할지
  final bool centerTitle;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.scrolledUnder = false,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 66);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: scrolledUnder
            ? ImageFilter.blur(sigmaX: 18, sigmaY: 18)
            : ImageFilter.blur(sigmaX: 0.001, sigmaY: 0.001),
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: scrolledUnder ? AppGlass.surface : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: scrolledUnder
                    ? HwahaeColors.borderLight
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Row(
                children: [
                  if (showBack)
                    AppIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 19,
                      tooltip: '뒤로',
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                    )
                  else
                    SizedBox(width: AppLayout.gutterOf(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: centerTitle
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: HwahaeTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: HwahaeTypography.captionSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ...actions,
                  if (actions.isEmpty)
                    SizedBox(width: AppLayout.gutterOf(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 큰 제목이 스크롤에 따라 앱바 제목으로 축소되는 헤더 sliver.
///
/// 홈/프로필처럼 첫 화면 인상이 중요한 곳에 쓴다.
class AppLargeHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// 헤더 아래에 붙는 위젯 (검색 바 등)
  final Widget? bottom;
  final double bottomHeight;

  const AppLargeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: HwahaeColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: (subtitle == null ? 96 : 116) + bottomHeight,
      collapsedHeight: 56 + bottomHeight,
      actions: actions.isEmpty ? null : [...actions, const SizedBox(width: 4)],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: AppLayout.gutterOf(context),
          bottom: 14 + bottomHeight,
        ),
        title: Text(
          title,
          style: HwahaeTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        // 접힐 때 제목이 커졌다 작아지는 기본 동작을 유지하되 배경은 단색으로.
        background: Container(color: HwahaeColors.background),
      ),
      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(bottomHeight),
              child: bottom!,
            ),
    );
  }
}

/// 스크롤 위에 떠 있는 하단 고정 액션 바.
///
/// AppScreen 의 [AppScreen.bottomBar] 에 넣어 쓴다.
class AppBottomActionBar extends StatelessWidget {
  final Widget child;

  /// 버튼 위 보조 정보 (총 금액, 남은 시간 등)
  final Widget? info;

  const AppBottomActionBar({super.key, required this.child, this.info});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: AppMotion.base,
      curve: AppMotion.standard,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.gutterOf(context),
          12,
          AppLayout.gutterOf(context),
          // 키보드가 올라온 상태에서는 홈 인디케이터 여백이 필요 없다.
          12 + (keyboardInset > 0 ? 0 : bottomInset),
        ),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          boxShadow: AppElevation.level3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info != null) ...[
              info!,
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
