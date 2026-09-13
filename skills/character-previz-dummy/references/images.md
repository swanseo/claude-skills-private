# 단계 1~2: 바디 렌더와 이미지 생성

## 1. 바디 준비

1. `input/body fbx/<BODY>.*` 를 `out/<TAG>/<BODY>_body_src/` 로 복사 — **`.Fbx .fbxkey .json .fbm` + `input/body fbx/textures/<BODY>` → `<BODY>_body_src/textures/<BODY>`** (텍스처 폴더를 빠뜨리면 거칠기·AO·SSS 20개 "json image path not found"). 원본 json 을 CC/iC Tools 가 덮어쓰므로 복사본으로 임포트한다.
2. Blender (별도 호출 2번): `bpy.ops.wm.read_homefile(use_empty=True)` → 다음 호출에서 `bpy.ops.cc3.importer(filepath=r"...\<BODY>_body_src\<BODY>.Fbx", param="IMPORT", no_rigify=True)`
3. 키·주요 뼈 머리 출력(Hand·Forearm·Upperarm·Thigh·Calf·Foot·NeckTwist01·Head) → HANDOFF 기록. 이후 모든 Z·|X| 구간 상수의 기준.
4. `exec(pipeline/body_render_blender.py)` → `render_body(out_dir, TAG)` → 시스템 Python `python pipeline/body_patch.py out/<TAG> <TAG>`
5. `_body_front_safe.jpg` 를 Read 로 확인(가림판이 사타구니를 덮는지). 작업 blend 로 저장 `out/<TAG>/<TAG>_work.blend`.

시트 크롭: 원본 시트에서 앞·뒤 전신 패널을 원해상도로 잘라 `out/<TAG>/<TAG>_front.jpg`, `_back.jpg` (패널 x 범위는 시트를 보고 정한다. ALD 4096×2304: 앞 x1990~2950, 뒤 x3040~3990).

## 2. 생성 라우팅: 로컬 1차 → 유료 최종

| 단계 | 1차 (로컬, 무료) | 통과 조건 | 최종 (유료) |
|---|---|---|---|
| 2a 클레이 | Klein 4B 참조 편집, 시트 크롭 1장 | 소품 제거·구성 유지(체크리스트) | Kling 9:16, 같은 프롬프트 |
| 2b 앞면 | Klein 4B 참조 편집, 바디 safe + 클레이 2장 | `pose_gate` PASS, 구성 체크 | Kling 1:1 |
| 2c 뒷면 | 바디 뒤 + 합성 레퍼런스 | `pose_gate` + 앞면 반전 폭 | Kling 1:1 |
| 2d 마스크 | 슈트 이미지 1장 색칠 | IoU ≥0.97 | Kling 1:1 |

- Meshy 입력은 최종본(2k)만 쓴다. 로컬 결과가 이미 게이트·품질을 통과하고 해상도(≥1536, 인물 높이 ≥85%)도 충분하면 사용자에게 "유료 생략" 을 제안할 수 있다(사용자 결정).
- 유료 호출 전에 로컬 결과 이미지와 게이트 수치를 보여준다.

### 로컬 참조 편집 워크플로우 구축 (FDK 착수 첫 작업, 미검증)

현재 `Comfyui\tools\gen.py` 는 텍스트→이미지만 된다. 엔진에는 `flux-2-klein-4b.safetensors`, `qwen_3_4b.safetensors`(CLIPLoader type `flux2`), `flux2-vae.safetensors`, 노드 `ReferenceLatent`·`EmptyFlux2LatentImage`·`Flux2Scheduler` 가 있다.
1. comfy-mcp `search_templates` 로 FLUX.2 Klein 편집(참조 이미지) 공식 템플릿을 찾고 `get_template` — 손으로 그래프를 짜기 전에 템플릿부터
2. API 형식으로 `Comfyui\workflows\klein4b_edit_api.json` 저장 (LoadImage ×2 → VAEEncode → ReferenceLatent 체인)
3. `gen.py` 에 `--image PATH`(최대 2) 추가: `/upload/image` 로 올리고 LoadImage 노드에 파일명 주입. 기존 t2i 경로는 그대로
4. 검증: FDK 바디 safe + 클레이로 앞면 1장 → `pose_gate` 수치·렌더 확인 → 4070 12GB 소요 시간 기록
5. `Comfyui\CLAUDE.md` 모델 표와 이 절을 갱신(검증 결과·한계). 실패 시 정지 조건 — 사용자에게 Kling 직행 여부 확인
주의: Klein 은 하단에 가짜 로고·글자 띠를 넣는 경우가 있다 → 시드 변경. 장변 1536 이하. 네거티브 없음(cfg 1).

## 3. Kling 명령 (최종)

```bash
cd out/<TAG> && PROMPT='...' && kling image_to_image --model gemini-3-pro-image --img_resolution 2k --aspect_ratio 1:1 --image_count 1 \
  --skill-name kling-cli --skill-version 0.1.2 --poll 180 --image <TAG>_body_front_safe.jpg --image <TAG>_clay_front.jpg "$PROMPT" > kling_<step>.log 2>&1
URL=$(python -c "import re;t=open('kling_<step>.log',encoding='utf-8',errors='ignore').read();m=re.search(r'\"urlWithoutWatermark\": \"([^\"]+)\"',t);print(m.group(1) if m else '')")
curl -sL -o <TAG>_suit_front.png "$URL" && python -c "from PIL import Image;Image.open('<TAG>_suit_front.png').convert('RGB').save('<TAG>_suit_front.jpg',quality=92)"
```
- 입력 **최대 2장** (3장 → 400 `Duplicate input 'image_2'`, 과금 없음) → 뒷면 레퍼런스는 `make_ref_composite.py` 로 한 장.
- 클레이(시트 기반)는 `--aspect_ratio 9:16`, 바디 기반은 `1:1`. 1장 20 크레딧, 약 35~50초.

## 4. 프롬프트 템플릿 (원문 — `<>` 만 캐릭터에 맞게)

### 4.1 클레이 디자인 레퍼런스 (시트 크롭 1장) — ALD·MUM-A·WAR 검증
```
Convert this character into a clean 3D-scan reference image for photogrammetry.

Apply a uniform matte light-grey clay material to the ENTIRE figure - <모든 재질 나열: skin, cloth hood, plate armour, chainmail, leather gloves, belts, boots> - all the same neutral grey. No colour, no black, no metallic or glossy surfaces, no printed pattern. Flatten the COLOUR only - every sculpted form must survive: <형태 디테일 나열: layered shoulder plates with rivets, torn ragged cloth edges, strap and buckle ...>.

REMOVE completely: <무기·소품·긴 망토>. With <가리던 것> removed, rebuild what it was hiding so it matches the visible parts: <팔·다리·벨트 ...>. Both hands are empty and relaxed, hanging naturally at the sides with fingers slightly apart.

<머리: Simplify the face into a smooth blocked-in sculptor head, no tattoos, no skin detail. Keep the very short buzz-cut head shape.>
<후드: KEEP the loose cloth hood exactly as designed: large, standing away from the head, ragged torn edge, deep open front around the face. Inside the hood opening, replace the skull with a smooth simple blocked-in human face.>

Same standing pose, same proportions, full body front view, entire figure including both feet inside the frame, plain flat light-grey background, soft even lighting, no cast shadow, no text.
```
체크: 소품 제거, 가려졌던 부위 복원, 원본에 없는 요소 추가 없음, 망토 제거 시 드러나는 자락(ALD 옆 판) 확인.

### 4.2 슈트형 앞면 (image1 바디 safe, image2 클레이) — ALD v2 원문
```
Image 1 is a grey clay 3D body in an A-pose seen exactly from the front. Image 2 is a grey clay <역할> character - use it ONLY as the design reference for the outfit.

THE POSE AND SCALE OF IMAGE 1 ARE LOCKED:
- the legs stay exactly as close together as in image 1: the knees stay where they are, the feet stay where they are, the gap between the two feet stays narrow, toes point forward. Do NOT widen the stance. Do NOT spread the legs.
- the top of the head, the soles of the feet, the fingertips and the elbows stay at exactly the same pixel positions as image 1. The figure keeps the same size - do not enlarge it.
- the arms keep exactly the same angle, the bare hands keep the same finger positions.
- the same bald head and the same face. No hair.

Dress this body in the outfit from image 2, fitted TIGHTLY to the body of image 1 so the silhouette of the legs and arms barely changes:
- <위에서 아래로 항목. 붕대: thin bandage wraps tightly over ... (the bandages do NOT thicken the limbs); 장갑: long leather gloves from the elbows down to the WRISTS only; both hands stay completely bare; 부츠: SLIM fitted tall leather boots worn on the same feet in the same place>

NO <제외 목록>, no colour: uniform matte light-grey clay exactly like image 1. Full body orthographic front view, plain flat light-grey background like image 1, soft even lighting, no cast shadow, no text.
```
- 후드 캐릭터는 항목에 추가: `a loose cloth HOOD standing clearly away from the bald head, with a ragged torn front edge and a wide open front so the WHOLE face of image 1 stays completely visible (forehead, eyes, nose, mouth, chin not covered)` — MUM-A 는 그래도 후드가 머리에 밀착 생성됨(후처리 `radial_scale` 필요할 수 있음)
- 좌우 지정: `from the figure RIGHT shoulder (image LEFT) to the figure LEFT hip (image RIGHT)`
- ⚠ LOCKED 조항으로도 두꺼운 부츠·판갑은 바깥으로만 두꺼워짐(ALD: 안쪽 ±4px·중심 +60px, 3D 에선 실제 A자) → Blender 보정 전제

### 4.3 뒷면 (image1 바디 뒤, image2 합성 [앞면 | 시트 뒷면]) — ALD 원문
```
Image 1 is a grey clay 3D body seen exactly from behind. Keep image 1 exactly: the same A-pose, the same arm angles, the same bare hands and finger positions, the same bald head, the same figure position and size and margins. No hair.

Dress this body from behind in the same outfit shown in image 2. The LEFT half of image 2 is this same body already dressed, seen from the front - the back view must be its exact back side: the same leg width, the same boot size and the same boot positions (mirrored left-right for the back view), the same belt heights, the same tabard length, the same shoulder armour. The RIGHT half of image 2 is the original character sheet from behind - use it ONLY for <후드·칼라 등 뒷면에서만 보이는 것>.

Back view outfit:
- <뒷면 항목>

NO <제외>, no colour: uniform matte light-grey clay exactly like image 1. Full body orthographic back view, plain flat light-grey background like image 1, no shadow, no text.
```
원본 뒷면이 망토로 가려 몸 정보가 없으면 "앞면의 정확한 뒷면" 조항이 핵심(VAE·ALD).

### 4.4 맨살형 장비만 (WAR) — [재구성: 원문 미보존, HANDOFF ⑩ 조항으로 복원]
```
Image 1 is a grey clay 3D body in an A-pose seen exactly from the front. Image 2 is <캐릭터> in grey clay - use it ONLY as the design reference for the gear.
Keep image 1 EXACTLY: same pose, same proportions, same bare skin everywhere that is not covered by gear, same hands and feet positions (legs NOT spread), same size and margins.
ADD ONLY the gear from image 2, sculpted as raised grey clay pieces sitting on the skin: <장비 목록>. The figure's RIGHT shoulder is on the image LEFT.
The arms and legs between the gear pieces stay bare skin exactly as in image 1: no sleeves, no padding, no thickness added.
No <무기>, no colour, full body orthographic front view, plain flat light-grey background like image 1, no shadow, no text.
```
함정: 손 붕대를 빼라고 해도 원본 디자인대로 추가됨(WAR 수용 후 손목 절단).

### 4.5 장비 색칠 마스크 (맨살형, image1 = 장비 입힌 이미지) — [재구성]
```
Keep image 1 pixel-identical in shape: same silhouette, same pose, same framing. Recolour only:
every piece of gear (<목록>) solid flat pure red (#FF0000); all bare skin solid flat pure white; background unchanged.
No shading, no gradients, no outlines, no new shapes.
```
검증: 장비 이미지 실루엣과 IoU ≥0.97·윤곽 차 ≤2px (WAR 0.980/0.983). 라벨 npy 변환은 **시스템 Python**(Blender 에 PIL 없음).

## 5. 자세 게이트

```bash
python pipeline/pose_gate.py out/<TAG>/<TAG>_body_front.jpg out/<TAG>/<TAG>_suit_front.jpg
python pipeline/pose_gate.py out/<TAG>/<TAG>_body_back.jpg  out/<TAG>/<TAG>_suit_back.jpg
```
- PASS → Meshy. FAIL(안쪽 가장자리 벗어남) → 재생성. WARN(중심만) → 사용자에게 두 선택지(재생성 / Blender 보정 전제로 진행).
- 무릎 한 줄은 붕대 주름 그림자·자락 끝으로 덩어리가 쪼개진다 → 여러 높이로 판정(스크립트 기본).
- 뒷면은 앞면을 `--mirror` 로 뒷면과 대조해 다리 폭이 같은지도 본다(ALD ≤9px).
- 수치 통과 후에도 **이미지를 Read 로 열어** 구성(민머리·맨손·항목·제외물·글자 없음)을 확인한다.
