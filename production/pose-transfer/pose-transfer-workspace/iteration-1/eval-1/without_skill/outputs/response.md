# 발레 댄서 포즈를 애니메이션 캐릭터에 적용하는 방법

## 개요

ComfyUI에서 VNCCS_PoseStudio + DWPose + ControlNet OpenPose 조합을 사용하여 발레 포즈 레퍼런스를 파란 드레스를 입은 20대 여성 애니메이션 캐릭터에 적용하는 과정입니다.

워크플로우 파일: `E:\AI-work\pose-studio\VNCCS_PoseStudio_Local_SDXL.json`

---

## 전체 흐름 (워크플로우 3단계 구조)

```
[① Pose Studio] → [② DWPose] → [③ SDXL + ControlNet]
  3D 마네킹 편집     OpenPose 추출    이미지 생성
```

---

## 단계별 상세 안내

### 단계 1: 워크플로우 열기

1. ComfyUI를 실행합니다.
2. `Load` 버튼 클릭 → `E:\AI-work\pose-studio\VNCCS_PoseStudio_Local_SDXL.json` 파일을 불러옵니다.
3. 세 개의 그룹(파란/보라/초록 영역)이 보이면 정상입니다.

---

### 단계 2: 포즈 레퍼런스 입력 (두 가지 방법 중 선택)

#### 방법 A: 레퍼런스 이미지에서 포즈 자동 추출 (권장)

워크플로우 좌측 상단에 **"Pose Capture (Reference)"** 라는 LoadImage 노드가 있습니다 (Node ID: 1). 이 노드는 기본적으로 비활성화(mode: 4) 상태입니다.

1. **LoadImage 노드를 활성화**합니다: 노드를 우클릭 → "Enable" 선택
2. 발레 댄서 레퍼런스 이미지를 이 노드에 로드합니다.
3. 이 노드의 출력(IMAGE)을 **VNCCS_PoseStudio 노드의 `pose_image` 입력**에 연결합니다.
   - VNCCS_PoseStudio 노드의 `pose_image` 입력 슬롯이 현재 연결되어 있지 않으므로(`link: null`) 드래그하여 연결하면 됩니다.
4. PoseStudio가 레퍼런스 이미지의 포즈를 자동으로 3D 마네킹에 매핑합니다.

> **주의**: 노드 제목에 "disconnect to avoid SAM3D download"라고 적혀 있습니다. SAM3D 모델이 없다면 연결 전에 해당 모델을 먼저 다운로드하거나, 방법 B를 사용하세요.

#### 방법 B: VNCCS_PoseStudio에서 직접 포즈 수동 편집

1. **VNCCS_PoseStudio 노드** (Node ID: 2)를 더블클릭하거나 "Open in Editor" 버튼을 클릭합니다.
2. 3D 마네킹 편집 UI가 열립니다.
3. 발레 댄서 포즈(한쪽 다리를 높이 들어올리고 팔을 벌린 포즈)에 맞게 bone을 조정합니다:
   - **다리 올리기**: `thigh_l` 또는 `thigh_r` → 전방/측방으로 크게 회전 (X축 -90도 이상)
   - **무릎 펴기**: `calf_l` 또는 `calf_r` → 0도 유지 (발레는 다리를 곧게 폄)
   - **팔 벌리기**: `upperarm_l`, `upperarm_r` → 양쪽으로 수평 방향 (Z축 ±90도)
   - **팔꿈치**: `lowerarm_l`, `lowerarm_r` → 약간 굽히거나 펴기
   - **척추**: `spine_01`, `spine_02`, `spine_03` → 발레 특유의 직립 자세 유지
4. 조정 완료 후 저장합니다.

---

### 단계 3: DWPose로 OpenPose 스켈레톤 추출 확인

- **DWPreprocessor 노드** (Node ID: 3)가 PoseStudio 출력을 받아 OpenPose 스켈레톤으로 변환합니다.
- **PreviewImage 노드** (Node ID: 4, "Pose Preview")에서 추출된 스켈레톤 이미지를 확인합니다.
- 발레 포즈가 올바르게 인식되었는지 확인하세요 (한쪽 다리 높이 들어올림, 양팔 벌림).

---

### 단계 4: SDXL 생성 설정

#### 4-1. 체크포인트 확인

**CheckpointLoaderSimple 노드** (Node ID: 5)에 현재 `juggernautXL_juggXIByRundiffusion.safetensors`가 설정되어 있습니다. 애니메이션 스타일을 원한다면 애니메이션 특화 SDXL 모델로 변경을 권장합니다:
- 예: `animagineXL`, `bluePencilXL`, `kohakuXLbeta` 등

#### 4-2. 포지티브 프롬프트 수정

**Positive Prompt 노드** (Node ID: 6)를 다음과 같이 수정합니다:

```
anime illustration, 1girl, 20s, full body, blue dress, ballet pose, one leg raised high, arms spread wide, elegant dancer, detailed character design, high quality, masterpiece, best quality
```

주요 추가 키워드:
- `1girl, 20s` — 20대 여성
- `blue dress` — 파란 드레스
- `ballet pose, one leg raised high, arms spread wide` — 포즈 묘사
- `elegant dancer` — 발레 분위기 강화
- `anime illustration` — 애니메이션 스타일

#### 4-3. 네거티브 프롬프트 확인

**Negative Prompt 노드** (Node ID: 7) 현재 설정:
```
bad anatomy, extra limbs, mutated hands, poorly drawn, blurry, low quality, ugly, worst quality, text, watermark
```
이 그대로 유지하거나 `deformed legs, wrong pose` 등을 추가해도 좋습니다.

#### 4-4. ControlNet 강도 설정

**ControlNetApplyAdvanced 노드** (Node ID: 9) 현재 설정:
- strength: `0.8` — 포즈 준수 강도 (0.7~0.9 권장)
- start: `0.0`, end: `1.0`

발레 포즈처럼 복잡한 포즈는 `0.8~0.85`로 유지하는 것이 좋습니다. 너무 높으면(1.0) 이미지 품질이 저하될 수 있습니다.

#### 4-5. 이미지 크기

**EmptyLatentImage 노드** (Node ID: 10): 현재 `1024x1024`
- 전신 포즈이므로 세로 비율을 권장: `768x1216` 또는 `832x1216`으로 변경

#### 4-6. KSampler 설정

**KSampler 노드** (Node ID: 11) 현재 설정:
- steps: `25`, cfg: `7.0`, sampler: `dpmpp_2m`, scheduler: `karras`
- 이 설정은 적절합니다. 필요시 cfg를 `6.5~7.5` 범위에서 조정.

---

### 단계 5: 생성 실행

1. 모든 설정 완료 후 **Queue Prompt** 버튼을 클릭합니다.
2. 생성된 이미지는 **SaveImage 노드** (Node ID: 13)를 통해 `PoseStudio_SDXL_XXXXXX.png` 파일명으로 저장됩니다.
3. **Lighting Prompt 노드** (Node ID: 14)에서 PoseStudio가 자동 생성한 조명 프롬프트도 참고할 수 있습니다.

---

## 요약 체크리스트

- [ ] LoadImage 노드에 발레 댄서 레퍼런스 이미지 로드 후 PoseStudio에 연결 (방법 A), 또는 PoseStudio에서 직접 포즈 편집 (방법 B)
- [ ] Pose Preview 노드에서 스켈레톤 확인
- [ ] Positive Prompt에 `1girl, 20s, blue dress, ballet pose, one leg raised high, arms spread wide, anime illustration` 추가
- [ ] 애니메이션 특화 SDXL 모델로 체크포인트 변경 (선택)
- [ ] 이미지 크기를 세로 비율로 변경 (768x1216 권장)
- [ ] ControlNet strength 0.8 유지
- [ ] Queue Prompt 실행

---

## 팁

- 포즈가 정확히 안 나온다면 DWPose Preview를 확인하고 PoseStudio에서 bone을 다시 조정하세요.
- 애니메이션 스타일이 약하다면 모델을 애니메이션 특화 SDXL로 교체하거나 `LoRA`를 추가하세요.
- 파란 드레스 색상이 잘 표현되지 않으면 `royal blue dress`, `sapphire blue dress` 등 더 구체적인 색상 표현을 사용하세요.
