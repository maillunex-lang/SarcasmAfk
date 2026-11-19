"""Create a character-profiled proxy .blend (unique silhouette/colors per profiles.json)."""
import json
import math
import sys
from pathlib import Path

import bpy

PIPE = Path(__file__).resolve().parent


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        bpy.data.materials.remove(block)
    for block in list(bpy.data.actions):
        bpy.data.actions.remove(block)


def make_mat(name: str, rgba):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = tuple(rgba)
    return mat


def load_profile(asset_id: str) -> dict:
    data = json.loads((PIPE / "profiles.json").read_text(encoding="utf-8"))
    profiles = data.get("profiles", {})
    if asset_id in profiles:
        return profiles[asset_id]
    return {
        "body": [0.33, 0.55, 0.72, 1.0],
        "head": [0.91, 0.84, 0.72, 1.0],
        "hair": [0.2, 0.2, 0.25, 1.0],
        "accent": [0.91, 0.74, 0.41, 1.0],
        "prop": "none",
        "width": 0.45,
        "height": 1.4,
    }


def build(asset_id: str, out_blend: Path) -> None:
    clear_scene()
    p = load_profile(asset_id)
    w = float(p.get("width", 0.45))
    h = float(p.get("height", 1.4))

    bpy.ops.mesh.primitive_cylinder_add(radius=w, depth=h, location=(0, 0, h * 0.55))
    body = bpy.context.active_object
    body.name = f"{asset_id}_body"
    body.data.materials.append(make_mat("Body", p["body"]))

    bpy.ops.mesh.primitive_uv_sphere_add(radius=w * 0.85, location=(0, 0, h * 1.25))
    head = bpy.context.active_object
    head.name = f"{asset_id}_head"
    head.data.materials.append(make_mat("Head", p["head"]))

    # Hair volume (class silhouette)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=w * 0.95, location=(0, -0.05, h * 1.38))
    hair = bpy.context.active_object
    hair.name = f"{asset_id}_hair"
    hair.scale = (1.05, 0.9, 0.7)
    hair.data.materials.append(make_mat("Hair", p["hair"]))

    bpy.ops.mesh.primitive_cube_add(size=0.3, location=(w * 1.35, 0, h * 0.85))
    arm_r = bpy.context.active_object
    arm_r.name = f"{asset_id}_arm_r"
    arm_r.scale = (0.35, 0.35, 1.1)
    arm_r.data.materials.append(make_mat("ArmR", p["accent"]))

    bpy.ops.mesh.primitive_cube_add(size=0.3, location=(-w * 1.35, 0, h * 0.85))
    arm_l = bpy.context.active_object
    arm_l.name = f"{asset_id}_arm_l"
    arm_l.scale = (0.35, 0.35, 1.1)
    arm_l.data.materials.append(make_mat("ArmL", p["accent"]))

    prop = str(p.get("prop", "none"))
    prop_obj = None
    if prop == "sword":
        bpy.ops.mesh.primitive_cube_add(size=0.2, location=(w * 1.7, 0.2, h * 0.7))
        prop_obj = bpy.context.active_object
        prop_obj.scale = (0.25, 0.08, 1.6)
        prop_obj.rotation_euler.z = math.radians(25)
    elif prop == "key":
        bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.05, location=(w * 1.6, 0.25, h * 0.95))
        prop_obj = bpy.context.active_object
    elif prop == "staff":
        bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=h * 1.2, location=(-w * 1.7, 0.15, h * 0.7))
        prop_obj = bpy.context.active_object
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14, location=(-w * 1.7, 0.15, h * 1.35))
        orb = bpy.context.active_object
        orb.data.materials.append(make_mat("Orb", p["accent"]))
    elif prop == "stamp":
        bpy.ops.mesh.primitive_cube_add(size=0.5, location=(0, 0.35, h * 0.9))
        prop_obj = bpy.context.active_object
        prop_obj.scale = (1.2, 0.15, 0.9)
    if prop_obj:
        prop_obj.name = f"{asset_id}_prop"
        prop_obj.data.materials.append(make_mat("Prop", p["accent"]))

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = f"{asset_id}_root"
    kids = [body, head, hair, arm_r, arm_l]
    if prop_obj:
        kids.append(prop_obj)
    if prop == "staff":
        kids.append(orb)
    for obj in kids:
        obj.parent = root

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
        root.location.z = 0.05 * math.sin(t)
        root.keyframe_insert(data_path="location", frame=frame, index=2)
        arm_r.rotation_euler.x = 0.28 * math.sin(t)
        arm_r.keyframe_insert(data_path="rotation_euler", frame=frame, index=0)
        arm_l.rotation_euler.x = -0.28 * math.sin(t)
        arm_l.keyframe_insert(data_path="rotation_euler", frame=frame, index=0)

    bpy.ops.object.camera_add(location=(0, -6.5, h * 0.75), rotation=(math.radians(90), 0, 0))
    cam = bpy.context.active_object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(3.0, h * 2.1)
    scene.camera = cam
    bpy.ops.object.light_add(type="AREA", location=(2.5, -2.0, 4.0))
    bpy.context.active_object.data.energy = 420

    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    print(f"OK create_rig asset={asset_id} prop={prop} → {out_blend}")


def main() -> None:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    asset_id = argv[0] if argv else "sample_unit"
    out = Path(argv[1]) if len(argv) > 1 else Path(f"/tmp/{asset_id}.blend")
    build(asset_id, out)


if __name__ == "__main__":
    main()
