"""제미나이 원본에서 캐릭터 에셋을 만든다.

원본(`캐릭터이미지/`, 2048px)에는 **투명 체커보드가 픽셀로 그려져 있다.**
진짜 알파가 아니라 밝은 회색(#FDFDFD)과 어두운 회색(#DFDFDF)이 번갈아 칠해진
그림이다. 그대로 줄여서 쓰면 앱에서 캐릭터 뒤에 회색 격자 사각형이 나타난다.
(한 번 그렇게 배포될 뻔했다 — 골든 테스트에 격자가 찍혀서 잡았다.)

그래서 이 스크립트가 하는 일은 세 가지다.

1. **체커보드를 진짜 투명으로 바꾼다.** 회색이라고 다 지우면 사또의 흰 얼굴
   하이라이트와 어흥이의 크림색 배까지 뚫린다. 그래서 "무채색 + 체커 색"인
   픽셀 중 **테두리에서 연결된 덩어리만** 지운다. 캐릭터 안쪽의 흰색은
   바깥과 이어져 있지 않으므로 살아남는다.

2. **경계의 회색 띠를 걷어낸다.** 안티에일리어싱된 가장자리는 캐릭터 색과
   체커 회색이 섞인 픽셀이다. 알파만 0으로 만들면 그 띠가 남아 회색 후광이
   된다. 알파를 1px 깎고, 지워진 자리의 RGB 를 가장 가까운 캐릭터 색으로
   메워서(inpaint) 축소할 때 회색이 번지지 않게 한다.

3. **먹색 배경용 변형을 만든다.** 갓과 도포가 어두워서 다크 카드 위에 올리면
   실루엣이 배경에 먹힌다. 실루엣 바깥으로 크림색 테두리를 둘러 띄운다.

실행:  python scripts/build_characters.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

APP = Path(__file__).resolve().parent.parent
SRC = APP.parent / "캐릭터이미지"
DST = APP / "assets" / "characters"

# 내보내는 크기. 가장 큰 사용처가 온보딩/스플래시의 140pt 이고 3x 화면이
# 420px 이므로 512 면 충분하다. 더 키우면 번들만 커진다.
OUT_SIZE = 512

# 크림. HwahaeColors.background 와 같은 값이어야 다크 변형의 테두리가
# 앱 배경과 같은 계열로 읽힌다.
CREAM = (253, 246, 233)

# 체커로 볼 밝기 구간. 원본 히스토그램에서 직접 잰 값이다.
#
# 어두운 칸이 220, 밝은 칸이 **순백 255**, 두 칸 사이 이음매가 그 중간에
# 깔린다. 셋을 한 구간으로 덮어야 한다.
#
# 여기를 253 에서 끊어봤다가 밝은 칸이 통째로 남아 체커 절반이 그대로
# 살아난 적이 있다. 캐릭터의 흰자위도 같은 순백이지만, 그쪽은 두꺼운
# 윤곽선에 둘러싸여 바깥과 이어지지 않으므로 연결 판정에서 살아남는다 —
# 색이 아니라 **연결이** 캐릭터와 배경을 가른다.
CHECKER_BANDS = ((213, 255),)

# 무채색 판정. 체커는 R=G=B 이고 캐릭터의 크림/살구/올리브색은 채널 차가 크다.
NEUTRAL_TOL = 8

# 이보다 작은 조각은 캐릭터가 아니라 잡티로 본다 (2048px 원본 기준 픽셀 수).
#
# 원본이 압축을 거쳐서 체커 칸에도 채널이 살짝 어긋난 픽셀이 흩어져 있다.
# 무채색 판정을 통과하지 못한 그 픽셀들이 불투명한 점으로 남고, 512 로
# 줄이면 옅은 체커 무늬 유령이 된다. 다크 변형에서는 그 유령까지 테두리로
# 부풀어 화면이 크림색으로 덮였다. 눈썹처럼 떨어져 있는 진짜 부속은
# 남기고 점만 걷어내는 크기가 이 값이다.
MIN_PART = 400

# 연결 판정에만 쓰는 팽창 반경.
#
# 밝은 칸과 어두운 칸 사이에는 두 색이 섞인 이음매가 있는데, 그 값이 위
# 두 구간 사이의 빈틈에 떨어진다. 그대로 두면 칸마다 따로 놀아서 테두리에
# 닿지 않는 안쪽 칸이 흰 사각형으로 남는다(실제로 남았다). 이음매를 메워
# 체커 전체를 한 덩어리로 만든 뒤 테두리 연결을 따진다.
BRIDGE = 3

SOURCES = {
    # 파일명 조각 → 내보낼 이름
    "vdex07": "eoheung",
    "hvc0fa": "sato",
}


def find_source(fragment: str) -> Path:
    for p in sorted(SRC.glob("*.png")):
        if fragment in p.name:
            return p
    raise SystemExit(f"원본을 찾지 못했다: *{fragment}*  ({SRC})")


def knockout(rgb: np.ndarray) -> np.ndarray:
    """체커보드 배경을 찾아 불리언 마스크로 돌려준다 (True = 배경)."""
    spread = rgb.max(axis=2).astype(np.int16) - rgb.min(axis=2).astype(np.int16)
    neutral = spread <= NEUTRAL_TOL

    value = rgb.mean(axis=2)
    near_checker = np.zeros_like(neutral)
    for low, high in CHECKER_BANDS:
        near_checker |= (value >= low) & (value <= high)

    candidate = neutral & near_checker

    # 테두리에 닿은 덩어리만 배경이다. 캐릭터 안쪽의 흰자위·수염은 두꺼운
    # 검은 윤곽선에 둘러싸여 바깥과 이어지지 않으므로 여기서 살아남는다.
    #
    # 연결은 팽창시킨 마스크에서 따지되, 지우는 것은 원래 마스크뿐이다.
    # 팽창한 채로 지우면 윤곽선이 같이 깎인다.
    bridged = ndimage.binary_dilation(candidate, iterations=BRIDGE)
    labels, count = ndimage.label(bridged)
    if count == 0:
        return candidate

    edge = np.concatenate(
        [labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]]
    )
    outside = np.unique(edge)
    outside = outside[outside != 0]
    background = np.isin(labels, outside) & candidate

    return background | speckles(background)


def speckles(background: np.ndarray) -> np.ndarray:
    """배경에 남은 잡티(작게 흩어진 불투명 조각)를 찾는다."""
    foreground = ~background
    labels, count = ndimage.label(foreground)
    if count == 0:
        return np.zeros_like(background)

    areas = np.bincount(labels.ravel())
    small = np.flatnonzero(areas < MIN_PART)
    small = small[small != 0]
    return np.isin(labels, small)


def inpaint(rgb: np.ndarray, background: np.ndarray) -> np.ndarray:
    """배경 픽셀의 색을 가장 가까운 캐릭터 색으로 덮는다.

    알파가 0 이어도 축소할 때는 RGB 가 이웃과 섞인다. 회색을 그대로 두면
    가장자리에 회색 실루엣이 번진다.
    """
    _, indices = ndimage.distance_transform_edt(
        background, return_indices=True
    )
    return rgb[indices[0], indices[1]]


def build_base(path: Path) -> Image.Image:
    src = Image.open(path).convert("RGB")
    rgb = np.array(src)

    background = knockout(rgb)
    filled = inpaint(rgb, background)

    alpha = np.where(background, 0, 255).astype(np.uint8)

    # 안티에일리어싱된 회색 띠를 1px 깎아낸다. 2048px 원본에서 1px 은
    # 512 로 줄이면 0.25px 이라 실루엣이 얇아진 것을 알아볼 수 없다.
    alpha_img = Image.fromarray(alpha).filter(ImageFilter.MinFilter(3))
    # 계단을 죽인다. 축소가 대부분 해주지만 이쪽이 가장자리가 더 곱다.
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(0.8))

    out = Image.fromarray(filled).convert("RGBA")
    out.putalpha(alpha_img)

    return trim_square(out)


def trim_square(im: Image.Image) -> Image.Image:
    """캐릭터에 맞춰 자르고, 정사각형 캔버스 가운데에 여백과 함께 놓는다.

    원본은 캐릭터 주위 여백이 제각각이라 그대로 쓰면 화면마다 캐릭터 크기가
    다르게 보인다. 바운딩 박스를 기준으로 통일한다.
    """
    bbox = im.getchannel("A").getbbox()
    if bbox is None:
        raise SystemExit("알파가 전부 0 이다 — 배경 판정이 캐릭터까지 먹었다")
    cropped = im.crop(bbox)

    # 가장 긴 변 기준 8% 여백. 테두리를 두르는 다크 변형이 잘리지 않을 만큼.
    side = max(cropped.size)
    canvas = int(side * 1.16)
    square = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    square.paste(
        cropped,
        ((canvas - cropped.width) // 2, (canvas - cropped.height) // 2),
    )
    return square.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)


def with_cream_outline(im: Image.Image, width: int = 7) -> Image.Image:
    """실루엣 바깥에 크림색 테두리를 두른다 (먹색 배경용)."""
    alpha = im.getchannel("A")
    # 최대 필터로 실루엣을 넓힌다. 커널은 홀수여야 한다.
    grown = alpha.filter(ImageFilter.MaxFilter(width * 2 + 1))
    grown = grown.filter(ImageFilter.GaussianBlur(0.6))

    outline = Image.new("RGBA", im.size, CREAM + (0,))
    outline.putalpha(grown)
    return Image.alpha_composite(outline, im)


def report(name: str, im: Image.Image) -> None:
    a = np.array(im.getchannel("A"))
    print(
        f"  {name:18s} {im.width}x{im.height} "
        f"투명 {100 * (a == 0).mean():4.1f}%  불투명 {100 * (a == 255).mean():4.1f}%"
    )


def main() -> int:
    if not SRC.is_dir():
        raise SystemExit(f"원본 폴더가 없다: {SRC}")
    DST.mkdir(parents=True, exist_ok=True)

    for fragment, name in SOURCES.items():
        source = find_source(fragment)
        print(f"{source.name}  →  {name}")

        base = build_base(source)
        base.save(DST / f"{name}.png", optimize=True)
        report(f"{name}.png", base)

        dark = with_cream_outline(base)
        dark.save(DST / f"{name}_dark.png", optimize=True)
        report(f"{name}_dark.png", dark)

    return 0


if __name__ == "__main__":
    sys.exit(main())
