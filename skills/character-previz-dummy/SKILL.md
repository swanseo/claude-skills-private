---
name: character-previz-dummy
description: >
  캐릭터 시트(2D) → CC4 리깅 프리비즈 더미(AI 영상의 깊이·포즈 입력용) 파이프라인. 바디 렌더 → 이미지 생성(로컬 ComfyUI 1차 → Kling 나노바나나 최종)
  → Meshy 3D → Blender 정렬·보정·절단 → CC/iC Blender Tools 웨이트 → CC4 Cloth 지정·바디 숨김 → farm\assets 납품까지.
  다음 상황에서 반드시 사용: 캐릭터 시트로 3D 더미·프리비즈 캐릭터·CC4 캐릭터를 만들자고 할 때, "FDK/UKG 진행하자" 같은 남은 캐릭터 착수,
  갑옷·의상·장비를 CC4 바디에 입히는 작업, Meshy detail·CC/iC Blender Tools·Import Character From Blender·Cloth·Hide Body Mesh 얘기,
  슈트가 바디에서 뜨거나 바디가 뚫고 나올 때, 늘어남·찢김 게이트, 칼라·후드가 있는 머리 절단, 완성 더미를 production 으로 옮길 때.
---

# 캐릭터 프리비즈 더미 (CC4 리깅)

검증: 2026-09-13 VAE(판갑 슈트)·WAR(맨살+장비)·MUM-B(붕대 슈트)·MUM-A(붕대+후드)·ALD(판갑+칼라) 5종 완성, 사용자가 CC4 모션까지 확인.
원본 기록: `D:\Google\Works-Drive\Claude\image-to-3D\HANDOFF.md` ⑧~⑬ (수치·실패 이력 전부). 이 스킬은 거기서 확정된 절차만 뽑은 것이다.

## 경로

| 무엇 | 경로 |
|---|---|
| 작업 폴더 | `D:\Google\Works-Drive\Claude\image-to-3D` — 산출물은 **항상 `out/<TAG>/`**, `input/` 에는 쓰지 않는다 |
| 스크립트 | `image-to-3D\pipeline\` (README 참조), `meshy.py`, `blender_tail.py`, `blender_armor.py` |
| 시트 원본 | `input/<TAG>-sheet-*.png` (동일본: `production\farm\assets\_recalibrated\`) |
| 바디 원본 | 사용자가 CC4 → Plugins → Blender Pipeline → **Export Character to Blender** (fbxkey 포함) → `input/body fbx/<BODY>.*` + `textures/<BODY>` |
| 로컬 이미지 엔진 | ComfyUI `127.0.0.1:8188`, 규칙 `D:\Google\Works-Drive\Claude\Comfyui\CLAUDE.md`, 생성 `Comfyui\tools\gen.py` |
| 납품 | `D:\Google\Works-Drive\VAEL\production\farm\assets\<분류>\<캐릭터>\3D_Previz_Dummy_CC4\` ([delivery](references/delivery.md)) |
| 크레딧 | `kling account` (availableRemainCredits, 이미지 1장 20) / `python meshy.py balance` (detail 1회 35) |

비밀: Kling 은 `kling login` 으로만, `~/.kling/.credentials` 는 읽거나 출력하지 않는다. Meshy 키는 `.env` 의 `MESHY_API_KEY` — 노출 금지.

## 0. 착수 전 (건너뛰지 말 것)

1. **원본 시트를 원해상도로 확대해서 본다** (파생 이미지로 대체 금지). 머리·목·뒷면·손·발·소품을 목록으로 적는다.
2. 사용자에게 **하나씩** 확인한다 (CLAUDE.md ★변수 하나만):
   - 방식: **슈트형**(의상이 몸 전체를 대체, CC4 는 얼굴·손만 보임 — VAE·MUM·ALD) vs **맨살형**(CC4 바디가 보이고 장비만 — WAR)
   - 제외: 무기·방패·책·지팡이, **발목까지 긴 망토**(다리와 한 부피로 재구성돼 늘어남 → ALD 는 칼라만 남김)
   - 머리: 민머리(CC4 헤어) / 높은 칼라 / 후드 유지(얼굴만 개구부)
3. 판정 기준을 한 줄로 제안·동의: "CC4 에서 Cloth 로 불러와 모션을 따라가고, 얼굴·손만 CC4 바디로 보이며 (후드면) 고개 30°에서 머리가 안 뚫림"
4. 크레딧 확인. 캐릭터당 유료 기준 Kling 60(클레이 1 + 앞·뒤 2) + Meshy 35. 로컬 1차 생성으로 Kling 재시도분을 줄인다.

## 1. 단계

| # | 단계 | 도구 | 산출물 (`out/<TAG>/`) | 게이트 | 상세 |
|---|---|---|---|---|---|
| 1 | 바디 준비 | CC/iC Tools 임포트 → `body_render_blender.py` → `body_patch.py` | `_body_front/back(_safe)`, `_proj_cam.json`, `<BODY>_body_src\` | 렌더·패치 눈 확인 | [images](references/images.md) |
| 2a | 클레이 디자인 레퍼런스 | **로컬 1차** → Kling (시트 크롭 → 소품 제거 클레이) | `_clay_front` | 구성 체크리스트 | [images](references/images.md) |
| 2b | 의상 입힌 앞면 | **로컬 1차** → Kling (image1 바디 safe + image2 클레이) | `_suit_front` | `pose_gate.py` PASS (WARN 은 사용자 판단) | [images](references/images.md) |
| 2c | 뒷면 | `make_ref_composite.py` → 로컬 1차 → Kling (image1 바디 뒤 + image2 합성) | `_suit_back` | `pose_gate.py` + 앞면 반전과 폭 대조 | [images](references/images.md) |
| 2d | (맨살형) 장비 마스크 | 로컬 1차 → Kling (장비 빨강·맨살 흰색) | `_mask_front/back` | 장비 이미지 실루엣 IoU ≥0.97 | [images](references/images.md) |
| 3 | Meshy | `python meshy.py detail --name <TAG> --images front back --pose ""` | `_detail.glb/.fbx` | 약 5분, 35 크레딧 | [blender_fit](references/blender_fit.md) |
| 4 | 정렬·보정·절단 | `prep_body` → `align_skin_fit` → 진단 → 보정 → 절단 | `_work.blend` 의 `<TAG>_suit` | 옆면 겹침 렌더 + 레이 간격 + 모서리 비 | [blender_fit](references/blender_fit.md) |
| 5 | 리깅 | `rig_tools`: import(별도 호출) → append 게이트 → ADD_PBR·TRANSFER → fix_weights | `_CC4_rig.blend` | 미할당 0, 레스트 변화 0mm, 늘어남·고개 검사 | [rig_export](references/rig_export.md) |
| 6 | 내보내기 | `export_cc3` → `verify_export` | `_suit_export.fbx/.fbxkey/.json/.fbm/textures` | 텍스처 참조 전부 해석 | [rig_export](references/rig_export.md) |
| 7 | 사용자 CC4 | Import Character From Blender → **Cloth** → 바디 숨김 → 모션 | (사용자) `.ccProject` | 사용자 확인 | [rig_export](references/rig_export.md) |
| 8 | 피드백 반영 | 팔·발 어긋남 → `limbfit` / 파편 → Blender 삭제 후 재내보내기 | 같은 파일 덮어쓰기 | 전후 렌더 | [rig_export](references/rig_export.md) |
| 9 | 납품 | pack_all → `deliver.py` → 휴지통(확인 후) | farm\assets | 크기·텍스처 재검사 | [delivery](references/delivery.md) |

## 2. 이미지 생성 라우팅 (2026-09-13 사용자 지시)

**1차 범용 생성은 로컬 ComfyUI, 제대로 된 이미지만 유료(Kling `gemini-3-pro-image` = 나노바나나 계열).**
- 단계 2a~2d 는 모두 로컬에서 먼저 뽑고, 게이트·구성 확인을 통과한 방향만 같은 프롬프트로 Kling 에 보낸다. 유료 호출 전에 로컬 결과와 이유를 사용자에게 보여준다.
- ⚠ **로컬 참조 편집 워크플로우는 아직 없다** (`gen.py` 는 텍스트→이미지만, workflows 는 `klein4b_t2i`·`zimage_turbo_t2i`). 다음 캐릭터(FDK) 착수 첫 작업으로 만들고 검증한 뒤 이 절과 `Comfyui\CLAUDE.md` 모델 표를 갱신한다 — 방법은 [images](references/images.md) §로컬.
- comfy-mcp `generate_image` 는 SD1.5 기본이라 쓰지 않는다. 유료 `partner_generate`·노드 설치·모델 다운로드는 사용자 확인 후.
- Blender 렌더(바디·검사)는 생성 모델이 아니므로 해당 없음.

## 3. 게이트 수치

| 게이트 | 통과선 | 근거 |
|---|---|---|
| 자세(이미지) | 손끝 ±10px, 다리 여러 높이 **안쪽 가장자리** ±10px, 중심 ±10px(벗어나면 WARN) | WAR 발 +140px 누락, ALD 중심 +60px = 실제 A자 |
| 다리 축(3D) | `leg_axis_report` 발목 중심 오차 수 mm | ALD 80→5mm |
| 앞뒤 어긋남 | 옆면 겹침 렌더에서 정강이·팔뚝 노출 없음, 레이 앞/뒤 p50 차 작음 | 앞면 렌더만 보면 놓침 |
| 보정 품질 | 모서리 >1.5배 수십 개 이하, 두께 변화 ≤1mm(평행이동) | ALD 저주파 기각 사례 |
| 리깅 | 미할당 0, 레스트 평가 변화 0mm, append 잔차 <2mm | |
| 늘어남 | 가혹 포즈 >3배 100개 미만(참고). 같은 포즈 CC4 바디 값 병기 | 튜닉·서코트는 사용자 수용 이력(MUM-B 391, ALD 885) |
| 후드 | 좌/우 30°·끄덕 20°·기울 15° 두피 노출 ≤1%, 겉면 뚫림 없음(렌더) | MUM-A |
| 내보내기 | json 텍스처 참조 전부 해석, 메시 = Body·Tongue·suit | |

## 4. 판단 갈림길 (증상 → 조치)

| 증상 | 조치 | 하지 말 것 |
|---|---|---|
| 생성 이미지 다리 벌어짐·두꺼운 부츠 | 프롬프트 LOCKED 조항 1회 재시도 → 그래도면 사용자에게 "Blender 보정 전제로 진행?" | 3회 이상 재생성 |
| Meshy 다리 A자 | `legfix_axis`(dry → 적용) | 무릎 한 높이 중심으로 허벅지 각 계산(판갑에 끌려 과보정) |
| 부위별 앞뒤 치우침 (얇은 붕대) | `lowfreq_fit` | — |
| 부위별 앞뒤 치우침 (판갑·부츠) | `yshift_by_height` | `lowfreq_fit`(앞뒤 압축) |
| 머리·목 절단 | 민머리 `neck_plane_mask` / 칼라 `collar_sine_mask` / 후드 `face_flood_mask`+`remnant_mask` | 거리+방향 정점 판정 |
| 후드 정수리로 머리 뚫림 | `radial_scale` k≈0.06 | 정점별 법선 밀기(찢김 2회) |
| 튜닉·서코트 늘어남 | 사용자에게 CC4 확인 제안(수용 이력) | 거리 기준 넓은 웨이트 덮어쓰기, 자락 분리(틈 생김) |
| CC4 에서 팔·발 갑옷 어긋남 | `limbfit` (바디 고정, 웨이트 재사용) | 부위별 큰 회전(비틀림 포함) |
| CC4 에서 파편 삭제 요청 | Cloth 는 CC4 Delete Face 불가 → 사용자 CC4 내보내기 → Blender 삭제 → `_v2` 로 재내보내기 | — |

## 5. 운영 규칙

- **정지 조건**: 같은 증상이 2회 연속 안 풀리면 멈추고 ①바꾼 것 ②그대로인 것 ③원인 후보 3개로 사용자 선택을 받는다 (이 파이프라인에서 7회 발동 — 매번 선택지로 해결).
- 보정·절단은 **사본 또는 npy 백업**에서 시작해 재실행 가능하게. 삭제는 **색 미리보기 렌더 → 확인 → 적용**.
- 렌더는 Read 로 직접 보고 판단한다. 수치만으로 채택하지 않는다(발 돌출률 수치는 발바닥 레이가 섞여 과대).
- 사용자에게 산출물을 알릴 때: 폴더 경로를 한 줄로 출력 + 파일 용도 표 (폴더 열기 도구 쓰지 않음). 한국어.
- 결정·수치·실패는 `HANDOFF.md` 에 캐릭터 절(⑬ 형식)로 즉시 기록.

## references

- [images.md](references/images.md) — 바디 렌더, 로컬→Kling 규칙과 로컬 편집 워크플로우 구축 방법, 프롬프트 원문 템플릿(클레이·슈트 앞/뒤·후드·맨살 장비·마스크), 다운로드, 자세 게이트
- [blender_fit.md](references/blender_fit.md) — Meshy, 정렬, 진단, 다리·앞뒤 보정, 절단 방식별 파라미터
- [rig_export.md](references/rig_export.md) — CC/iC Tools, 웨이트, 포즈 검사, 내보내기, CC4 사용자 단계, 피드백 반영
- [pitfalls.md](references/pitfalls.md) — 실제로 겪은 함정 모음 (원인·교훈)
- [delivery.md](references/delivery.md) — farm\assets 분류 규칙, pack_all, deliver.py, 휴지통
