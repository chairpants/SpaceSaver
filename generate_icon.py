#!/usr/bin/env python3
"""
Generates PNG icons from the SVG source for all required macOS sizes.
Requires cairosvg: pip install cairosvg
"""

import os
import sys

# macOS icon sizes
ICON_SIZES = [
    (16, 1),    # 16x16 @1x
    (16, 2),    # 16x16 @2x (32x32)
    (32, 1),    # 32x32 @1x
    (32, 2),    # 32x32 @2x (64x64)
    (128, 1),   # 128x128 @1x
    (128, 2),   # 128x128 @2x (256x256)
    (256, 1),   # 256x256 @1x
    (256, 2),   # 256x256 @2x (512x512)
    (512, 1),   # 512x512 @1x
    (512, 2),   # 512x512 @2x (1024x1024)
]

def generate_icons():
    try:
        import cairosvg
    except ImportError:
        print("❌ Error: cairosvg is required.")
        print("Install it with: pip install cairosvg")
        print("\nAlternatively, you can use the SVG icon directly in design software")
        print("to export PNGs at the required sizes.")
        return False

    svg_path = "SpaceSaver/Assets.xcassets/AppIcon.appiconset/SpaceSaver-Icon.svg"

    if not os.path.exists(svg_path):
        print(f"❌ Error: {svg_path} not found")
        return False

    output_dir = "SpaceSaver/Assets.xcassets/AppIcon.appiconset"

    print("🎨 Generating app icons from SVG...")
    print()

    for size, scale in ICON_SIZES:
        pixel_size = size * scale
        filename = f"icon_{size}x{size}@{scale}x.png"
        output_path = os.path.join(output_dir, filename)

        try:
            cairosvg.svg2png(
                url=svg_path,
                write_to=output_path,
                output_width=pixel_size,
                output_height=pixel_size
            )
            print(f"✓ {filename} ({pixel_size}x{pixel_size})")
        except Exception as e:
            print(f"✗ Error generating {filename}: {e}")
            return False

    print()
    print("✅ All icons generated successfully!")
    print(f"   Location: {output_dir}/")
    print()
    print("Next steps:")
    print("1. Open SpaceSaver.xcodeproj in Xcode")
    print("2. Select Assets.xcassets")
    print("3. The icons should now appear in the AppIcon preview")
    return True

if __name__ == "__main__":
    generate_icons()
