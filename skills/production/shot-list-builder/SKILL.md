---
name: shot-list-builder
description: >
  광고 영상·시네마틱 콘텐츠의 샷 리스트와 프로덕션 스케줄을 작성할 때 반드시 사용할 것.
  사용자가 "샷 리스트", "shot list", "프로덕션 스케줄", "촬영 일정", "씬 리스트",
  "콘티 정리", "프로젝트 브리프", "광고 기획서", "샷 디비전", "샷 넘버링",
  "프리프로덕션 정리", "AI 영상 프로덕션 계획", "클립 리스트", "에피소드 구성",
  "멀티샷 시퀀스 계획", "촬영 우선순위" 등을 언급할 때마다 반드시 트리거.
  AI 영상 프로덕션(Seedance·Kling)의 샷 단위 기획에도 반드시 이 스킬 사용.
  결과물은 항상 Artifact로 출력하며, Notion·Excel 양쪽에 호환되는 포맷으로 제공.
---

# 샷 리스트 빌더 스킬

## 역할

광고·시네마틱·AI 영상 프로젝트의 프리프로덕션 단계에서
샷 리스트와 프로덕션 스케줄을 구조화한다.

전통적 실사 촬영과 AI 영상 생성 양쪽에 모두 적용 가능한 포맷.

---

## Step 1 — 프로젝트 메타데이터 확인

작업 시작 전 다음 항목을 사용자에게 확인하거나 KB에서 조회한다.

```
필수
  프로젝트명         : 
  클라이언트         : (있는 경우)
  최종 출력 길이     : 예) 30초 / 60초 / 6편 x 15초
  최종 출력 비율     : 예) 16:9 / 9:16 / 1:1
  배포 채널          : SNS / TVC / 인스타 릴스 / 유튜브 / 행사 LED
  마감일             : YYYY-MM-DD

권장
  무드보드 레퍼런스   : (이미지 URL 또는 키워드)
  컬러 톤            : 예) ARRI ALEXA 35mm warm shadows
  주요 키 메시지     : 한 줄 카피
  타깃 정서           : 한 줄 (예: 적막한 우아함, 폭발적 에너지)
```

---

## Step 2 — 샷 분할 원칙

### 시간 기반 분할 가이드

```
영상 길이      권장 샷 수        평균 샷 길이
─────────────────────────────────────────────
15초          5~8 샷           2~3초
30초          8~14 샷          2~3초
60초          15~25 샷         2.5~4초
3분 (뮤비)    40~70 샷         2.5~4.5초
시네마틱 단편 60~150 샷        다양
```

### AI 영상 특수 고려사항

- Seedance 2.0 / Kling 3.0 Omni 기본 클립 = 5초 (분할 시 2.5초 단위)
- 한 샷당 1회 생성 ≠ 1회 시도. 실패율 30~50% 가정해 버퍼 일정 확보
- 동일 캐릭터 다중 샷은 Soul ID 사용. Soul 없는 경우 reference element 활용

---

## Step 3 — 샷 리스트 표준 컬럼 구조

```
| Shot # | Scene | Description | Shot Type | Camera Move | Duration | 
|        |       |             |           |             |          |
| Subject | Lighting | Audio | Reference | AI Model | Prompt Status |
|         |          |       |           |          |               |
| Asset Source | Status | Notes |
|              |        |       |
```

### 각 컬럼 작성 기준

**Shot Type** (샷 타입 표기 표준)
```
ECU  — Extreme Close-Up
CU   — Close-Up
MCU  — Medium Close-Up
MS   — Medium Shot
MWS  — Medium Wide Shot
WS   — Wide Shot
EWS  — Extreme Wide Shot
OTS  — Over the Shoulder
POV  — Point of View
```

**Camera Move** (카메라 무브)
```
STATIC, PAN-L/R, TILT-U/D, DOLLY-IN/OUT,
TRUCK-L/R, PEDESTAL, CRANE, HANDHELD, GIMBAL
```

**Status** (진행 단계)
```
DRAFT → PROMPTED → GENERATED → SELECTED → GRADED → FINAL
```

---

## Step 4 — 출력 포맷 (반드시 Artifact)

### Markdown 표 포맷 (Notion 직접 붙여넣기 가능)

```markdown
# [프로젝트명] — Shot List
**버전**: v0.1 / 작성일 / 작성자  
**길이**: 60초 / **비율**: 16:9 / **마감**: YYYY-MM-DD

## 시퀀스 A — [씬 제목]

| # | Type | Move | Sec | Description | AI Model | Status |
|---|------|------|-----|-------------|----------|--------|
| A01 | ECU | STATIC | 2.5 | 손가락이 천천히 줄 위로 | Seedance 2.0 | DRAFT |
| A02 | MS  | DOLLY-IN | 3.0 | 인물 정면, 호흡 직전 | Kling 3.0 Omni | DRAFT |

## 시퀀스 B — [씬 제목]
...

---

## 프로덕션 일정

| 단계 | 시작 | 마감 | 산출물 |
|------|------|------|--------|
| 키샷 생성 | MM/DD | MM/DD | 5장 |
| 영상 1차 | MM/DD | MM/DD | 8클립 |
| Topaz 강화 | MM/DD | MM/DD | 8클립 ProRes |
| 컬러 그레이딩 | MM/DD | MM/DD | 60초 마스터 |
| 최종 딜리버리 | MM/DD | — | H.265 / ProRes |
```

### CSV 포맷 (Excel·Numbers 호환)

```csv
shot_number,scene,description,shot_type,camera_move,duration_sec,ai_model,status
A01,Opening,Finger on string,ECU,STATIC,2.5,Seedance 2.0,DRAFT
A02,Opening,Front shot breath,MS,DOLLY-IN,3.0,Kling 3.0 Omni,DRAFT
```

---

## Step 5 — AI 영상 프로덕션 일정 산출

피카서님 환경(Higgsfield Ultimate, RTX 4070 12GB) 기준 일정 계산식:

```
키샷 이미지 생성
  → 샷당 평균 3~5회 시도
  → Nano Banana Pro / Soul 2.0: 시도당 약 1분
  → 8샷 시퀀스: 약 30~50분

영상 클립 생성
  → 샷당 평균 2~4회 시도 (5초 클립)
  → Seedance 2.0: 시도당 약 3~5분 (큐 시간 포함)
  → 8샷 시퀀스: 약 1.5~3시간

Topaz Video AI 강화
  → 4K 5초 클립당 약 8~15분 (Proteus)
  → 8샷 시퀀스: 약 1~2시간

DaVinci 그레이딩
  → 8샷 시퀀스 기준 1~3시간 (Shot Match + 룩 적용)

총 소요(60초 시퀀스, 외부 대기 제외)
  → 약 1~2일 작업 (집중 시)
  → 클라이언트 피드백 1회 포함 시: 3~5일
```

---

## Step 6 — Notion KB 연동

생성된 샷 리스트는 PICASEO KB의 프로젝트 페이지에 다음 구조로 적재한다.

```
프로젝트 페이지
├── 01_Brief         (브리프·레퍼런스)
├── 02_ShotList      (이 스킬 출력물)
├── 03_Prompts       (샷별 프롬프트)
├── 04_Assets        (생성된 이미지·영상)
└── 05_Master        (최종 출력물)
```

---

## 누적 학습 메모

### 검증된 패턴
- 5초 단위 클립 사고가 AI 영상 시대의 새로운 샷 단위
- DRAFT → FINAL 6단계 상태 추적이 진행률 파악에 효과적

### 발견된 한계
- AI 영상 실패율은 프롬프트 정교함보다 모델 컨디션에 좌우됨
- 동일 캐릭터의 액션 연속성 보장이 여전히 가장 큰 변수

### 미검증 / 추후 테스트
- Soul 2.0 + Reference Element 동시 사용 시 일관성 비교
- Fable 5 기반 자동 샷 분할 가능성

---

## 참조 스킬
- `kling-3-omni-prompt` — 영상 프롬프트 작성 단계
- `seedance2-prompt` — 영상 프롬프트 작성 단계
- `storyboard-image-prompt` — 키샷 이미지 작성 단계
