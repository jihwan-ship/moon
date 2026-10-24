#!/bin/sh
# 사용: tools/snap.sh <씬 경로> <출력 폴더> <프레임 수> [fps] [사용자 인자...]
# Godot 무비 메이커로 씬을 프레임 단위 PNG로 찍는다.
SCENE=$1; OUT=$2; N=$3; FPS=${4:-30}; shift 4 2>/dev/null
mkdir -p "$OUT"
find "$OUT" -maxdepth 1 -name 'f*.png' -delete
cd "$(dirname "$0")/../game" || exit 1
timeout 300 xvfb-run -a -s "-screen 0 1280x720x24" /opt/godot/Godot_v4.3-stable_linux.x86_64 --path . --rendering-driver opengl3 \
  --write-movie "$OUT/f.png" --fixed-fps "$FPS" --quit-after "$N" "$SCENE" -- "$@" 2>&1 | grep -E "ERROR|SCRIPT|error|Parse" | head -20
