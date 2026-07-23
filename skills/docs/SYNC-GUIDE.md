# 맥·윈도우 동기화 가이드

## 초기 설치

### 맥북
```bash
cd ~/.claude
git clone https://github.com/swanseo/claude-skills-private.git skills
```

### 윈도우 (PowerShell)
```powershell
cd $env:USERPROFILE\.claude
git clone https://github.com/swanseo/claude-skills-private.git skills
```

## 일상 동기화

### 작업 시작 전 (다른 기기에서 변경 사항 가져오기)
```bash
cd ~/.claude/skills
git pull
```

### 스킬 수정 후 (변경 사항 저장)
```bash
cd ~/.claude/skills
git add .
git commit -m "feat(lab): [변경 내용 요약]"
git push
```

### 자동화 스크립트

- 맥: `scripts/sync-mac.sh` 실행
- 윈도우: `scripts/sync-windows.ps1` 실행
