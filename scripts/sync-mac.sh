#!/bin/bash
# PICASEO Claude Skills 맥 동기화 스크립트

SKILLS_PATH="$HOME/.claude/skills"

echo "PICASEO Claude Skills 동기화 시작"
cd "$SKILLS_PATH" || exit 1

echo "원격 변경 사항 확인 중..."
git fetch

STATUS=$(git status -uno)

if echo "$STATUS" | grep -q "Your branch is behind"; then
    echo "원격에 새 변경 사항 있음. Pull 진행..."
    git pull
elif echo "$STATUS" | grep -q "up to date"; then
    echo "이미 최신 상태입니다."
else
    echo "로컬 변경 사항 있음:"
    git status --short
    read -r -p "커밋하고 푸시하시겠습니까? (y/n) " confirm
    if [ "$confirm" = "y" ]; then
        read -r -p "커밋 메시지: " message
        git add .
        git commit -m "$message"
        git push
    fi
fi

echo "완료."
