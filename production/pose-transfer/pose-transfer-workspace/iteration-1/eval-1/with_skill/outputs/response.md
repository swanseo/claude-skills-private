# 발레 댄서 포즈 전이 가이드: 파란 드레스 애니메이션 캐릭터 (SDXL)

**워크플로우:** `VNCCS_PoseStudio_Local_SDXL.json`
**프로젝트 경로:** `E:\AI-work\pose-studio\`

---

## Step 1: 포즈 레퍼런스 이미지 분석

실제 이미지가 없으므로, "발레 댄서가 한쪽 다리를 높이 들어올리고 팔을 벌린 포즈"를 기반으로 분석한다.

### 예상 포즈 요약

> 오른쪽 다리(또는 왼쪽 다리)를 90도 이상 옆으로 높이 들어올린 자세 (아라베스크 또는 그랑 바트망 변형).  
> 양팔을 좌우로 크게 벌려 수평에 가깝게 펼친 상태.  
> 척추는 곧게 세우거나 살짝 뒤로 젖힌 형태 (발레 특유의 에레크트 자세).  
> 골반은 들어올린 다리 방향으로 약간 기울어짐.  
> 카메라 앵글: 정면 또는 살짝 3/4뷰.  
> 머리는 정면을 향하거나 팔 방향을 따라 약간 측면을 바라봄.

### VNCCS_PoseStudio 재현 시 주의점

- 다리를 90도 이상 들어올리는 경우 `thigh_l` 또는 `thigh_r` 본의 Z축을 극단적으로 조정해야 하며, 골반(`pelvis`)이 연동하여 기울어진다.
- 팔을 좌우로 완전히 펼친 동작은 DWPose가 비교적 잘 인식하므로 ControlNet 효과가 잘 나타난다.
- 발레 포즈 특유의 발끝(포인트 발) 동작은 `foot_l/r` 본을 Z축으로 조정해야 하며, DWPose가 발끝 세부를 못 잡을 수 있으니 프롬프트 보완이 필요하다.
- 들어올린 다리가 카메라 방향으로 심한 원근감(foreshortening)을 만들지 않도록, 카메라를 정면(`cam_yaw_deg: 0`)으로 유지하는 것을 권장한다.

---

## Step 2: VNCCS_PoseStudio 본(Bone) 조정 권장값

아래는 "오른쪽 다리를 높이 들어 좌측으로 뻗고, 양팔을 좌우로 벌린 발레 포즈" 기준의 본 조정값이다.  
각도는 **[X(전후 기울기), Y(좌우 비틀기), Z(들어올리기/내리기)]** 형태.

```json
{
  "pelvis":       [5,  0,  12],
  "spine_01":     [5,  0,   0],
  "spine_02":     [5,  0,   0],
  "spine_03":    [-5,  0,   0],
  "neck_01":      [0,  0,   0],
  "head":         [0,  5,   0],

  "clavicle_l":   [0,  0,  10],
  "clavicle_r":   [0,  0, -10],
  "upperarm_l":   [0,  0,  80],
  "upperarm_r":   [0,  0, -80],
  "lowerarm_l":  [-10, 0,  10],
  "lowerarm_r":  [-10, 0, -10],
  "hand_l":       [0,  0,  10],
  "hand_r":       [0,  0, -10],

  "thigh_l":      [0,  0,  15],
  "thigh_r":      [0,  0,  95],
  "calf_l":       [5,  0,   0],
  "calf_r":      [-5,  0,   0],
  "foot_l":     [-30,  0,   0],
  "foot_r":     [-30,  0,   0]
}
```

### 조정 포인트 설명

| 본 | 조정 설명 |
|----|-----------|
| `pelvis` | 오른쪽 다리가 올라가므로 골반이 우측으로 약 12도 기울어짐 |
| `spine_01/02` | 발레 특유의 가슴을 살짝 앞으로 내민 자세 (5도 전방 기울기) |
| `spine_03` | 흉추 상부는 역방향으로 미세 조정해 에레크트 자세 유지 |
| `upperarm_l/r` | 양팔을 좌우로 80도 들어올려 수평에 가깝게 벌림 |
| `thigh_r` | 오른쪽 다리를 옆으로 95도 들어올림 (그랑 바트망 아 라 스콩드) |
| `thigh_l` | 왼쪽 지지 다리는 약간 바깥쪽 턴아웃 (15도) |
| `foot_l/r` | 발끝 포인트를 위해 Z가 아닌 X축으로 -30도 (발등 펴기) |

> **팁:** 먼저 `thigh_r` Z축을 95로 설정한 뒤 골반(`pelvis`) Z축을 미세조정하면서 자연스러운 균형을 찾아라. 마네킹이 넘어지는 느낌이 들면 `pelvis` X축을 앞으로 조금 더 올려라.

---

## Step 3: 포즈 캡처 방법 (레퍼런스 이미지 활용)

실제 발레 댄서 레퍼런스 이미지가 있는 경우:

1. 이미지를 `E:\AI-work\ComfyUI\input\` 폴더에 복사한다.
2. `VNCCS_PoseStudio_Local_SDXL.json`에서 **노드 ID 1** (LoadImage, title: "Pose Capture (Reference)")의 `mode`를 `4`에서 `0`으로 변경한다.
3. `widgets_values[0]`에 파일명을 입력한다 (예: `"ballet_reference.png"`).
4. VNCCS_PoseStudio 노드(ID 2)의 `pose_image` 입력 슬롯에 노드 1의 IMAGE 출력을 연결한다.
5. 워크플로우를 실행하면 3D 마네킹이 레퍼런스 포즈를 자동 근사한다.

> **주의:** 레퍼런스 이미지를 연결하면 SAM3D 모델이 다운로드될 수 있다 (수 GB).  
> 수동 본 조정만으로도 충분하다면 노드 1을 `mode: 4` (비활성)로 두고 Step 2의 본 값을 직접 입력하는 방식을 권장한다.

---

## Step 4: SDXL 캐릭터 프롬프트

### 긍정 프롬프트 (노드 ID 6, `widgets_values[0]`)

```
anime illustration, 1girl, 20s, slender figure, long hair, blue eyes,
beautiful face, elegant expression,
blue dress, flowing blue dress, elegant ballgown, light blue fabric,
ballet pose, one leg raised high, arms spread wide, dynamic pose, full body,
graceful, elegant, ballet dancer,
high quality, masterpiece, best quality, highly detailed, 8k,
soft lighting, studio background
```

### 부정 프롬프트 (노드 ID 7, `widgets_values[0]`)

```
bad anatomy, extra limbs, mutated hands, poorly drawn hands, deformed legs,
blurry, low quality, ugly, worst quality, text, watermark,
bad proportions, missing limbs, floating limbs, disconnected limbs,
extra fingers, fused fingers, too many fingers, long neck
```

### VNCCS_PoseStudio user_prompt 필드 (노드 ID 2, JSON 내부)

노드 2의 `widgets_values[0]` JSON에서 `"user_prompt"` 필드를 다음으로 수정:

```json
"user_prompt": "anime illustration, 1girl, 20s, blue dress, elegant, ballet pose, full body, high quality"
```

---

## Step 5: 워크플로우 설정 조정

### 이미지 크기 (노드 ID 10 - EmptyLatentImage)

발레 전신 포즈이므로 세로형을 권장:

```json
"widgets_values": [768, 1024, 1]
```

(기본값 1024×1024에서 768×1024로 변경)

### ControlNet 강도 (노드 ID 9 - ControlNetApplyAdvanced)

발레 포즈의 정확도가 중요하므로 강도를 높임:

```json
"widgets_values": [0.9, 0.0, 1.0]
```

| 파라미터 | 값 | 의미 |
|----------|----|------|
| strength | 0.9 | 포즈 충실도 높음 (기본 0.8에서 상향) |
| start_percent | 0.0 | 처음부터 ControlNet 적용 |
| end_percent | 1.0 | 끝까지 ControlNet 적용 |

### KSampler 설정 (노드 ID 11)

애니메이션 캐릭터 품질을 위해 스텝 수 상향:

```json
"widgets_values": [42, "randomize", 30, 7.5, "dpmpp_2m", "karras", 1.0]
```

| 파라미터 | 변경값 | 이유 |
|----------|--------|------|
| steps | 30 (기본 25) | 디테일 향상 |
| cfg | 7.5 (기본 7.0) | 프롬프트 충실도 소폭 증가 |

### ControlNet 모델 (노드 ID 8)

현재 설정: `controlnet-openpose-sdxl.safetensors` — SDXL용 OpenPose이므로 그대로 사용.

---

## Step 6: 단계별 워크플로우 실행 가이드

### 전체 순서

```
1. ComfyUI 실행
       ↓
2. VNCCS_PoseStudio_Local_SDXL.json 로드
       ↓
3. [노드 2] VNCCS_PoseStudio에서 본 조정
   - Step 2의 bone 값을 JSON 에디터에 직접 입력
   - 또는 3D 뷰포트에서 마우스로 드래그 조작
       ↓
4. [노드 6] Positive Prompt 수정 (Step 4 프롬프트 붙여넣기)
       ↓
5. [노드 7] Negative Prompt 확인 (기본값 유지 또는 Step 4 값 사용)
       ↓
6. [노드 10] 이미지 크기를 768×1024로 변경
       ↓
7. [노드 9] ControlNet 강도를 0.9로 설정
       ↓
8. [노드 11] Steps를 30으로 변경
       ↓
9. Queue Prompt 실행
       ↓
10. [노드 4] Pose Preview에서 OpenPose 스켈레톤 확인
    - 다리가 높이 들린 형태가 스켈레톤에 반영되었는지 확인
       ↓
11. [노드 13] SaveImage에서 최종 결과 확인
```

### ComfyUI에서 노드 2 bone 값 수정 방법

1. VNCCS_PoseStudio 노드(ID 2)를 더블클릭하거나 우클릭 → "Edit"
2. 3D 뷰포트가 열리면 우측 패널에서 각 bone을 선택
3. X/Y/Z 슬라이더를 Step 2의 값으로 조정
4. 또는 노드의 `widgets_values[0]` JSON 문자열을 직접 편집하여 `"bones"` 객체 안에 Step 2의 값을 입력

---

## Step 7: 결과 확인 및 트러블슈팅

### 예상 문제와 해결

| 증상 | 원인 | 해결 방법 |
|------|------|-----------|
| 포즈가 레퍼런스와 다름 | ControlNet 강도 부족 | 노드 9에서 0.9 → 1.0으로 상향 |
| 다리가 자연스럽게 안 올라감 | `thigh_r` 각도 부족 | Z축 95 → 100~110으로 높임 |
| 드레스가 파랗지 않음 | 프롬프트 가중치 낮음 | `(blue dress:1.4)` 형태로 강조 |
| 애니메이션 스타일이 약함 | 모델 특성 | juggernautXL 대신 AnimeXL 계열 체크포인트로 교체 |
| 손이 이상하게 표현됨 | DWPose 손 인식 한계 | `hand_l/r` 본 수동 미세조정, 프롬프트에 `detailed hands` 추가 |
| 발끝(포인트) 표현 안 됨 | DWPose 발 인식 한계 | 프롬프트에 `ballet shoes, pointed toes` 추가 |
| 전신이 잘림 | 캔버스 크기 부족 | 768×1024로 설정 확인, 또는 VNCCS_PoseStudio의 `cam_zoom`을 1.2로 줄임 |

### 반복 개선 흐름

```
첫 번째 결과 확인
    ↓
포즈 정확도 문제? → ControlNet 강도 상향 (0.9→1.0)
캐릭터 외모 문제? → 프롬프트에 외모 묘사 추가
품질 문제? → Steps 증가 (30→35), CFG 조정
    ↓
Seed 고정 후 한 변수씩 조정
    ↓
원하는 결과 달성 → Seed 기록 보관
```

---

## 빠른 참조 요약

| 항목 | 설정값 |
|------|--------|
| 워크플로우 파일 | `VNCCS_PoseStudio_Local_SDXL.json` |
| 모델 | `juggernautXL_juggXIByRundiffusion.safetensors` |
| ControlNet 모델 | `controlnet-openpose-sdxl.safetensors` |
| 이미지 크기 | 768 × 1024 |
| ControlNet 강도 | 0.9 |
| Steps | 30 |
| CFG Scale | 7.5 |
| Sampler | dpmpp_2m / karras |
| 핵심 bone 조정 | `thigh_r Z: 95`, `upperarm_l Z: 80`, `upperarm_r Z: -80` |
