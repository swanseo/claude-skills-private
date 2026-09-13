# 단계 5~8: 리깅 → 내보내기 → CC4 → 피드백

## 5-1. 바디 임포트 (빈 장면)

- 애드온: CC/iC Blender Tools 2.4.3 (`%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\cc_blender_tools`), CC4 쪽 플러그인 Blender Pipeline 2.x.
- 호출 1: `bpy.ops.wm.read_homefile(use_empty=True)` / 호출 2: `bpy.ops.cc3.importer(filepath=r"...\out\<TAG>\<BODY>_body_src\<BODY>.Fbx", param="IMPORT", no_rigify=True)` — 같은 호출에 넣으면 "bad mesh".
- 확인: 뼈대 1개(이름 = 캐릭터명, 뼈 101~106), `CC_Base_Body` 14,164점, 이미지 파일 누락 0.
- 애드온 크래시(`CC3ImportProps` 사라짐, `already registered as a subclass 'addon_updater_install_popup'`): 남은 `cc_blender_tools` 클래스 unregister → `sys.modules` 에서 관련 모듈 삭제 → `addon_utils.enable`. 임포트 캐시는 복구 안 됨 → 저장된 blend 에서 재구성. 캐시 의존 단계 전에 blend 저장.

## 5-2. 슈트 부착·웨이트

```python
ROOT = r"D:\Google\Works-Drive\Claude\image-to-3D"
for f in (r"pipeline\fit_tools.py", r"pipeline\rig_tools.py"): exec(open(ROOT + "\\" + f, encoding="utf-8").read())
arm = find_armature(); body = bpy.data.objects["CC_Base_Body"]                # ★ append 전에 뼈대를 잡아 둔다
suit = append_suit(ROOT + r"\out\<TAG>\<TAG>_work.blend", "<TAG>_suit", arm)  # 잔차 <2mm 게이트 (바디 재내보내기 시 WAR 7mm 균일 이동도 여기서 흡수)
attach_and_transfer(suit, arm, "<tag>_suit_mat")                              # 미할당 0 이어야 함
fix_weights(suit, facial_head_above_z=None, save_pkl=ROOT + r"\out\<TAG>\<TAG>_weights_transfer.pkl")
bpy.ops.wm.save_as_mainfile(filepath=ROOT + r"\out\<TAG>\<TAG>_CC4_rig.blend")
```
- 후드(MUM-A): `facial_head_above_z` = 턱 위 높이(1.78 @ 키 1.978) → 후드는 머리, 목 부분은 NeckTwist02.
- 맨살형(WAR): 부츠·팔 장비는 **같은 쪽 팔다리 바디 정점에서만** 최근접 4점 역거리 재전송 / 요포 = 골반(1−t)+같은 쪽 허벅지 t(아래로 0→0.7, 가운데 ±0.06 반반) / 벨트·병 구간 Thigh 계열 제거 → 1,584→12개.
- 레스트 평가 변화 0mm 확인: 뼈대 REST 에서 evaluated 좌표 = 원 좌표.

## 5-3. 검사 (참고 게이트)

```python
stretch_test(suit, arm, POSE_HARSH, "harsh"); stretch_test(suit, arm, POSE_WALK, "walk")
stretch_test(body, arm, POSE_HARSH, "BODY harsh")        # 바디가 수 개면 포즈 탓이 아님
headturn_test(suit, body, arm)                           # 후드 캐릭터만
render_set(suit, "rig", ["full_front", "full_side"])     # 포즈를 걸고 보려면 _set_pose(arm, POSE_WALK) 후 렌더, 끝나면 _set_pose(arm, None)
```
- 치마·튜닉·서코트가 허벅지와 한 부피로 재구성된 캐릭터는 늘어남이 크다(MUM-B 391, ALD 885). **CC4 에서 보고 판단하자고 사용자에게 제안**하는 것이 이력상 최선이었다.
- 하지 말 것(MUM-B 실패): 거리 기준 튜닉 웨이트 덮어쓰기(391→2,351), 가운데 넓은 혼합(→2,774), 자락 split + 사타구니 조화 보간(401, 긴 틈 생김). 필요하면 `restore_weights(suit, pkl)`.

## 6. 내보내기

```python
export_cc3(ROOT + r"\out\<TAG>\<TAG>_suit_export.fbx", arm, ("CC_Base_Body", "CC_Base_Tongue", "<TAG>_suit"))
verify_export(ROOT + r"\out\<TAG>\<TAG>_suit_export.json")   # 참조 전부 해석 + 메시 3개
```
- 산출: `.fbx .fbxkey .json .fbm\ textures\` — 같은 폴더에 함께 있어야 CC4 가 읽는다. **`out/<TAG>/` 에만** 쓴다.
- CC4 가 불러올 때 같은 이름 `.txt`(0바이트)를 만들 수 있다 — 무시.

## 7. 사용자 CC4 단계 (안내 문구)

1. Plugins → Blender Pipeline → **Import Character From Blender** → `<TAG>_suit_export.fbx` (열기 창은 `*.fbx` 필터라 `.fbxkey` 가 안 보이는 게 정상)
2. 슈트 종류를 기본값 **Hair → Cloth** 로 변경 (안 바꾸면 모션을 안 따라감)
3. 슈트형: 얼굴·손만 남기고 바디 숨김 / 맨살형: 장비 아래 바디만 숨김 → 헤어 추가
4. 모션 확인 → `.ccProject` 저장(이름은 사용자가 정함 — ALD 는 `ALD_A-pose.ccProject`)
- `*.ccFacialProfile` 저장 창 = 표정 프로필 내보내기, 불필요(취소). CC4 마네킹 계열은 눈 뜨기·입 벌리기 표정이 제한적.
- 바디와 슈트가 목록에서 따로 보이는 것은 정상(같은 뼈대의 별도 메시). 메시를 합치면 바디 숨김을 못 쓴다.

## 8. 피드백 반영

| 요청 | 방법 |
|---|---|
| 팔·발 갑옷을 바디에 더 맞춰(바디 고정) | `<TAG>_CC4_rig.blend` 에서 `limbfit(suit, body, arm, pre_npy=out/<TAG>/<TAG>_suit_pre_limbfit_world.npy, save_disp=...)` → 발 위·손목·팔뚝 아래·무릎 앞·다리 옆 렌더 전후 비교 → `export_cc3` 덮어쓰기. 웨이트 재전송 불필요 |
| 슈트 파편 삭제 (CC4 에서 수정한 내용 보존) | CC4 Edit Mesh 의 Delete Face 는 Standard 캐릭터 **Cloth·Hair 불가**(공식 매뉴얼) → 사용자가 CC4 저장 후 Export Character to Blender(다른 이름, `out/<TAG>/`) → Blender 에서 **면 단위** 파편 찾기·삭제 → 전후 렌더 → `<TAG>_suit_export_v2.fbx` → 다시 Cloth 로 불러오기(정점 순서가 바뀌어 바디 숨김 재설정 필요할 수 있음) |
| 헤어 흰색 | HANDOFF ⑧-13 (VAE) 참조 |

limbfit 검증 기록(ALD v5): 팔뚝 돌출 32→8%, 정강이 8~10→0%, 발자국 중심 차 27→0.3mm, 모서리 >1.5배 33(최대 2.6). 적용 전 v1~v4 실패 원인은 [pitfalls](pitfalls.md) Blender 절.
- limbfit 후에는 소매 끝이 원래 손목 절단 평면 너머로 이동한다(ALD 왼팔 법선 방향 ≈19mm, `wrist_mask` 378점) — 정상. 손목을 다시 자르지 말고 렌더로 손이 소매 밖으로 깔끔히 나오는지만 본다.
