"""Export store listing assets from the 1024px source icon.

Outputs to store_assets/:
  play_store/icon_512.png                  512x512 32-bit PNG (Play Console app icon)
  play_store/feature_graphic_1024x500.png  1024x500 PNG (Play Console feature graphic)
  app_store/icon_1024.png                  1024x1024 PNG, no alpha (App Store marketing icon)

Run from the repo root: python tool/export_store_assets.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ICON = ROOT / "assets" / "logo" / "nomnap_icon_1024.png"
MARK = ROOT / "assets" / "logo" / "nomnap_mark_1024.png"
OUT = ROOT / "store_assets"


def vertical_gradient(size, top_rgb, bottom_rgb):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(top_rgb, bottom_rgb))
        for x in range(w):
            px[x, y] = c
    return img


def main():
    icon = Image.open(ICON).convert("RGBA")
    assert icon.size == (1024, 1024), f"expected 1024x1024 source, got {icon.size}"

    play_dir = OUT / "play_store"
    appstore_dir = OUT / "app_store"
    play_dir.mkdir(parents=True, exist_ok=True)
    appstore_dir.mkdir(parents=True, exist_ok=True)

    # Play Store app icon: 512x512, 32-bit PNG
    icon.resize((512, 512), Image.LANCZOS).save(play_dir / "icon_512.png")

    # App Store marketing icon: 1024x1024, no alpha channel
    flat = Image.new("RGB", icon.size, (255, 203, 160))
    flat.paste(icon, mask=icon.split()[3])
    flat.save(appstore_dir / "icon_1024.png")

    # Feature graphic: brand gradient sampled from the icon, mark centered
    rgb = icon.convert("RGB")
    top = rgb.getpixel((512, 0))
    bottom = rgb.getpixel((512, 1023))
    fg = vertical_gradient((1024, 500), top, bottom)
    mark = Image.open(MARK).convert("RGBA")
    mark_size = 400
    mark = mark.resize((mark_size, mark_size), Image.LANCZOS)
    fg.paste(mark, ((1024 - mark_size) // 2, (500 - mark_size) // 2), mark)
    fg.save(play_dir / "feature_graphic_1024x500.png")

    for p in sorted(OUT.rglob("*.png")):
        img = Image.open(p)
        print(f"{p.relative_to(ROOT)}  {img.size[0]}x{img.size[1]}  {img.mode}  {p.stat().st_size} bytes")


if __name__ == "__main__":
    main()
