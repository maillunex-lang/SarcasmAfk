"""Render transparent PNG frames from a pipeline .blend (T-031)."""
import sys
from pathlib import Path

import bpy


def configure_transparent(out_dir: Path, frame_start: int, frame_end: int) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    # Blender 4.x may use EEVEE_NEXT
    if hasattr(bpy.types.RenderSettings, "engine"):
        try:
            scene.render.engine = "BLENDER_EEVEE_NEXT"
        except Exception:
            scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.frame_start = frame_start
    scene.frame_end = frame_end
    out_dir.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(out_dir / "frame_")


def main() -> None:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    blend = Path(argv[0])
    out_dir = Path(argv[1])
    frame_start = int(argv[2]) if len(argv) > 2 else 1
    frame_end = int(argv[3]) if len(argv) > 3 else 8

    bpy.ops.wm.open_mainfile(filepath=str(blend))
    configure_transparent(out_dir, frame_start, frame_end)
    bpy.ops.render.render(animation=True)
    frames = sorted(out_dir.glob("frame_*.png"))
    print(f"OK render_frames count={len(frames)} dir={out_dir}")


if __name__ == "__main__":
    main()
