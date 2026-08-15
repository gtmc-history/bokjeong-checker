#!/usr/bin/env bash
# 배포 전 게이트 — index.html과 review.html의 검사 엔진이 동일한지 확인한다.
# 두 파일에 엔진이 물리적으로 복사돼 있으므로, 한쪽만 고치는 사고를 여기서 막는다.
# 사용: bash check_engine_sync.sh   (같은 폴더에 index.html·review.html)
set -e
extract() {  # <script> 시작부터 UI 계층 시작 직전까지가 엔진
  python3 - "$1" <<'PY'
import sys
s = open(sys.argv[1], encoding='utf-8').read()
a = s.index('"use strict";', s.index('<script>'))
for mark in ('/* ============================================================\n   UI (V1.0 통합)',
             '/* ============================================================\n   담당자용 일괄 검토 UI'):
    if mark in s:
        print(s[a:s.index(mark)], end='')
        sys.exit(0)
sys.exit("UI 경계 표식을 찾지 못했습니다: " + sys.argv[1])
PY
}
H1=$(extract index.html  | sha256sum | cut -d' ' -f1)
H2=$(extract review.html | sha256sum | cut -d' ' -f1)
echo "index.html  엔진: $H1"
echo "review.html 엔진: $H2"
if [ "$H1" = "$H2" ]; then
  echo "✅ 엔진 동일 — 배포 가능"
else
  echo "❌ 엔진 불일치 — 한쪽만 수정되었습니다. index.html의 엔진을 review.html에 다시 복사하세요."
  exit 1
fi
