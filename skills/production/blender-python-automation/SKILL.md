---
name: blender-python-automation
description: >
  Blender Python(bpy) 스크립트 작성·셰이더 노드 자동화·반복 작업 자동화를 진행할 때 반드시 사용할 것.
  사용자가 "Blender", "블렌더", "bpy", "Blender 파이썬", "셰이더 노드", "노드 자동생성",
  "Break & Stretch", "노드 그룹화", "모디파이어 자동화", "FBX 일괄 처리",
  "렌더 자동화", "카메라 각도 일괄", "지오메트리 노드", "Geometry Nodes",
  "Blender 애드온", "스크립트 자동화", "오브젝트 일괄 처리", "재질 일괄 적용" 등을 언급할 때마다
  반드시 트리거. 제품 광고용 3D 렌더링(FBX → Blender 각도 조정 → AI 합성) 워크플로우 요청에도 사용.
  Blender 4.2 기준. Claude API와 협업하는 반복 수정 워크플로우 지원.
---

# Blender Python 자동화 스킬

## 역할

Blender 4.2 기준 Python API(`bpy`)를 이용한 반복 작업 자동화 스크립트를 작성한다.
셰이더 노드 그룹 생성, 카메라 일괄 조작, FBX 배치 처리, 렌더 자동화가 핵심 영역.

피카서님 환경: Blender 4.2 / Windows 11 / RTX 4070 12GB.

---

## Step 1 — 작업 유형 분류

사용자 요청을 다음 유형으로 분류한다.

```
A. 셰이더 노드 자동화      — 노드 트리 생성·그룹화·연결
B. 카메라/뷰 조작          — 다각도 렌더, 턴테이블, FOV 일괄
C. 오브젝트 일괄 처리      — 트랜스폼, 모디파이어, 재질 일괄
D. FBX/외부 파일 처리     — 임포트·정리·익스포트 자동화
E. 렌더 자동화             — 시퀀스 렌더, 다중 카메라 렌더
F. 지오메트리 노드         — 절차적 셋업 자동화
```

---

## Step 2 — 스크립트 구조 표준 (모든 스크립트 공통)

```python
"""
스크립트명: [snake_case_name].py
용도: [한 줄 설명]
작성: Claude + 피카서
검증: Blender 4.2 / YYYY-MM-DD
"""

import bpy
import bmesh
from mathutils import Vector, Matrix
import os

# ========== 설정값 (사용자가 수정하는 영역) ==========
CONFIG = {
    "output_dir": r"D:\projects\output",
    "camera_angles": [0, 45, 90, 135, 180, 225, 270, 315],
    # 그 외 파라미터
}

# ========== 유틸리티 함수 ==========
def safe_select(obj):
    """오브젝트를 안전하게 선택 (deselect_all 포함)"""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

# ========== 메인 로직 ==========
def main():
    # 작업 본문
    pass

# ========== 실행 ==========
if __name__ == "__main__":
    main()
    print("[완료] 작업 종료")
```

⚠️ `bpy.ops` 남용 금지. 가능하면 `bpy.data` 직접 조작이 빠르고 안정적.

---

## Step 3 — 셰이더 노드 자동화 패턴

### Break & Stretch 노드 그룹 생성 예시

```python
def create_break_stretch_group():
    """Break & Stretch 셰이더 노드 그룹을 생성."""
    grp = bpy.data.node_groups.new("BreakStretch", "ShaderNodeTree")
    
    # 입력 인터페이스 정의 (Blender 4.0+ 신 API)
    grp.interface.new_socket(
        "Color", in_out='INPUT', socket_type='NodeSocketColor'
    )
    grp.interface.new_socket(
        "Intensity", in_out='INPUT', socket_type='NodeSocketFloat'
    )
    grp.interface.new_socket(
        "Result", in_out='OUTPUT', socket_type='NodeSocketColor'
    )
    
    # 내부 노드 생성
    grp_in = grp.nodes.new("NodeGroupInput")
    grp_out = grp.nodes.new("NodeGroupOutput")
    grp_in.location = (-400, 0)
    grp_out.location = (400, 0)
    
    mix = grp.nodes.new("ShaderNodeMix")
    mix.data_type = 'RGBA'
    mix.location = (0, 0)
    
    # 노드 연결
    grp.links.new(grp_in.outputs["Color"], mix.inputs[6])  # A
    grp.links.new(grp_in.outputs["Intensity"], mix.inputs[0])  # Factor
    grp.links.new(mix.outputs[2], grp_out.inputs["Result"])
    
    return grp
```

### 핵심 주의사항 (Blender 4.0+ 변경점)

```
구버전 (3.x)               신버전 (4.0+)
─────────────────────  →  ──────────────────────────
grp.inputs.new(...)         grp.interface.new_socket(...)
node.inputs[0]              node.inputs[6] (Mix 노드 등)

→ Blender 버전별 API 차이 반드시 명시하고 코드 작성
```

---

## Step 4 — 카메라 일괄 조작 (제품 광고 워크플로우)

### 8각도 턴테이블 렌더

```python
import math

def render_turntable(target_obj_name, num_angles=8, radius=5.0, height=2.0):
    """타겟 오브젝트 주위로 카메라를 회전시키며 렌더."""
    target = bpy.data.objects[target_obj_name]
    cam = bpy.data.objects["Camera"]
    
    for i in range(num_angles):
        angle = (2 * math.pi / num_angles) * i
        cam.location = Vector((
            target.location.x + radius * math.cos(angle),
            target.location.y + radius * math.sin(angle),
            target.location.z + height
        ))
        
        # 타겟 바라보기
        direction = target.location - cam.location
        cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
        
        # 렌더
        bpy.context.scene.render.filepath = os.path.join(
            CONFIG["output_dir"], f"angle_{i:02d}.png"
        )
        bpy.ops.render.render(write_still=True)
```

---

## Step 5 — FBX 배치 처리 (제품 광고용)

```python
def batch_process_fbx(input_dir, output_dir):
    """폴더 내 모든 FBX 파일에 대해 임포트→정리→익스포트."""
    fbx_files = [f for f in os.listdir(input_dir) if f.endswith('.fbx')]
    
    for fbx_file in fbx_files:
        # 새 씬으로 격리
        bpy.ops.scene.new(type='EMPTY')
        scene = bpy.context.scene
        scene.name = os.path.splitext(fbx_file)[0]
        
        # 임포트
        bpy.ops.import_scene.fbx(filepath=os.path.join(input_dir, fbx_file))
        
        # 정리 작업 (예: 스케일 통일, 원점 정렬)
        for obj in scene.objects:
            if obj.type == 'MESH':
                bpy.context.view_layer.objects.active = obj
                bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY')
        
        # 익스포트
        out_path = os.path.join(output_dir, fbx_file.replace('.fbx', '_processed.fbx'))
        bpy.ops.export_scene.fbx(filepath=out_path, use_selection=False)
        
        # 씬 정리
        bpy.ops.scene.delete()
```

---

## Step 6 — Claude API 협업 워크플로우

피카서님의 반복 수정 워크플로우 (Blender ↔ Claude):

```
1. Blender Text Editor에서 Python 스크립트 작성/수정
2. 실행 결과를 콘솔에서 캡처
3. 에러 로그·결과 스크린샷을 Claude에 전달
4. Claude가 수정안 제시
5. 다시 Blender에 붙여넣고 실행
6. 검증된 스크립트는 PICASEO KB에 기록
```

⚠️ Blender Python 콘솔의 한국어 출력은 윈도우에서 깨질 수 있음.
→ `print()` 대신 영문 메시지 또는 `import logging` 사용 권장.

---

## Step 7 — 검증 체크리스트

스크립트를 사용자에게 전달하기 전 확인:

```
□ Blender 4.2 API 기준으로 작성되었는가?
□ bpy.ops 의존도가 최소화되었는가?
□ 윈도우 경로 raw string(r"...")으로 작성되었는가?
□ 에러 발생 가능 지점에 try-except가 있는가?
□ CONFIG 영역과 로직 영역이 분리되어 있는가?
□ 실행 후 콘솔 출력이 명확한가?
□ Undo가 가능한 작업인가? (대량 삭제 등은 경고 추가)
```

---

## 누적 학습 메모

### 검증된 패턴
- 셰이더 노드 그룹은 `interface.new_socket()` 사용 (4.0+ 필수)
- 카메라 turntable은 `to_track_quat()` 방식이 안정적
- FBX 배치는 씬 격리 방식이 메모리 안전

### 발견된 한계
- 한국어 print 출력 인코딩 문제 (윈도우)
- bpy.ops.render.render 호출 시 GUI 멈춤 (백그라운드 렌더 권장)
- Geometry Nodes 4.2 신규 노드 일부는 Python 생성 어려움

### 미검증 / 추후 테스트
- Blender 4.3 신 API 호환성
- Unreal Engine 연동을 위한 USD 익스포트 자동화
- 멀티 GPU 렌더 자동 분배

---

## 참조 스킬
- `topaz-video-settings` — Blender 렌더 출력의 후반 강화
