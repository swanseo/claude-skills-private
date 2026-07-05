# PICASEO Claude Skills Private

피카서(picaseo) 개인 Claude 커스텀 스킬 통합 저장소.

## 구조

- `labs/` — 실험 중인 스킬. 검증 후 production으로 승격
- `production/` — 실전 사용 중인 검증된 스킬
- `external/` — 외부 저장소 서브트리
- `docs/` — 스킬 관리 규칙 문서
- `scripts/` — 맥·윈도우 동기화 스크립트

## 동기화

- **맥북**: `~/.claude/skills/` ← 이 저장소 clone
- **윈도우**: `%USERPROFILE%\.claude\skills\` ← 이 저장소 clone

## 관련 시스템

- **Notion Skills Registry**: 메타데이터·검증 로그·승격 판단 기록
- **로컬 실행 환경**: Claude Code CLI (맥·윈도우)
- **웹 전역 스킬**: claude.ai Settings (독립 관리, 실험 스킬 위주)

## 승격·폐기 규칙

`docs/PROMOTION-RULES.md` 참조.
