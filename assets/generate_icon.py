"""
StudentTrack Pro — App Icon Generator
Programmatically creates icon.ico using Pillow.
"""

import os
from PIL import Image, ImageDraw, ImageFont


def generate_icon(output_path: str):
    """
    Generate a colorful icon.ico for StudentTrack Pro.
    Draws a book + star symbol in blue/gold.
    """
    sizes = [16, 32,48, 64, 128, 256]
    images = []

    for size in sizes:
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Background circle
        margin = size // 10
        draw.ellipse(
            [margin, margin, size - margin, size - margin],
            fill=(13, 17, 23, 255)
        )

        # Book body
        bx1 = int(size * 0.18)
        bx2 = int(size * 0.82)
        by1 = int(size * 0.20)
        by2 = int(size * 0.78)
        mid = (bx1 + bx2) // 2

        draw.rectangle([bx1, by1, mid, by2], fill=(30, 144, 255))      # left page blue
        draw.rectangle([mid, by1, bx2, by2], fill=(0, 191, 255))       # right page light blue
        draw.line([(mid, by1), (mid, by2)], fill=(255, 255, 255, 180), width=max(1, size // 32))

        # Star overlay (top right)
        cx = int(size * 0.72)
        cy = int(size * 0.28)
        r = int(size * 0.18)

        def star_point(angle_deg, radius):
            import math
            angle = (angle_deg - 90) * (3.14159 / 180)
            return cx + radius * math.cos(angle), cy + radius * math.sin(angle)

        star_pts = []
        for i in range(5):
            star_pts.append(star_point(i * 72, r))
            star_pts.append(star_point(i * 72 + 36, r * 0.4))

        draw.polygon(star_pts, fill=(255, 214, 10))

        images.append(img)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    images[0].save(
        output_path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=images[1:]
    )
    print(f"[Icon] Generated icon at: {output_path}")


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "assets", "icon.ico")
    generate_icon(out)
