---
name: pose-transfer
description: >
  ComfyUI Pose Studio 워크플로우 전문 가이드 스킬. 포즈 레퍼런스 이미지의 포즈를
  원하는 인물 이미지에 적용하고, 포즈를 수정하여 이미지를 생성하는 전체 과정을 안내한다.
  다음 상황에서 반드시 이 스킬을 사용하라:
  - 사용자가 포즈 전이(pose transfer), 포즈 적용, 레퍼런스 포즈 복사를 언급할 때
  - VNCCS_PoseStudio, DWPose, ControlNet OpenPose 관련 작업을 할 때
  - "이 포즈를 저 캐릭터에 적용해줘", "포즈 레퍼런스 이미지 분석", "bone 조정" 같은 요청이 올 때
  - ComfyUI 포즈 워크플로우 설정이나 프롬프트 조언이 필요할 때
  - 포즈를 수정하고 이미지를 생성하고 싶다는 말이 나올 때
---

# Pose Transfer Skill

이 스킬은 ComfyUI의 VNCCS_PoseStudio 기반 포즈 전이 워크플로우를 처음부터 끝까지 안내한다.
사용자가 포즈 레퍼런스와 캐릭터 설명을 주면, 포즈 분석 → 본(bone) 조정 조언 → 프롬프트 작성
→ 워크플로우 설정 → 생성 결과 확인까지 함께 진행한다.

---

## 워크플로우 구조 (참고)

프로젝트 경로: `e:\AI-work\pose-studio\`

**워크플로우 선택 기준:**

| 파일 | 모델 | 적합한 상황 |
|------|------|-------------|
| `VNCCS_PoseStudio_Local_SDXL.json` | juggernautXL (SDXL) | 빠른 로컬 생성, 사실적 스타일 |
| `VNCCS_PoseStudio_RunComfy_Klein9b.json` | Klein 9b | 높은 품질, 복잡한 파이프라인 |

**파이프라인 3단계:**
1. **VNCCS_PoseStudio** — 3D 마네킹에서 포즈 생성 (본 20개 + 신체 비율 조정)
2. **DWPreprocessor** — OpenPose 스켈레톤 추출
3. **SDXL + ControlNet OpenPose** — 스켈레톤 기반 이미지 생성

---

## Step 1: 포즈 레퍼런스 이미지 분석

사용자가 포즈 레퍼런스 이미지를 제공하면:

1. **이미지를 시각적으로 분석**하여 다음을 파악하라:
   - 전체 자세 (서기/앉기/눕기/동적 동작)
   - 상체: 어깨 각도, 팔 위치 (위/옆/앞/뒤), 팔꿈치 굽힘 각도
   - 하체: 다리 벌림 정도, 무릎 굽힘, 발 방향
   - 척추: 곧음/앞숙임/뒤젖힘/측면 기울기
   - 골반 각도, 머리 방향
   - 카메라 앵글 (정면/측면/3/4뷰/위/아래)

2. **포즈 요약을 한국어로 간결하게 전달**하라. 예시:
   > "양팔을 머리 위로 들어올린 자세, 왼쪽으로 약간 기울어진 척추,
   > 오른쪽 무릎을 약 30도 굽힌 자세입니다. 카메라는 정면 45도 위에서 바라보는 앵글입니다."

3. **VNCCS_PoseStudio에서 재현 시 주의점**을 알려라:
   - 손가락 상세 동작은 DWPose가 잘 못 잡을 수 있음
   - 극단적 원근감(foreshortening)이 있으면 3D 마네킹과 차이가 날 수 있음
   - 얼굴 방향이 중요하다면 `head` 본 조정 필요

---

## Step 2: VNCCS_PoseStudio 본(Bone) 조정 가이드

포즈를 레퍼런스에서 3D 마네킹으로 옮길 때 어떤 본을 조정할지 안내하라.

### 본 이름과 역할

```
pelvis        → 골반 (전체 자세 기준점)
spine_01/02/03 → 척추 하/중/상 (굽힘/틀기)
neck_01       → 목
head          → 머리 방향

clavicle_l/r  → 왼/오른쪽 쇄골
upperarm_l/r  → 위팔 (어깨에서 팔꿈치)
lowerarm_l/r  → 아래팔 (팔꿈치에서 손목)
hand_l/r      → 손

thigh_l/r     → 허벅지
calf_l/r      → 종아리
foot_l/r      → 발
```

### 레퍼런스 이미지에서 본 값 추출하기

레퍼런스 이미지를 분석해서 각 본의 조정 방향을 **[X(전후), Y(좌우 틀기), Z(들어올리기)]** 형태로 제안하라.

예시 (두 팔을 들어올린 포즈):
```json
"upperarm_l": [-30, 0, 90],
"upperarm_r": [-30, 0, -90],
"lowerarm_l": [0, 0, 20],
"lowerarm_r": [0, 0, -20]
```

사용자가 직접 VNCCS_PoseStudio UI에서 조정할 수 있도록 어떤 본을 얼마나 움직여야 할지 **구체적인 방향과 대략적인 각도**를 알려라.

---

## Step 3: 포즈 레퍼런스 캡처 방법

ComfyUI에서 레퍼런스 이미지를 직접 포즈 캡처에 사용하는 방법:

1. 레퍼런스 이미지를 `ComfyUI/input/` 폴더에 복사
2. 워크플로우에서 **"Pose Capture (Reference)"** LoadImage 노드 활성화 (mode를 0으로 변경)
3. 이미지 파일 선택
4. VNCCS_PoseStudio의 `pose_image` 입력에 연결되어 있는지 확인
5. 워크플로우 실행 → 3D 마네킹이 레퍼런스 포즈를 자동으로 근사

> ⚠️ 주의: SAM3D 기능을 사용하면 대용량 모델 다운로드가 발생할 수 있음.
> 단순 포즈 참고만 원한다면 LoadImage 노드를 연결 해제하고 수동으로 본 조정을 권장.

---

## Step 4: 캐릭터 프롬프트 작성

사용자가 원하는 캐릭터 설명을 받아 SDXL에 맞는 프롬프트를 작성하라.

### 프롬프트 구조

```
[캐릭터 기본 정보], [외모 묘사], [의상], [스타일], [품질 태그]
```

**긍정 프롬프트 템플릿:**
```
1girl, [나이대], [헤어스타일 + 색상], [눈 색상], [의상 상세],
[스타일: anime/realistic/illustration], full body,
high quality, masterpiece, best quality, detailed
```

**부정 프롬프트 (기본값 유지 권장):**
```
bad anatomy, extra limbs, mutated hands, poorly drawn,
blurry, low quality, ugly, worst quality, text, watermark
```

### 워크플로우 JSON에서 프롬프트 수정 위치

`VNCCS_PoseStudio_Local_SDXL.json` 기준:
- **노드 ID 6** (`title: "Positive Prompt"`) → `widgets_values[0]` 수정
- **노드 ID 7** (`title: "Negative Prompt"`) → `widgets_values[0]` 수정
- **노드 ID 2** (VNCCS_PoseStudio) → `widgets_values[0]` 내 JSON의 `"user_prompt"` 필드 수정

---

## Step 5: 워크플로우 설정 조정

사용자 요청에 따라 다음 설정을 조정하도록 안내하거나 직접 JSON을 수정하라.

### 주요 설정값 (Local SDXL 기준)

| 설정 | 노드 | 기본값 | 조정 가이드 |
|------|------|--------|-------------|
| 이미지 크기 | EmptyLatentImage (ID:10) | 1024×1024 | 세로형: 768×1024, 가로형: 1024×768 |
| ControlNet 강도 | ControlNetApplyAdvanced (ID:9) | 0.8 | 포즈 충실도↑: 0.9-1.0 / 자유도↑: 0.5-0.7 |
| 스텝 수 | KSampler (ID:11) | 25 | 빠른 결과: 15-20 / 고품질: 30-35 |
| CFG Scale | KSampler (ID:11) | 7.0 | 프롬프트 충실도↑: 8-10 / 자유로운 해석: 5-6 |
| 모델 | CheckpointLoaderSimple (ID:5) | juggernautXL | 사용자 모델로 변경 가능 |

---

## Step 6: 결과 확인 및 피드백

생성 후 사용자와 함께 결과를 평가하라:

1. **포즈 정확도**: 레퍼런스와 포즈가 얼마나 일치하는가?
2. **캐릭터 충실도**: 원하는 캐릭터 외모가 잘 표현되었는가?
3. **품질**: 해부학적 오류, 손 표현, 전체 완성도

### 문제별 해결 방법

| 문제 | 원인 | 해결 |
|------|------|------|
| 포즈가 어색함 | ControlNet 강도 낮음 | 0.8→0.9로 높임 |
| 캐릭터가 다름 | 프롬프트 부족 | 더 구체적인 외모 묘사 추가 |
| 손이 이상함 | DWPose 손 인식 오류 | `hand_l/r` 본 수동 조정 |
| 포즈가 뭉개짐 | 스텝 수 부족 | 25→30으로 높임 |
| 특정 부위 안 맞음 | 3D 마네킹 비율 차이 | 해당 본 길이 파라미터 조정 |

---

## 전체 진행 흐름 요약

```
사용자 요청
    ↓
1. 포즈 레퍼런스 이미지 분석 (있을 경우)
    ↓
2. 포즈 설명 + 본 조정 값 제안
    ↓
3. 캐릭터 프롬프트 작성
    ↓
4. 워크플로우 선택 (SDXL / Klein9b)
    ↓
5. 설정 조정 (ControlNet 강도, 크기 등)
    ↓
6. ComfyUI 실행 → 결과 확인
    ↓
7. 피드백 반영 → 반복
```
