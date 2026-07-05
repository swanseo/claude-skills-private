# 스킬 승격·폐기 규칙

## Lab → Production 승격 조건

각 lab 스킬의 검증 로그가 **3건 이상 누적**되면 리뷰:

- **승격**: 3건 중 2건 이상에서 명확한 품질 개선 확인
  - lab 폴더에서 production 폴더로 이동
  - Notion Skills Registry에서 상태를 🟢 Active로 변경
  - 관련 본체 스킬이 있으면 흡수 여부 결정
- **조건부 유지**: 특정 프로젝트에서만 작동
  - lab 폴더에 유지하되 SKILL.md에 조건부 항목 명시
- **폐기**: 오버 엔지니어링 또는 기존 스킬로 충분
  - `labs/archive/` 폴더로 이동 (삭제하지 않고 보관)
  - Notion Skills Registry에서 상태를 ⚫ Deprecated로 변경

## 커밋 메시지 규칙

- `feat(lab): add [스킬명] - [출처]`
- `promote: [스킬명] lab → production`
- `deprecate: [스킬명] moved to archive`
- `docs: update [문서명]`
- `fix(스킬명): [수정 내용]`
