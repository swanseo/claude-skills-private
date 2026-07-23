---
name: topaz-video-settings
description: >
  Topaz Video AI의 모델 선택·파라미터 설정·익스포트 옵션을 결정할 때 반드시 사용할 것.
  사용자가 "토파즈", "Topaz", "Topaz Video AI", "TVAI", "영상 업스케일", "AI 영상 복원",
  "VHS 복원", "오래된 영상 복원", "노이즈 제거", "디인터레이스", "프레임 보간",
  "60fps 변환", "4K 업스케일", "Proteus", "Artemis", "Iris", "Rhea", "Nyx", "Chronos",
  "디테일 강화", "모션 블러 제거" 등을 언급할 때마다 반드시 트리거.
  AI 생성 영상(Seedance·Kling 출력)의 후반 강화 시에도 이 스킬 사용.
  단순 권장값 안내가 아닌, 소스 영상 분석 → 모델 매칭 → 파라미터 산출 → PICASEO KB 기록 흐름 전체를 다룬다.
---

# Topaz Video AI 설정 스킬

## 역할

소스 영상의 결함 유형을 진단하고, Topaz Video AI(TVAI) v5/v6 기준 최적 모델과 파라미터를 산출한다.
검증된 설정값은 PICASEO KB의 Topaz Video AI 항목에 누적 기록한다.

---

## Step 1 — 소스 영상 진단

사용자에게 다음 정보를 확인한다 (이미 명시되었다면 건너뜀).

```
1. 소스 종류        : 실사 / AI 생성 / 애니메이션 / VHS·필름 스캔
2. 해상도·프레임    : 예) 720x480 / 29.97fps interlaced
3. 목표 출력        : 예) 1080p 24fps / 4K 60fps
4. 주요 결함        : 노이즈·압축아티팩트·모션블러·인터레이스·해상도 부족
5. 콘텐츠 특성      : 인물 클로즈업 / 풍경 / 빠른 모션 / 텍스트 포함
```

---

## Step 2 — 결함 유형별 모델 매칭

### Enhancement (해상도 향상·디테일 복원)

| 모델 | 용도 | 비고 |
|------|------|------|
| **Proteus v4 (Fine Tune)** | 범용 실사, 파라미터 수동 조정 | 가장 유연함. 기본 선택지 |
| **Artemis** | 압축 아티팩트가 심한 영상 | 유튜브·SNS 다운로드 영상 |
| **Iris** | 인물 얼굴이 주된 영상 | 클로즈업·인터뷰 영상 |
| **Rhea** | AI 생성 영상의 디테일 정제 | Seedance·Kling 출력 강화에 적합 |
| **Nyx** | 노이즈 제거 전용 | 야간·고감도 촬영 영상 |
| **Gaia** | 애니메이션·CG | 라인아트 보존 |

### Frame Interpolation

| 모델 | 용도 |
|------|------|
| **Chronos** | 일반 프레임 보간 (24→60fps) |
| **Chronos Fast** | 빠른 처리, 약간의 품질 손실 |
| **Apollo** | 슬로우 모션 (8x 이상) |

### 디인터레이스
- **Dione TV** : 실사 인터레이스 영상
- **Dione DV**  : 디지털 비디오 인터레이스

---

## Step 3 — Proteus Fine Tune 파라미터 산출

Proteus는 6개 슬라이더가 핵심이다. 결함 유형별 시작값:

```
범용 실사 (1080p 업스케일)
  Detail         : 25
  Sharpen        : 15
  Noise          : 0  (노이즈 없을 때)
  Compression    : 30 (압축 흔적 있을 때)
  Anti-alias     : 20
  Recover        : 0

AI 생성 영상 강화 (Seedance·Kling 출력)
  Detail         : 15  ※ 과하면 페이크 디테일
  Sharpen        : 10
  Noise          : 5
  Compression    : 20
  Anti-alias     : 30
  Recover        : 10

VHS·오래된 영상 복원
  Detail         : 40
  Sharpen        : 20
  Noise          : 40
  Compression    : 60
  Anti-alias     : 50
  Recover        : 30
```

⚠️ 각 값은 시작점일 뿐. 반드시 5초 프리뷰로 검증 후 ±10 범위에서 조정.

---

## Step 4 — 익스포트 설정

### 코덱 선택

```
편집 소스용 (DaVinci Resolve 입력)
  → ProRes 422 HQ  (.mov)
  → 색공간: Rec.709 / Gamma 2.4

배포용 (최종 마스터)
  → H.265 (HEVC) Main10
  → 비트레이트: 1080p 25Mbps / 4K 50Mbps

WEB·SNS용
  → H.264 High
  → 1080p 12Mbps / 4K 35Mbps
```

### 컨테이너·프레임레이트

- AI 생성 영상은 가변 프레임률(VFR) 문제가 있을 수 있음 → **CFR 강제 변환** 필수
- 24fps 시네마틱 톤 유지 시 Chronos 보간 비활성화

---

## Step 5 — RTX 4070 12GB 환경 최적화

피카서님 환경(MSI RTX 4070 12GB, Ryzen 7 7700, 32GB) 기준:

```
동시 처리         : 1개 영상 (분할 처리)
프리뷰 메모리     : 8GB까지 사용 가능
4K Proteus 처리   : 약 0.7~1.2 FPS
4K Rhea 처리      : 약 0.5~0.8 FPS
백그라운드 작업   : Topaz 처리 중 Blender 렌더 동시 실행 금지

오버나이트 배치   : 4K 5분 영상 = 약 2~4시간 소요
                    여러 영상은 Queue에 등록 후 PC 슬립 비활성화
```

---

## Step 6 — PICASEO KB 기록 포맷

설정 검증 후 Notion KB의 Topaz Video AI 항목에 누적한다.

```
Tool         : Topaz Video AI
Category     : Video Enhancement
Status       : Verified / Testing / Failed
Last Tested  : YYYY-MM-DD
Version      : v6.x.x
Tags         : [모델명] [용도] [소스종류]
Source       : 본인 검증 / 공식 가이드 / 커뮤니티

[설정 본문]
- 소스: 1280x720 24fps H.264, Seedance 2.0 출력
- 모델: Rhea Enhancement
- 파라미터: Detail 15 / Sharpen 10 / Noise 5
- 출력: 1920x1080 24fps ProRes 422 HQ
- 결과: AI 노이즈 감소, 디테일 자연스러움 유지
- 비고: Detail 20 이상 시 페이크 텍스처 발생
```

---

## 누적 학습 메모

### 검증된 패턴
- AI 생성 영상은 Proteus보다 Rhea가 더 자연스러움
- VHS 복원은 Dione TV → Proteus 2단계 파이프라인이 효과적

### 발견된 한계
- 인물 얼굴 클로즈업에서 Iris 사용 시 표정이 미세하게 변형되는 경우 있음
- Chronos 보간은 폭발·물보라 같은 비정형 모션에서 아티팩트 발생

### 미검증 / 추후 테스트
- TVAI v6의 신규 모델 비교
- AV1 코덱 익스포트 안정성
- 멀티 GPU 환경에서의 처리속도 스케일링

---

## 참조 스킬
- `davinci-color-grade` — Topaz 출력 후 컬러 그레이딩 단계
