#!/usr/bin/env bash
#
# 김태효탑내과의원 홈페이지 배포 스크립트
# ---------------------------------------------------------------------------
# 사용법:  ./deploy.sh
#
# 하는 일 (한 번에):
#   1) website/ (작업본, 진실의 원천) → docs/ (Vercel 배포본) 동기화
#   2) Vercel 프로덕션 배포 (docs/ 폴더가 프로젝트에 연결돼 있음)
#   3) canonical 도메인(kimtaehyo-clinic-website.vercel.app) 별칭을 방금 배포로 자동 재지정
#      ※ 이 도메인은 프로덕션을 자동으로 따라가지 않는 고정 별칭이라 매번 재지정이 필요함
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
