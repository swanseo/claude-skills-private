# 손 이상함 + 얼굴이 프롬프트와 다른 문제 해결 가이드

현재 워크플로우: VNCCS_PoseStudio → DWPose → ControlNet OpenPose (strength 0.8) → KSampler (CFG 7.0, steps 25) → juggernautXL

---

## 문제 1: 손이 이상하게 나왔을 때

### 원인
- OpenPose ControlNet은 손가락 세부 구조를 잘 잡지 못함 (손목 관절만 검출, 개별 손가락 keypoint는 부정확)
- DWPreprocessor의 resolution이 512로 설정되어 있어 손 영역 디테일 손실 가능
- ControlNet strength가 0.8이면 포즈는 잘 따르지만, 손은 여전히 모델 자체가 재해석함

### 해결 방법

#### 방법 A: 네거티브 프롬프트 강화 (즉시 적용 가능)
현재 네거티브 프롬프트에 이미 `mutated hands`가 있음. 다음을 추가:
```
bad hands, extra fingers, missing fingers, fused fingers, too many fingers, poorly drawn hands, deformed hands, malformed limbs
```

#### 방법 B: ADetailer 또는 Inpaint로 손 후처리
1. 생성된 이미지에서 손 영역만 마스크
2. KSampler 앞에 VAEEncodeForInpaint 연결
3. denoise를 0.5~0.7로 낮춰서 손 부분만 재생성

#### 방법 C: DWPose resolution 올리기
- DWPreprocessor 노드의 resolution을 512 → 1024로 변경
- 손 keypoint 검출 정확도 향상

#### 방법 D: ControlNet에 손 전용 추가
- OpenPose ControlNet 외에 `depth` 또는 `tile` ControlNet을 손 영역에만 적용

---

## 문제 2: 캐릭터 얼굴이 프롬프트와 다를 때

### 원인
- 현재 Positive Prompt: `anime illustration, 1girl, full body, detailed character design, high quality, masterpiece, best quality`
- 얼굴 특징 묘사가 전혀 없음 (눈 색, 머리 색, 표정, 나이 등 미지정)
- OpenPose ControlNet은 얼굴 방향/위치는 잡지만 얼굴 외모는 모델이 자유롭게 생성
- CFG Scale 7.0 → 프롬프트 준수도가 낮지 않지만, 캐릭터 외모 묘사가 없으면 효과 없음

### 해결 방법

#### 방법 A: 프롬프트에 얼굴 특징 명시 (핵심)
Positive Prompt 노드에 원하는 얼굴 특징을 구체적으로 추가:
```
anime illustration, 1girl, full body, detailed character design,
[머리 색]hair, [눈 색]eyes, [표정], [나이대],
high quality, masterpiece, best quality
```
예시:
```
anime illustration, 1girl, full body, detailed character design,
long blonde hair, blue eyes, smiling, 18 years old,
high quality, masterpiece, best quality
```

#### 방법 B: CFG Scale 높이기
- KSampler의 CFG Scale: 7.0 → 8.0~10.0으로 증가
- 프롬프트 지시를 더 강하게 따름
- 너무 높으면(>12) 아티팩트 발생 주의

#### 방법 C: FaceDetailer / ADetailer 추가
- 얼굴 영역만 별도로 재생성하는 노드 추가
- ComfyUI에서는 `FaceDetailer` (Impact Pack) 사용
- 얼굴 전용 프롬프트로 세밀한 제어 가능

#### 방법 D: IP-Adapter로 얼굴 레퍼런스 지정
- 원하는 캐릭터 얼굴 이미지를 IP-Adapter Face ID에 연결
- 프롬프트만으로 얼굴 특징을 제어하는 것보다 훨씬 정확

#### 방법 E: ControlNet OpenPose의 strength 조정
- 현재 strength: 0.8
- 얼굴 표현이 너무 포즈에 제약받는다면 end_percent를 0.7로 낮추기
  (현재 start: 0.0, end: 1.0)
- ControlNetApplyAdvanced에서 `end_percent`를 0.7~0.8로 변경

---

## 현재 워크플로우 설정 요약

| 노드 | 현재 설정 | 권장 변경 |
|------|-----------|-----------|
| DWPreprocessor resolution | 512 | 1024 (손 디테일) |
| ControlNet strength | 0.8 | 0.7~0.85 유지 |
| ControlNet end_percent | 1.0 | 0.7~0.8 (얼굴 자유도 증가) |
| KSampler CFG | 7.0 | 8.0~9.0 |
| KSampler steps | 25 | 25~30 유지 |
| Positive Prompt | 얼굴 특징 없음 | 구체적 얼굴 묘사 추가 |
| Negative Prompt | 기본적 bad hands 있음 | 손 관련 네거티브 강화 |

---

## 우선순위 권장 액션

1. **즉시**: Positive Prompt에 원하는 얼굴 특징 (머리 색, 눈 색, 표정) 명시
2. **즉시**: Negative Prompt에 손 관련 키워드 추가
3. **설정 변경**: DWPreprocessor resolution을 1024로 올리기
4. **선택적**: CFG Scale을 7.0 → 8.5로 올리기
5. **고급**: FaceDetailer 또는 IP-Adapter Face 추가 (더 정확한 얼굴 제어)
