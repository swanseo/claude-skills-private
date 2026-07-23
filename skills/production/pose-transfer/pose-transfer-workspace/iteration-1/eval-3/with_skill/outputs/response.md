# 손 이상 + 얼굴 불일치 문제 해결 가이드

포즈는 정확하게 나왔지만 손과 얼굴에 문제가 있는 상황이다. 두 가지 문제를 각각 분리해서 해결하면 된다.

---

## 문제 1: 손이 이상하게 나옴

### 원인

DWPose(OpenPose 스켈레톤 추출기)는 손가락의 세밀한 관절을 잘 인식하지 못한다. 3D 마네킹에서 `hand_l/r` 본의 방향이 어색하게 설정되면, DWPose가 손 키포인트를 잘못 추출하고, ControlNet이 그 오류를 그대로 이미지에 반영한다.

### 해결 방법 A: hand 본 수동 조정 (근본 해결)

VNCCS_PoseStudio에서 손목/손 본을 직접 조정한다.

**조정할 본:**
- `hand_l` — 왼손 방향
- `hand_r` — 오른손 방향
- `lowerarm_l/r` — 아래팔 (손목 방향에 영향)

**조정 방향 [X(전후), Y(좌우 틀기), Z(들어올리기)]:**

손이 자연스럽게 내려진 기본 자세 기준:
```json
"hand_l": [0, 0, 0],
"hand_r": [0, 0, 0]
```

손바닥이 앞을 향하게 (일반적으로 가장 안정적):
```json
"hand_l": [-10, 0, 0],
"hand_r": [-10, 0, 0]
```

손이 몸 옆에 자연스럽게 위치하는 경우:
```json
"lowerarm_l": [0, -15, 0],
"lowerarm_r": [0, 15, 0],
"hand_l": [-5, -10, 0],
"hand_r": [-5, 10, 0]
```

**핵심 원칙:** 손목이 꺾이거나 비틀린 각도를 피하고, `lowerarm`과 `hand` 본의 방향이 자연스럽게 이어지도록 맞춘다.

### 해결 방법 B: 부정 프롬프트 강화

프롬프트 수정으로 손 오류를 억제한다.

**워크플로우 JSON 수정 위치:**
- 노드 ID 7 (`title: "Negative Prompt"`) → `widgets_values[0]`

**강화된 부정 프롬프트:**
```
bad anatomy, extra limbs, mutated hands, poorly drawn hands,
extra fingers, missing fingers, fused fingers, too many fingers,
malformed hands, deformed hands, blurry hands,
low quality, ugly, worst quality, text, watermark
```

### 해결 방법 C: ControlNet 강도 구간 조정

손 부분만 ControlNet 영향을 약하게 줘서 모델이 자체적으로 손을 더 자연스럽게 그리도록 유도한다.

**워크플로우 JSON 수정 위치:**
- 노드 ID 9 (`ControlNetApplyAdvanced`) → `start_percent`, `end_percent` 파라미터

현재 기본값이 `0.0 ~ 1.0` (전 구간 적용)이라면:
```
start_percent: 0.0
end_percent: 0.85
```
마지막 15% 구간에서 ControlNet을 끄면 모델이 손 디테일을 자체 판단으로 마무리한다.

**또는 강도 자체를 소폭 낮춤:**
```
ControlNet 강도: 0.8 → 0.75
```

---

## 문제 2: 캐릭터 얼굴이 프롬프트와 다름

### 원인

SDXL은 ControlNet OpenPose의 포즈 신호를 우선 따르면서 프롬프트의 외모 묘사를 약하게 반영하는 경향이 있다. 특히 CFG Scale이 낮거나 프롬프트에 외모 묘사가 부족하면 모델이 기본 얼굴로 생성한다.

### 해결 방법 A: CFG Scale 높이기 (가장 빠른 효과)

**워크플로우 JSON 수정 위치:**
- 노드 ID 11 (`KSampler`) → `cfg` 값

```
현재 기본값: 7.0
권장 변경값: 8.0 ~ 9.0
```

CFG Scale을 높이면 모델이 프롬프트를 더 강하게 따른다. 단, 10 이상으로 올리면 색상이 과포화되거나 아티팩트가 생길 수 있으니 8~9 범위에서 테스트한다.

### 해결 방법 B: 긍정 프롬프트에 얼굴 묘사 강화

**워크플로우 JSON 수정 위치:**
- 노드 ID 6 (`title: "Positive Prompt"`) → `widgets_values[0]`
- 노드 ID 2 (VNCCS_PoseStudio) → `widgets_values[0]` 내 JSON의 `"user_prompt"` 필드

**수정 전 예시 (부족한 상태):**
```
1girl, brown hair, school uniform, full body, high quality
```

**수정 후 예시 (얼굴 묘사 강화):**
```
1girl, 18 years old, long brown wavy hair, large blue eyes,
sharp nose, small lips, pale skin, delicate facial features,
school uniform, full body, detailed face, beautiful face,
high quality, masterpiece, best quality
```

**얼굴 관련 강화 태그 목록 (원하는 것 선택 추가):**
```
detailed face          → 얼굴 디테일 강화
beautiful face         → 전체적으로 아름다운 얼굴 유도
perfect face           → 얼굴 완성도 향상
sharp eyes             → 눈 선명하게
expressive eyes        → 눈 표현력 강화
realistic skin texture → 피부 질감 (사실적 스타일)
soft skin              → 부드러운 피부 (애니 스타일)
```

### 해결 방법 C: user_prompt 필드도 반드시 동기화

VNCCS_PoseStudio 노드 내부의 `user_prompt`와 노드 ID 6의 Positive Prompt가 **다른 내용**이면 충돌이 생긴다.

**확인 방법:**

`VNCCS_PoseStudio_Local_SDXL.json` 파일에서:
```json
// 노드 ID 2
"widgets_values": ["{... \"user_prompt\": \"여기 내용\", ...}"]

// 노드 ID 6
"widgets_values": ["여기 내용"]
```

두 곳의 캐릭터 묘사가 **일치**하도록 맞춰야 한다.

### 해결 방법 D: 스텝 수 높이기

얼굴 디테일은 스텝 수가 적으면 흐릿하게 나온다.

**워크플로우 JSON 수정 위치:**
- 노드 ID 11 (`KSampler`) → `steps` 값

```
현재 기본값: 25
권장 변경값: 30 ~ 35
```

---

## 두 문제를 동시에 적용할 때 권장 설정값 요약

| 항목 | 기존 값 | 변경 값 | 수정 위치 |
|------|---------|---------|-----------|
| CFG Scale | 7.0 | 8.5 | KSampler (ID:11) |
| 스텝 수 | 25 | 30 | KSampler (ID:11) |
| ControlNet 강도 | 0.8 | 0.75~0.8 유지 | ControlNetApplyAdvanced (ID:9) |
| ControlNet end_percent | 1.0 | 0.85 | ControlNetApplyAdvanced (ID:9) |
| 긍정 프롬프트 | 기본 | 얼굴 묘사 태그 추가 | 노드 ID 6 + ID 2 user_prompt |
| 부정 프롬프트 | 기본 | 손 관련 태그 추가 | 노드 ID 7 |

---

## 작업 순서 권장

1. `hand_l/r` 본을 VNCCS_PoseStudio에서 자연스러운 각도로 조정 (lowerarm과 방향 일치)
2. 부정 프롬프트에 손 오류 태그 추가
3. 긍정 프롬프트에 얼굴 묘사 상세 태그 추가
4. `user_prompt`와 노드 ID 6 프롬프트 동기화 확인
5. CFG Scale을 7.0 → 8.5로 변경
6. steps를 25 → 30으로 변경
7. ControlNet `end_percent`를 1.0 → 0.85로 변경
8. 생성 실행 후 결과 확인

포즈가 이미 맞으니 ControlNet 강도(0.8)는 크게 건드리지 않아도 된다. 손과 얼굴만 집중적으로 수정하는 것이 포즈 유지에 유리하다.
