"""
sprite_to_sheet.py

Turns a pixel art sprite into a sprite sheet where each frame shows
the sprite growing from tiny to full size.

Usage:
    python sprite_to_sheet.py <sprite_path> [--frames N] [--min-scale F]

Arguments:
    sprite_path     Path to the input sprite (PNG recommended)
    --frames N      Number of frames to generate (default: 8)
    --min-scale F   Scale of the smallest frame as a fraction of full size (default: 0.1)

Output:
    <sprite_name>_sheet.png  — horizontal sprite sheet, each cell is the
                               size of the largest (full) frame, using
                               nearest-neighbour scaling to keep pixel art crisp.
"""

import argparse
from pathlib import Path
from PIL import Image


def make_growing_sheet(
    sprite_path: str,
    num_frames: int = 8,
    min_scale: float = 0.1,
) -> Path:
    src = Path(sprite_path)
    if not src.exists():
        raise FileNotFoundError(f"Sprite not found: {src}")

    sprite = Image.open(src).convert("RGBA")
    full_w, full_h = sprite.size

    # Each cell in the sheet is the size of the full sprite
    cell_w, cell_h = full_w, full_h

    # Build scale values that ramp from min_scale → 1.0 over num_frames
    # Frame 0 = smallest, last frame = full size
    scales = [
        min_scale + (1.0 - min_scale) * (i / (num_frames - 1))
        for i in range(num_frames)
    ]

    # Create the sheet canvas (horizontal strip)
    sheet_w = cell_w * num_frames
    sheet_h = cell_h
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))

    for i, scale in enumerate(scales):
        # Compute scaled size (at least 1×1)
        scaled_w = max(1, round(full_w * scale))
        scaled_h = max(1, round(full_h * scale))

        # Scale with nearest-neighbour to preserve pixel art look
        scaled_sprite = sprite.resize((scaled_w, scaled_h), Image.NEAREST)

        # Center the scaled sprite within its cell
        cell_x = i * cell_w
        paste_x = cell_x + (cell_w - scaled_w) // 2
        paste_y = (cell_h - scaled_h) // 2

        sheet.paste(scaled_sprite, (paste_x, paste_y), scaled_sprite)

    out_path = src.parent / (src.stem + "_sheet.png")
    sheet.save(out_path, "PNG")
    print(f"Saved {num_frames}-frame sheet ({sheet_w}×{sheet_h}px) → {out_path}")
    return out_path


def main():
    parser = argparse.ArgumentParser(
        description="Generate a growing sprite sheet from a pixel art sprite."
    )
    parser.add_argument("sprite", help="Path to the source sprite image")
    parser.add_argument(
        "--frames",
        type=int,
        default=8,
        help="Number of frames in the sheet (default: 8)",
    )
    parser.add_argument(
        "--min-scale",
        type=float,
        default=0.1,
        help="Scale of the smallest frame, 0.0–1.0 (default: 0.1)",
    )
    args = parser.parse_args()

    if not (0.0 < args.min_scale < 1.0):
        parser.error("--min-scale must be between 0.0 and 1.0 (exclusive)")
    if args.frames < 2:
        parser.error("--frames must be at least 2")

    make_growing_sheet(args.sprite, args.frames, args.min_scale)


if __name__ == "__main__":
    main()