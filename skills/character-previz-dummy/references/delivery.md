# 단계 9: 납품 (production\farm\assets)

사용자 규칙(2026-09-13): **원본·최종본만 옮기고 중간 파일은 삭제, image-to-3D 에는 남기지 않는다.** Meshy 원본은 함께 옮긴다(재처리 시 크레딧 절약).

## 목적지

`D:\Google\Works-Drive\VAEL\production\farm\assets\` 기존 분류를 따른다.

| 캐릭터 | 폴더 |
|---|---|
| VAE | `01_Party_Characters\Vael\3D_Previz_Dummy_CC4` (완료) |
| WAR | `01_Party_Characters\Warrior\3D_Previz_Dummy_CC4` (완료) |
| ALD | `01_Party_Characters\Aldric\3D_Previz_Dummy_CC4` (완료) |
| MUM-A·MUM-B | `03_Dungeon_Creatures\Mummy\3D_Previz_Dummy_CC4` (완료, 같은 바디 공유) |
| FDK | `03_Dungeon_Creatures\` 아래 — 폴더명은 착수 시 사용자 확인 (시트 `FDK-sheet-v01.png` 가 03 루트에 있음) |
| UKG | `02_Boss_UndeadKing\` 아래 — 착수 시 확인 |

폴더 안 구성: `.ccProject` · `<X>_export.fbx/.fbxkey/.json/.fbm` · `textures\` · `body_src\`(CC4 바디 원본 + textures) · `blender\`(리깅 blend, 텍스처 패킹) · `meshy\`(detail.fbx/.glb)

## 절차

1. 사용자가 CC4 `.ccProject` 를 `out/` 에 저장했는지 확인(이름은 사용자 지정).
2. Blender: 리깅 blend 텍스처 패킹 — `.blend1` 안 만들게
   ```python
   prefs = bpy.context.preferences.filepaths; old = prefs.save_version; prefs.save_version = 0
   bpy.ops.wm.open_mainfile(filepath=r"...\out\<TAG>\<TAG>_CC4_rig.blend"); bpy.ops.file.pack_all(); bpy.ops.wm.save_mainfile()
   prefs.save_version = old
   ```
3. `python pipeline/deliver.py --tag <TAG> --body <BODY> --dest "<분류>\<캐릭터>\3D_Previz_Dummy_CC4" --ccproject out/<CC>.ccProject` (dry-run)
   → 이동 목록·새 배치 텍스처 참조 수·목적지 충돌 확인 → 사용자에게 **이동 목록 + 삭제 후보 목록(개수·용량·종류)** 을 보여주고 확인
4. `--apply` → 목적지 존재·크기 확인, json 텍스처 참조를 새 위치 기준으로 재검사.
5. 시트 원본은 production 에 해시 동일본이 있으면 옮기지 않는다(`_recalibrated`, 캐릭터 폴더). input 중복본만 삭제 후보.
6. 삭제(사용자 확인 후, 휴지통): **남은 파일이 전부 삭제 목록 안에 있는 폴더만** 통째로 휴지통
   ```powershell
   Add-Type -AssemblyName Microsoft.VisualBasic
   $ui=[Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs; $rb=[Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
   [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('D:\...\out\<TAG>', $ui, $rb)
   [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('D:\...\input\<file>', $ui, $rb)
   ```
   목록 밖 파일이 섞인 폴더는 건너뛰고 보고. 끝나면 "삭제 목록 중 남은 파일 0" 확인.
7. HANDOFF 캐릭터 절에 이동 결과(파일 수·용량·텍스처 재검사)를 기록하고, 메모리 `meshy-previz-pipeline` 의 완성 목록을 갱신.
8. 사용자 보고: 캐릭터별 폴더 경로 한 줄씩 + 폴더 구성 표 + 휴지통 개수·용량 + 남긴 것.
