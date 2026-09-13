# 단계 3~4: Meshy → Blender 정렬·보정·절단

## 3. Meshy

```bash
cd D:/Google/Works-Drive/Claude/image-to-3D && python meshy.py detail --name <TAG> --images out/<TAG>/<TAG>_suit_front.jpg out/<TAG>/<TAG>_suit_back.jpg --pose ""
```
- `--pose ""` 필수(A-포즈 강제 금지). 결과 `out/<TAG>/<TAG>_detail.glb/.fbx`(약 100MB), 300초 안팎, 35 크레딧 → Bash `run_in_background`.
- 같은 바디로 변형 두 개(MUM-A/B)면 `--name` 이 폴더·파일명을 정하므로 끝나면 `<VAR>_detail.*` 로 이름 변경.

## 4-1. 불러오기·정렬 (작업 blend = 바디 렌더 때 저장한 `<TAG>_work.blend`)

```python
ROOT = r"D:\Google\Works-Drive\Claude\image-to-3D"
for f in ("blender_tail.py", "blender_armor.py", r"pipeline\fit_tools.py", r"pipeline\cut_tools.py"):
    exec(open(ROOT + "\\" + f, encoding="utf-8").read())
mann = bpy.data.objects["CC_Base_Body"]
suit, rep = prep_body(ROOT + r"\out\<TAG>\<TAG>_detail.glb", "<TAG>_meshy")   # (ob, report) 튜플
for l in align_skin_fit(suit, mann): print(l)                                  # 마지막 중앙 오차 5~6mm 면 정상
bk = suit.copy(); bk.data = suit.data.copy(); bk.name = bk.data.name = "<TAG>_meshy_orig"; bpy.context.collection.objects.link(bk); bk.hide_set(True)
```
- NumPy 2.0: `arr.ptp()` 제거됨 → `np.ptp(arr)`.
- 한 번에 긴 코드가 중간에 오류 나면 이미 만든 오브젝트가 남는다 → 재실행 전 존재 여부를 확인하고 재사용.

## 4-2. 진단 (보정 전에 반드시)

1. `render_set(suit, "A0", ["full_front", "full_side", "full_back"])` → **옆면 겹침**을 본다(앞면만 보면 앞뒤 어긋남을 놓침).
2. `ray_gaps(suit, mann)` — 부위별 앞(F)/뒤(B)/옆(S) p50 과 돌출률. 앞뒤 p50 차이가 크면 앞뒤 치우침.
3. 다리가 의심되면 `leg_axis_report(suit, mann)` — 안쪽 가장자리가 발목으로 갈수록 커지면 A자.
4. 머리 구역 높이별 바디 거리 분포(후드·칼라 판단용) — MUM-A: 정수리 Z1.92~1.98 거리 4~7mm = 후드가 머리에 밀착 재구성.

## 4-3. 보정 (선택 표)

| 상황 | 함수 | 검증 이력 |
|---|---|---|
| 무릎 아래 A자 | `legfix_axis(suit, mann, arm, dry=True)` → 수치 확인 → `dry=False` | ALD 종아리 ±8~9°, 발목 오차 80→5mm. 무릎 높이 중심으로 허벅지 각을 잡으면 옆 판에 끌려 과보정 |
| 얇은 붕대 슈트의 부위별 앞뒤 치우침 | `lowfreq_fit(suit, mann)` (clr 4mm, ctrl 20mm, R 60mm, cap 25mm) | MUM-B·MUM-A 이동 p50 4.5mm, 뒤 돌출 대폭 감소 |
| 판갑·부츠 캐릭터의 앞뒤 치우침 | `yshift_by_height(suit, mann)` | ALD 종아리 앞 돌출 72→33%, 두께 변화 ≤0.3mm. 1회차 부호 실수로 반대 이동 — 부호는 `y += 치우침` |
| 맨살형 장비가 몸속/뜸 | 부위별 강체 탐색 → `conform_gear`(push-only) → 기준 판 간격을 복사하는 저주파 당기기 | WAR ⑩. 넓은 반경 정점별 당기기는 병·해골 디테일을 뭉갬 |

적용 후마다: `edge_ratio`(>2배 소수), `ray_gaps` 재측정, 옆면 렌더. 채택 전 상태는 사본(`<TAG>_meshy_legfix` 등) 또는 npy 로 보존.
**금지**: 두꺼운 장비에 `lowfreq_fit` 확대 설정(ctrl 60/R 80/cap 50) — ALD 몸통 앞뒤 −62~−75mm 압축, 모서리 >2배 231 → 기각.

## 4-4. 절단 (마스크 → 색 미리보기 → 사본에 적용)

공통: `mask = ... ; paint_preview(suit, [(head_mask,(0.9,0.15,0.15)), (wrist_mask_,(0.2,0.35,0.9))], "cut", views)` → Read 로 확인 → `new = apply_cut(suit, head_mask | wrist_mask_, "<TAG>_suit", keep_min=200)`.

| 부위 | 함수 | 파라미터 예 | 확인 |
|---|---|---|---|
| 손목 | `wrist_mask(co, arm, xmin=0.45)` | 손 관절 머리·Forearm→Hand 수직 평면 | 잘린 뒤 `(co−h)·n > 1mm` 인 정점 0 (|X|>0.45 로 한정해야 같은 쪽 다리가 안 섞임) |
| 민머리·낮은 목 | `neck_plane_mask(co, z0, slope=0.5, y0=-0.03)` | MUM-B z0 1.735(키 1.978) | 앞 턱 밑 ↔ 뒤 목덜미, 원 붕대 윗단을 따라가는지 |
| 높은 칼라 | `neck_centre` → `collar_probe` + 앞/옆 렌더로 윗단 읽기 → `collar_sine_mask(co, cx, cy, z_side, amp)` | ALD 1.615 ± 0.030 | 칼라 앞(턱 밑)·옆·뒤 온전, 머리·귀·턱 전부 제거, 떠 있는 얼굴 조각 없음 |
| 후드 유지 | `face_flood_mask(suit, mann)` → 사본에 적용 → `remnant_mask(new, mann)` 삭제 → 정수리 뚫림이면 `radial_scale(new, centre=(0, 0.01, head_z), k=0.06)` | MUM-A: 얼굴+후드 속 머리면 3,394점, 잔여 134점 | 후드 안 CC4 얼굴 깨끗, 후드 속 빔, 옆·뒤 구멍 없음, 정수리 빨강 없음(바디 켠 3/4 원근) |

- 칼라 캐릭터에서 실패한 자동 판정: 기울어진 평면(칼라 윗단 곡선 못 따라감), 피부 8mm 이내(칼라 앞면이 목에 붙어 구멍), 방위별 피부 반경(턱이 튀어나와 칼라 앞 누락) → 3회 연속 실패 후 수치 곡선으로 해결.
- 후드에서 실패한 것: 거리+방향 정점 판정(후드 옆면 오탐), 정점별 법선 밀기 2회(후드 윗단 찢김). 겉면/속면을 '바깥 레이 가림'으로 나누는 판정은 개구부 때문에 흔들린다.
- 절단 후 열린 고리(목·손목 개구부)는 정상. 손목 경계만 다듬고 얼굴 개구부 톱니는 찢어진 천으로 수용했다.

## 4-5. 저장
`bpy.ops.wm.save_mainfile()` (작업 blend). 채택 슈트 이름을 `<TAG>_suit` 로 고정 — 리깅 단계가 이 이름으로 append 한다.
