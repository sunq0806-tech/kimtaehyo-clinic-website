#!/usr/bin/env bash
#
# 김태효탑내과의원 홈페이지 배포 스크립트  [수동 폴백용]
# ===========================================================================
# ★ 기본 배포 방법은 이제 git push 입니다:
#       website/ 에서 수정 → git commit → git push origin main
#     → Vercel이 자동으로 프로덕션 배포하고(빌드 루트 = website/),
#       kimtaehyo-clinic-website.vercel.app 이 자동으로 최신 배포를 따라갑니다.
#     (2026-07-25 GitHub↔Vercel git 연동 완료. 별칭 수동 재지정 불필요.)
#
# 이 스크립트는 git 연동이 막혔을 때를 위한 CLI 수동 폴백입니다.
# ---------------------------------------------------------------------------
# 사용법:  ./deploy.sh
#
# 하는 일 (한 번에):
#   1) website/ (작업본, 진실의 원천) → docs/ (CLI 배포본) 동기화
#   2) Vercel 프로덕션 배포 (docs/ 폴더가 프로젝트에 연결돼 있음)
#   3) canonical 도메인 별칭을 방금 배포로 재지정 (지금은 도메인이 자동추종이라
#      belt-and-suspenders 성격 — 실패해도 프로덕션 도메인은 자동 갱신됨)
#   4) 라이브 도메인이 방금 배포 내용과 일치하는지 검증
#
# 전제: vercel CLI 로그인(sunq0806-tech) + docs/.vercel 링크 존재
# ---------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/website"
DEPLOY="$ROOT/docs"
DOMAIN="kimtaehyo-clinic-website.vercel.app"

command -v vercel >/dev/null 2>&1 || { echo "❌ vercel CLI가 없습니다. 'npm i -g vercel' 후 'vercel login'."; exit 1; }
[ -d "$SRC" ]    || { echo "❌ website/ 폴더를 찾을 수 없습니다: $SRC"; exit 1; }
[ -d "$DEPLOY/.vercel" ] || { echo "❌ docs/.vercel 링크가 없습니다. 'cd docs && vercel link' 로 프로젝트를 먼저 연결하세요."; exit 1; }

echo "▶ 1/4  website/ → docs/ 동기화"
# .vercel(프로젝트 링크)·.gitignore·.git·.DS_Store 는 보존/제외하고 내용만 미러링
rsync -a --delete \
  --exclude='.vercel' --exclude='.git' --exclude='.gitignore' --exclude='.DS_Store' \
  "$SRC"/ "$DEPLOY"/
echo "  동기화 완료"

echo "▶ 2/4  Vercel 프로덕션 배포"
cd "$DEPLOY"
DEPLOY_OUT="$(vercel --prod --yes 2>&1)"
DEPLOY_URL="$(printf '%s\n' "$DEPLOY_OUT" | grep -oE 'https://kimtaehyo-clinic-website-[a-z0-9]+-sunq0806-techs-projects\.vercel\.app' | head -1)"
if [ -z "$DEPLOY_URL" ]; then
  echo "  ❌ 배포 URL을 파싱하지 못했습니다. Vercel 출력:"; printf '%s\n' "$DEPLOY_OUT" | tail -20; exit 1
fi
echo "  배포됨: $DEPLOY_URL"

echo "▶ 3/4  canonical 도메인 별칭 재지정 → https://$DOMAIN"
vercel alias set "$DEPLOY_URL" "$DOMAIN" >/dev/null
echo "  별칭 재지정 완료"

echo "▶ 4/4  라이브 검증 (canonical 도메인이 방금 배포를 반영하는지)"
LOCAL_SUM="$(shasum "$DEPLOY/index.html" | awk '{print $1}')"
for i in $(seq 1 6); do
  LIVE_SUM="$(curl -s "https://$DOMAIN/index.html?cb=$RANDOM" | shasum | awk '{print $1}')"
  if [ "$LIVE_SUM" = "$LOCAL_SUM" ]; then
    echo "  ✅ 반영 확인 완료 → https://$DOMAIN"
    exit 0
  fi
  echo "  … 전파 대기 ($i/6)"; sleep 4
done
echo "  ⚠️ 아직 해시 불일치(캐시/전파 지연일 수 있음). 잠시 후 https://$DOMAIN 를 직접 확인하세요."
exit 0
