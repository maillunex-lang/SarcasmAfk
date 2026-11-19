"""Pack RGBA PNG frames into a horizontal atlas + atlas.json (no Pillow required)."""
from __future__ import annotations

import json
import struct
import sys
import zlib
from pathlib import Path


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def read_png(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"not png: {path}"
    pos = 8
    width = height = 0
    raw = b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        pos += 4
        ctype = data[pos : pos + 4]
        pos += 4
        chunk = data[pos : pos + length]
        pos += length
        pos += 4  # crc
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, *_ = struct.unpack(">IIBBBBB", chunk)
            if bit_depth != 8 or color_type != 6:
                raise SystemExit(f"need 8-bit RGBA PNG: {path} ({bit_depth}/{color_type})")
        elif ctype == b"IDAT":
            raw += chunk
        elif ctype == b"IEND":
            break
    decompressed = zlib.decompress(raw)
    stride = width * 4
    rows: list[bytearray] = []
    i = 0
    prev = bytearray(stride)
    for _y in range(height):
        filter_type = decompressed[i]
        i += 1
        row = bytearray(decompressed[i : i + stride])
        i += stride
        if filter_type == 0:
            pass
        elif filter_type == 1:  # Sub
            for x in range(stride):
                left = row[x - 4] if x >= 4 else 0
                row[x] = (row[x] + left) & 255
        elif filter_type == 2:  # Up
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 255
        elif filter_type == 3:  # Average
            for x in range(stride):
                left = row[x - 4] if x >= 4 else 0
                row[x] = (row[x] + ((left + prev[x]) >> 1)) & 255
        elif filter_type == 4:  # Paeth
            for x in range(stride):
                left = row[x - 4] if x >= 4 else 0
                up = prev[x]
                up_left = prev[x - 4] if x >= 4 else 0
                row[x] = (row[x] + _paeth(left, up, up_left)) & 255
        else:
            raise SystemExit(f"unsupported PNG filter {filter_type} in {path}")
        rows.append(row)
        prev = row
    rgba = b"".join(rows)
    return width, height, rgba


def write_png(path: Path, width: int, height: int, rgba: bytes) -> None:
    assert len(rgba) == width * height * 4
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # None filter
        raw.extend(rgba[y * stride : (y + 1) * stride])

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )


def pack(frames_dir: Path, out_png: Path, out_json: Path, asset_id: str) -> dict:
    frames = sorted(frames_dir.glob("frame_*.png"))
    if not frames:
        raise SystemExit(f"no frames in {frames_dir}")
    w0, h0, _ = read_png(frames[0])
    atlas_w = w0 * len(frames)
    atlas_h = h0
    buf = bytearray(atlas_w * atlas_h * 4)
    meta_frames = []
    opaque_px = 0
    for i, fp in enumerate(frames):
        w, h, rgba = read_png(fp)
        if w != w0 or h != h0:
            raise SystemExit(f"frame size mismatch {fp}: {w}x{h} vs {w0}x{h0}")
        x0 = i * w0
        for y in range(h0):
            src = y * w0 * 4
            dst = (y * atlas_w + x0) * 4
            buf[dst : dst + w0 * 4] = rgba[src : src + w0 * 4]
        for a in rgba[3::4]:
            if a > 8:
                opaque_px += 1
        meta_frames.append(
            {
                "name": f"idle_{i:02d}",
                "x": x0,
                "y": 0,
                "w": w0,
                "h": h0,
                "source": fp.name,
            }
        )
    write_png(out_png, atlas_w, atlas_h, bytes(buf))
    meta = {
        "asset_id": asset_id,
        "animation": "idle",
        "frame_count": len(frames),
        "frame_w": w0,
        "frame_h": h0,
        "atlas_w": atlas_w,
        "atlas_h": atlas_h,
        "image": out_png.name,
        "transparent": True,
        "opaque_pixels": opaque_px,
        "frames": meta_frames,
        "note": "Dev sample from Blender pipeline — not final art (D-ART-02)",
    }
    out_json.write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"OK pack_atlas frames={len(frames)} atlas={out_png}")
    return meta


def main() -> None:
    if len(sys.argv) < 5:
        raise SystemExit("usage: pack_atlas.py <frames_dir> <atlas.png> <atlas.json> <asset_id>")
    pack(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4])


if __name__ == "__main__":
    main()
