"""Create a minimal proxy character .blend with idle keyframes (T-031)."""
import math
import sys
from pathlib import Path

import bpy


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)
    for block in bpy.data.actions:
        bpy.data.actions.remove(block)


def make_mat(name: str, rgba: tuple[float, float, float, float]):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        if "Alpha" in bsdf.inputs:
            bsdf.inputs["Alpha"].default_value = 1.0
    return mat


def build(asset_id: str, out_blend: Path) -> None:
    clear_scene()
    # Body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=1.4, location=(0, 0, 0.9))
    body = bpy.context.active_object
    body.name = f"{asset_id}_body"
    body.data.materials.append(make_mat("BodyMat", (0.33, 0.55, 0.72, 1.0)))

    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.38, location=(0, 0, 1.95))
    head = bpy.context.active_object
    head.name = f"{asset_id}_head"
    head.data.materials.append(make_mat("HeadMat", (0.91, 0.84, 0.72, 1.0)))

    bpy.ops.mesh.primitive_cube_add(size=0.35, location=(0.55, 0, 1.2))
    arm_r = bpy.context.active_object
    arm_r.name = f"{asset_id}_arm_r"
    arm_r.scale = (0.4, 0.4, 1.2)
    arm_r.data.materials.append(make_mat("ArmMat", (0.91, 0.74, 0.41, 1.0)))

    bpy.ops.mesh.primitive_cube_add(size=0.35, location=(-0.55, 0, 1.2))
    arm_l = bpy.context.active_object
    arm_l.name = f"{asset_id}_arm_l"
    arm_l.scale = (0.4, 0.4, 1.2)
    arm_l.data.materials.append(make_mat("ArmMat2", (0.91, 0.74, 0.41, 1.0)))

    # Parent under empty root
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = f"{asset_id}_root"
    for obj in (body, head, arm_r, arm_l):
        obj.parent = root

    # Idle: bob + arm sway (8 frames @ 8fps → 1s loop)
    scene = bpy.context.scene
    scene.render.fps = 8
    scene.frame_start = 1
    scene.frame_end = 8

    action = bpy.data.actions.new(name="idle")
    if root.animation_data is None:
        root.animation_data_create()
    root.animation_data.action = action

    for frame in range(1, 9):
        t = (frame - 1) / 8.0 * math.tau
        root.location.z = 0.06 * math.sin(t)
        root.keyframe_insert(data_path="location", frame=frame, index=2)
        arm_r.rotation_euler.x = 0.25 * math.sin(t)
        arm_r.keyframe_insert(data_path="rotation_euler", frame=frame, index=0)
        arm_l.rotation_euler.x = -0.25 * math.sin(t)
        arm_l.keyframe_insert(data_path="rotation_euler", frame=frame, index=0)

    # Camera: side orthographic for 2D sprite look
    bpy.ops.object.camera_add(location=(0, -6.5, 1.2), rotation=(math.radians(90), 0, 0))
    cam = bpy.context.active_object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 3.2
    scene.camera = cam

    # Soft key light
    bpy.ops.object.light_add(type="AREA", location=(2.5, -2.0, 4.0))
    light = bpy.context.active_object
    light.data.energy = 400

    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    print(f"OK create_rig {out_blend}")


def main() -> None:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    asset_id = argv[0] if argv else "sample_unit"
    out = Path(argv[1]) if len(argv) > 1 else Path(f"/tmp/{asset_id}.blend")
    build(asset_id, out)


if __name__ == "__main__":
    main()
