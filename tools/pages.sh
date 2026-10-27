#!/bin/sh
# GitHub Pages용으로 웹 내보내기를 docs/에 만든다. docs/index.html이 실행 파일(첫 페이지)이다.
# 사용: tools/pages.sh  → 커밋, 푸시 후 GitHub 설정 > Pages에서 이 브랜치의 /docs 폴더를 고른다
cd "$(dirname "$0")/.." || exit 1
mkdir -p docs
timeout 300 /opt/godot/Godot_v4.3-stable_linux.x86_64 --headless --path game --export-release Web ../docs/index.html 2>&1 | grep -iE "error" | head
touch docs/.nojekyll
ls -la docs
