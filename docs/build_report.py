"""Build a standalone, offline-readable report using only Python's standard library."""
from pathlib import Path
import base64
import html
import re
import struct

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent


def inline(text):
    text = html.escape(text)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    return re.sub(r'`([^`]+)`', r'<code>\1</code>', text)


def markdown(text):
    lines = text.splitlines()
    output = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue
        if line.startswith('#'):
            depth = min(len(line) - len(line.lstrip('#')) + 1, 5)
            output.append(f'<h{depth}>{inline(line.lstrip("# "))}</h{depth}>')
        elif line.startswith('|'):
            rows = []
            while index < len(lines) and lines[index].startswith('|'):
                cells = lines[index].strip('|').split('|')
                if not all(re.fullmatch(r'[\s:\-]+', cell) for cell in cells):
                    tag = 'th' if not rows else 'td'
                    rows.append('<tr>' + ''.join(f'<{tag}>{inline(c.strip())}</{tag}>' for c in cells) + '</tr>')
                index += 1
            output.append('<div class="table"><table>' + ''.join(rows) + '</table></div>')
            continue
        elif line.startswith('- '):
            items = []
            while index < len(lines) and lines[index].startswith('- '):
                items.append('<li>' + inline(lines[index][2:]) + '</li>')
                index += 1
            output.append('<ul>' + ''.join(items) + '</ul>')
            continue
        else:
            paragraph = [line]
            while index + 1 < len(lines) and lines[index + 1].strip() and not lines[index + 1].startswith(('#', '|', '- ')):
                index += 1
                paragraph.append(lines[index])
            output.append('<p>' + inline(' '.join(paragraph)) + '</p>')
        index += 1
    return '\n'.join(output)


def picture(path, description):
    contents = path.read_bytes()
    width, height = struct.unpack('>II', contents[16:24])
    encoded = base64.b64encode(contents).decode('ascii')
    return f'<img src="data:image/png;base64,{encoded}" alt="{html.escape(description)}" width="{width}" height="{height}">'


source = (ROOT / 'research/report-source.md').read_text(encoding='utf-8-sig')
spec = (ROOT / 'PRODUCT_SPEC.md').read_text(encoding='utf-8-sig')
validation = (ROOT / 'qa/VALIDATION.md').read_text(encoding='utf-8-sig')
concept = picture(ROOT / 'design/consumer-discovery-concept.png', '생성된 암행어흥 홈·검색·감찰 리포트 디자인 시안. 합성 예시 데이터.')
previews = ''.join('<figure>' + picture(ROOT / f'qa/{name}.png', f'{label} 실제 Flutter 위젯 렌더. 테스트 데이터.') + f'<figcaption>{label} · 테스트 데이터</figcaption></figure>'
                   for name, label in [('home', '홈'), ('search', '검색'), ('report', '공개 리포트')])

document = '''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>암행어흥 — 제품 설계와 품질 개선</title><style>
:root{color-scheme:light;--ink:#3d2e1f;--muted:#6b5c49;--cream:#fdf6e9;--line:#e9dcc7}
*{box-sizing:border-box}body{margin:0;background:var(--cream);color:var(--ink);font:16px/1.85 'Malgun Gothic',system-ui,sans-serif}
main{max-width:1120px;margin:auto;padding:36px 28px 90px}header{padding:28px 0 32px;border-bottom:1px solid var(--line)}
.eyebrow{font-size:13px;letter-spacing:.12em;font-weight:700}h1{font-size:46px;line-height:1.25;letter-spacing:-.06em;margin:18px 0}
.lead{font-size:20px;max-width:780px}.meta{color:var(--muted);font-size:14px}nav{display:flex;gap:12px;flex-wrap:wrap;margin:22px 0}
a{color:#83520f;text-underline-offset:4px}nav a{border:1px solid #ad9268;border-radius:24px;padding:8px 16px;background:white;text-decoration:none;min-height:48px}
section{scroll-margin-top:20px;margin-top:42px}h2{font-size:28px;line-height:1.5}h3{font-size:23px;margin-top:32px}h4{font-size:19px;margin-top:26px}
p,li{max-width:950px}li{margin:8px 0}img{display:block;max-width:100%;height:auto;border-radius:18px;border:1px solid var(--line)}
.gallery{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:22px}figure{margin:0}figcaption{font-size:14px;color:var(--muted);padding:12px 2px}
.panel{background:white;border:1px solid var(--line);border-radius:22px;padding:24px 30px;margin:24px 0}.table{overflow:auto}
table{border-collapse:collapse;width:100%;font-size:14px;margin:20px 0}td,th{padding:12px;text-align:left;border:1px solid var(--line);vertical-align:top}th{background:#f6ead3}
code{font:14px/1.5 Consolas,monospace;overflow-wrap:anywhere;background:#f6ead3;padding:2px 5px;border-radius:4px}details summary{cursor:pointer;font-size:22px;font-weight:700;padding:14px 0}
@media(max-width:700px){main{padding:18px 18px 48px}h1{font-size:32px}.lead{font-size:18px}.gallery{grid-template-columns:1fr}.gallery figure{max-width:390px;margin:auto}.panel{padding:16px}h2{font-size:24px}}
@media print{body{background:white}main{max-width:none;padding:0}nav{display:none}section{break-inside:auto}.panel,figure{break-inside:avoid}a{color:inherit}}
</style><main><header><div class="eyebrow">AMHANGEOHEUNG / PRODUCT & DESIGN</div>
<h1>좋은 가게를 고르는<br>새로운 기준</h1><p class="lead">기획의 중심을 지키면서, 탐색부터 감찰 근거 확인까지.<br>암행어흥 제품 설계 · 딥리서치 · 구현 개선 보고서</p>
<p class="meta">2026.09.09 · 저장소 기반 설계 · 공식 자료 조사 · 운영 배포 전 검증</p></header>
<nav aria-label="보고서 목차"><a href="#design">디자인 시안</a><a href="#implementation">실제 화면</a><a href="#research">조사 결과</a><a href="#spec">전체 설계</a><a href="#verification">검증과 한계</a></nav>
<section id="design"><h2>하나의 브랜드, 세 개의 핵심 화면</h2><p>생성형 디자인 시안입니다. 합성된 업체·사진·수치이며 운영 데이터가 아닙니다.</p>''' + concept + '''</section>
<section id="implementation"><h2>실제 Flutter 위젯으로 확인한 화면</h2><p>기존 캐릭터와 디자인 토큰을 사용한 구현입니다. 아래는 테스트 데이터를 주입한 렌더이며, 실제 서비스 접속 화면은 아닙니다.</p><div class="gallery">''' + previews + '''</div></section>
<section id="research" class="panel">''' + markdown(source) + '''</section>
<section id="spec" class="panel"><details open><summary>전체 화면군 · API · 권한 · 결제/정산 설계</summary>''' + markdown(spec) + '''</details></section>
<section id="verification" class="panel">''' + markdown(validation) + '''</section>
<footer class="meta">이 보고서는 저장소에서 확인한 기획을 복원한 결과입니다. 별도 원본 기획서·실운영 DB·실결제 검증은 포함하지 않습니다.</footer></main></html>'''
(ROOT / 'quality-report.html').write_text(document, encoding='utf-8')

screens = sorted((REPO / 'app/lib/features').rglob('*_screen.dart'))
routes = re.findall(r"path: '([^']+)'", (REPO / 'app/lib/app_router.dart').read_text(encoding='utf-8-sig'))
sql = sorted((REPO / 'backend').rglob('*.sql'))
sql = [path for path in sql if 'node_modules' not in path.parts]
inventory = ['# 저장소 문서·화면·데이터 설계 목록', '',
             '기준일 2026-09-09. 문서와 라우트/화면 파일 목록을 확인했다. 모든 소스 줄에 대한 감사 완료를 뜻하지 않는다.', '',
             '## 확인한 기존 문서', '',
             '- app/DESIGN_SYSTEM.md: 제품 원칙·토큰·컴포넌트·미완료 사항. 전문 확인.',
             '- app/DEPLOY.md: 환경별 빌드·회사정보·결제 키·배포 방식. 전문 확인.',
             '- app/README.md: 기존 Flutter 템플릿. 이번에 제품 문서 진입점으로 교체.',
             '- 별도 PDF/HWP/DOCX/PPTX/XLSX 기획서는 저장소에서 발견되지 않음.', '',
             '## 코드에 포함된 정책 근거', '',
             '- backend/src/config/constants.js: 역할·보상·기간·등급·유형·구독',
             '- app/lib/features/legal/data/legal_content.dart: 약관·개인정보·위치 정책(관련 조항 검토)',
             '- app/pubspec.yaml / backend/package.json: 구현 스택과 검증 명령',
             '- backend/src/routes / app/lib/app_router.dart: 역할별 접근·화면/API 계약', '',
             f'## 화면 파일 {len(screens)}개', '']
inventory += [f'- `{p.relative_to(REPO).as_posix()}`' for p in screens]
inventory += ['', f'## 라우트 {len(routes)}개', ''] + [f'- `{route}`' for route in routes]
inventory += ['', '## 스키마·마이그레이션 파일', ''] + [f'- `{p.relative_to(REPO).as_posix()}`' for p in sql]
(ROOT / 'repository-inventory.md').write_text('\n'.join(inventory) + '\n', encoding='utf-8')
print(f'Report: {len(document):,} characters; inventory: {len(screens)} screens, {len(routes)} routes, {len(sql)} SQL files')
