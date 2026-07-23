---
name: davinci-color-grade
description: >
  DaVinci Resolve에서 컬러 그레이딩 작업을 진행할 때 반드시 사용할 것.
  사용자가 "다빈치", "DaVinci", "Resolve", "컬러 그레이딩", "컬러 코렉션",
  "Shot Match", "스코프", "웨이브폼", "벡터스코프", "히스토그램", "퍼레이드",
  "ARRI", "ALEXA", "필름 에뮬레이션", "35mm 톤", "LUT 적용", "DCTL",
  "Power Window", "Qualifier", "노드 트리", "프라이머리", "세컨더리",
  "AI 영상 톤 통일", "클립 색조 매칭", "시네마틱 컬러" 등을 언급할 때마다 반드시 트리거.
  AI 생성 클립(Seedance·Kling) 간 색조 통일 작업에도 반드시 이 스킬 사용.
  4단계 학습 경로(스코프 → 노출·WB → Shot Match → 창의적 그레이딩) 기반.
---

# DaVinci Resolve 컬러 그레이딩 스킬

## 역할

DaVinci Resolve 18/19 기준 컬러 그레이딩 워크플로우를 설계·실행한다.
AI 생성 영상 클립들의 색조 통일을 핵심 목표로 하되,
일반 실사 영상 그레이딩도 동일 프레임워크 적용.

기준 룩: **ARRI ALEXA 35mm 필름 에뮬레이션**.

---

## Step 0 — 작업 시작 전 환경 확인

```
프로젝트 설정
  Color Science      : DaVinci YRGB Color Managed
  Input Color Space  : Rec.709 Gamma 2.4 (소스가 SDR인 경우)
                       또는 소스별 자동 태깅
  Timeline CS        : DaVinci WG / Intermediate
  Output CS          : Rec.709 Gamma 2.4

스코프 배치
  Waveform           : 노출 판단의 1차 기준
  Parade (RGB)       : 화이트밸런스 진단
  Vectorscope        : 스킨톤·채도 위치 확인
  Histogram          : 톤 분포 분포 확인 보조
```

⚠️ AI 생성 영상은 메타데이터가 없거나 부정확함. 수동으로 Rec.709 Gamma 2.4 태깅 권장.

---

## Step 1 — 스코프 리딩 (1차 진단)

각 클립을 다음 순서로 읽는다.

```
1. Waveform 0~100 IRE 분포
   - 흑점이 0 아래(crushed)인가? → Lift 조정 필요
   - 백점이 100 초과(clipped)인가? → Gain 조정 필요
   - 중간톤이 40~60에 모여있는가? → 정상

2. Parade RGB 균형
   - 세 채널의 흑점이 같은 높이? → WB 흑점 OK
   - 세 채널의 백점이 같은 높이? → WB 백점 OK
   - 한 채널이 튀어 있으면 → 색온도 편향

3. Vectorscope 스킨톤 라인
   - I선(주황 11시 방향)에 인물 스킨톤이 정렬?
   - 빗나가면 Hue 조정 또는 Qualifier 보정
```

---

## Step 2 — 프라이머리: 노출과 화이트밸런스

### 노드 1: Primary Correction

```
순서 엄수
  ① Lift     → 흑점을 0 IRE 직전까지 끌어내림
  ② Gain     → 백점을 100 IRE 직전까지 끌어올림
  ③ Gamma    → 중간톤 분포 조정
  ④ Offset   → 전체 톤 위치 미세 이동
  ⑤ Temperature / Tint → WB 보정
```

⚠️ Lift→Gain→Gamma 순서를 지키지 않으면 반복 작업 발생.

### AI 영상 특유의 문제

- Seedance 출력: 채도가 약간 들뜬 경향 → Saturation -5~-10
- Kling 출력: 흑점이 깊은 경향 → Lift +0.005~+0.01
- 클립별 색온도 편차 큼 → Shot Match 반드시 필요

---

## Step 3 — Shot Match (클립 간 통일)

AI 영상 시퀀스에서 가장 중요한 단계.

```
1. 기준 클립 선정 (Hero Shot)
   - 가장 잘 나온 클립 1개를 Reference로 지정

2. 우클릭 → Shot Match to This Clip
   - 인접 클립들을 자동 매칭

3. 수동 미세 조정
   - 자동 매칭은 70% 정도만 맞춤
   - Parade RGB로 흑·백·중간점 재정렬
   - Vectorscope로 스킨톤 위치 재조정

4. Album에 Reference Still 저장
   - 시퀀스 전체에서 비교 기준으로 사용
```

---

## Step 4 — 창의적 그레이딩 (ARRI ALEXA 35mm 톤)

### 노드 구조

```
[Node 1] Primary       — 노출·WB
[Node 2] Color Wheel   — 룩 형성 (Lift/Gamma/Gain 색상)
[Node 3] Curves        — 톤 곡선 (S-Curve)
[Node 4] Saturation    — 채도 분포 조정
[Node 5] Film Look     — 필름 에뮬레이션 LUT 또는 DCTL
[Node 6] Power Window  — 비네팅·부분 보정
[Node 7] Output Trim   — 최종 미세 조정
```

### ARRI ALEXA 톤의 핵심 특성

```
Shadows  → 약한 청록 편향 (Lift Wheel: Cyan-Blue 쪽 5~10도)
Midtones → 따뜻한 황색 (Gamma Wheel: Orange 쪽 5도)
Highlights → 약한 황색 잔향 (Gain Wheel: Yellow 쪽 3~5도)
Skin tone  → I선 정확 정렬, 채도는 자연 유지

대비
  Soft Roll-off : 백점 90~95 IRE에서 부드럽게 압축
  Toe           : 흑점 5~10 IRE에서 부드럽게 lift
```

### 35mm 필름 그레인

- Resolve 내장 Film Grain OFX 사용
- Intensity: 0.5~1.0 (과하면 디지털 노이즈처럼 보임)
- 16mm가 아닌 35mm 프리셋 선택

---

## Step 5 — Power Window·Qualifier (세컨더리)

### 자주 쓰는 시나리오

```
인물 스킨톤 단독 보정
  → HSL Qualifier로 스킨톤 선택
  → 별도 노드에서 채도·휴만 조정
  → Mask Refinement로 경계 부드럽게

배경 분위기 차별화
  → Power Window로 배경 분리
  → 별도 Color Wheel로 청록 편향
  → Tracking으로 카메라 움직임 따라가게

하늘 채도 강화
  → Qualifier Blue 선택
  → Saturation +20, Hue -5
```

---

## Step 6 — 익스포트 및 검증

```
Deliver 페이지 설정
  Codec      : ProRes 422 HQ (편집·교정용)
               H.265 Main10 (배포용)
  Color Tag  : Rec.709 / Gamma 2.4
  Resolution : 1920x1080 또는 3840x2160
  Frame Rate : 24fps (시네마틱)

검증 체크
  □ HDMI 외부 모니터에서 톤 확인
  □ 스마트폰에서 SNS 톤 확인 (자동 톤 매핑 영향)
  □ 노트북 화면에서 어두운 디테일 손실 여부
```

---

## 누적 학습 메모

### 검증된 패턴
- AI 영상은 Shot Match → 수동 보정 → ARRI 룩 적용 3단 구조가 효과적
- ARRI 톤은 Lift Cyan-Blue + Gamma Orange가 핵심 공식

### 발견된 한계
- AI 생성 영상에서 인물이 등장하는 프레임마다 스킨톤 편차가 큼
- Resolve 자동 Shot Match는 강한 색조 차이가 있을 때 실패

### 미검증 / 추후 테스트
- DaVinci 19 신규 AI Color Match 정확도
- Resolve 내장 Film Look Creator vs 외부 LUT 비교
- DCTL 스크립트로 ARRI LogC → Rec.709 변환 직접 작성

---

## 참조 스킬
- `topaz-video-settings` — 그레이딩 전 영상 강화 단계
