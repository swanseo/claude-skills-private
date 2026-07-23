---
name: visual-motion-analysis
description: >
  영상(유튜브 링크 포함)·이미지·GIF의 비주얼·모션을 분석해야 할 때 반드시 사용할 것.
  사용자가 "영상 분석", "모션 분석", "비주얼 분석", "이 영상 어떻게 만든 건지",
  "레퍼런스 분석", "씬 분석", "컷 타이밍", "optical flow", "포즈 추정",
  "동작 인식", "영상 특화 모델", "카메라 무빙 분석", "편집 리듬 분석" 등을
  언급할 때마다 트리거. 특정 프로젝트에 종속되지 않는 범용 분석 워크플로우 —
  어느 프로젝트에서든 적용.
---

# 비주얼·모션 분석 스킬

## 역할

영상/이미지의 "무엇을 어떻게 움직였는가"를 분석하되, 목표에 따라 두 갈래로 나눈다.

```
의미적 설명이 필요한가?          → 멀티모달 LLM (Step 1)
정량적 수치가 필요한가?          → 로컬 CV 도구 (Step 2, 3)
둘 다 필요하면 두 갈래를 병행해서 교차 검증한다.
```

---

## Step 1 — 이미 연결된 MCP 도구 우선 사용 (설치 불필요)

프로젝트 무관하게 이 환경에서 바로 쓸 수 있는 것부터 확인:

- **`video_analysis_create`** (+ `video_analysis_status`) — 유튜브 URL을 직접 넣으면 씬 단위(scene-by-scene) 분석. 3~5분 소요. 짧은 클립일수록 정확도 높음. 업로드된 영상(`media_upload`)도 가능.
- **`virality_predictor`** — 후킹 강도·몰입도·리텐션 리스크 등 어텐션 관점 분석. "왜 이 편집이 반응이 좋은가" 류 질문에 적합.
- **멀티모달 비전(Claude 자체)** — 스크린샷/프레임을 직접 읽어 구도·색감·연출 의도를 설명. 수치는 못 주지만 가장 빠름.
- **HF 모델·논문 검색** (`hub_repo_search`, `paper_search`, `space_search`) — 특정 분석에 맞는 모델이 이미 있는지 먼저 찾아본다. 아래 Step 4 참조 목록과 중복되면 검색 생략 가능.

이 단계만으로 끝나는 요청이 대부분이다. 정량값(픽셀 단위 속도, 정확한 오프셋 등)이 실제로 필요할 때만 아래로 내려간다.

---

## Step 2 — 로컬 도구 (설치 완료, 즉시 사용 가능)

이 머신에 이미 설치되어 있음 (2026-07-22 확인):

```
ffmpeg      8.1.2   — 프레임 추출, 모든 분석의 전제
scenedetect 0.7.1   — 컷 타이밍 추출 (opencv 백엔드 포함)
opencv-python 5.0.0 — scenedetect 의존성, 기초 optical flow도 이걸로 가능
```

### 프레임 추출
```bash
ffmpeg -i input.mp4 -vf "select='not(mod(n\,10))'" -vsync vfr frame_%04d.png
```

### 컷 타이밍 추출
```bash
scenedetect -i input.mp4 detect-content list-scenes
# 또는 detect-adaptive (조명 변화가 심한 소스에 더 안정적)
```

### 기초 optical flow (opencv, 이미 설치됨 — 추가 설치 없이 바로 가능)
```python
import cv2
flow = cv2.calcOpticalFlowFarneback(prev_gray, next_gray, None,
                                     0.5, 3, 15, 3, 5, 1.2, 0)
# flow[...,0], flow[...,1] = x,y 방향 픽셀 이동량 (프레임당)
```
Farneback은 정밀도가 낮지만 설치 비용 zero. "대략 초당 몇 px, 어느 방향" 수준이면 충분.

---

## Step 3 — 추가 설치가 필요한 경우 (무거운 의존성, 필요할 때만)

기본은 **설치하지 않는다.** 눈으로/Farneback으로 판정 안 되는 상황이 실제로 생겼을 때만:

| 필요 | 도구 | 설치 |
|---|---|---|
| 정밀 optical flow | RAFT | `pip install torch` (2GB+) 후 RAFT 체크포인트 |
| 임의 점 추적 (스태거 오프셋 분석 등) | CoTracker (Meta) | torch 필요 |
| 사람 관절·포즈 추적 | MediaPipe Pose | `pip install mediapipe` (가벼움, 바로 설치해도 무방) |
| 영상+언어 통합 이해 (장시간 씬 흐름) | Qwen2.5/3-VL, V-JEPA2 | 로컬 추론은 무거움 — 대개 Step 1의 `video_analysis_create`로 대체 가능 |
| 동작 분류 | VideoMAE, TimeSformer | 특정 동작 라벨링이 명시적으로 필요할 때만 |

torch급 설치는 사용자에게 먼저 알리고 진행 — 용량·시간이 크다.

---

## Step 4 — 판정 시 주의 (일반 원칙)

수치 데이터는 **패턴의 존재**를 알려줄 뿐 **수식적 정체**를 알려주지 않는다.

> optical flow가 "초당 40px 우상향"이라고 알려줘도, 그게 사인파 합성인지 ease 보간인지
> 지수감쇠인지는 별도 판단이 필요하다. 관찰값과 해석(가설)을 분리해서 보고할 것.

프로젝트별로 더 구체적인 제약(예: 특정 엔진의 순수 시간함수 원칙, 색보간 규칙)이 있으면
그 프로젝트 문서가 이 스킬보다 우선한다 — 이 스킬은 범용 워크플로우일 뿐 프로젝트 규칙을 대체하지 않는다.

---

## 누적 학습 메모

### 검증된 패턴
- (아직 없음 — 실사용 로그 3건 누적 시 리뷰, `docs/PROMOTION-RULES.md` 참조)

### 발견된 한계
- (아직 없음)

### 미검증 / 추후 테스트
- Farneback vs RAFT 실질 정확도 차이가 이 정도 용도(레퍼런스 모션 특성 파악)에서 유의미한지
- `video_analysis_create`의 씬 분석 결과 포맷과 optical flow 수치를 같은 리포트에 병합하는 표준 양식

---

## 참조
- [Meta CoTracker](https://github.com/facebookresearch/co-tracker)
- [RAFT (optical flow)](https://github.com/princeton-vl/RAFT)
- [PySceneDetect docs](https://www.scenedetect.com/)
