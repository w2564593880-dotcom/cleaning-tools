# -*- coding: utf-8 -*-
"""把“有效 DPI 过高”的插图降采样到打印够用的分辨率，缩小 PDF、加快 xdvipdfmx。

为什么有效：本仓库图片合计 145 MB，其中 71 张有效 DPI 超过 400（最高 2115 DPI，
即 5712x4284 的图被排到 68.6 mm 宽）。这些多出来的像素在 PDF 里既看不出来，
又要在每次 xdvipdfmx 时被解码、压缩一遍，是编译慢的主因。

用法（在 cleaning-tools 目录下）：
    python tools/analyze_figures.py                 # 先看现状
    python tools/optimize_figures.py --dry-run      # 只统计会改哪些、能省多少
    python tools/optimize_figures.py --apply        # 真正修改（原图备份到 figure/_orig/）
    python tools/optimize_figures.py --apply --target-dpi 250

只处理 \\includegraphics 里用 width=/height= 明确指定了打印尺寸的图片；
两者都没有的图片无法推算 DPI，跳过。只缩小、不放大。
"""
import argparse
import os
import shutil
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyze_figures import collect, effective_dpi  # noqa: E402


def fmt_mb(n):
    return f"{n / 1048576:.1f} MB"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="项目根目录（含 main.tex）")
    ap.add_argument("--target-dpi", type=float, default=300.0)
    ap.add_argument("--apply", action="store_true", help="真正写回文件")
    ap.add_argument("--dry-run", action="store_true", help="只报告，不写文件")
    ap.add_argument("--backup", action="store_true", default=True,
                    help="修改前把原图复制到 figure/_orig/（默认开启）")
    ap.add_argument("--no-backup", dest="backup", action="store_false")
    ap.add_argument("--jpeg-quality", type=int, default=90)
    args = ap.parse_args()

    os.chdir(args.root)
    figs = collect(".")
    total_before = total_after = 0
    changed = []
    for path, (width_mm, height_mm) in figs.items():
        try:
            with Image.open(path) as im:
                px_w, px_h = im.size
        except Exception as exc:
            print(f"跳过 {path}: {exc}")
            continue
        dpi = effective_dpi(px_w, px_h, width_mm, height_mm)
        if not dpi or dpi <= args.target_dpi * 1.02:
            continue
        scale = args.target_dpi / dpi
        new_w, new_h = max(1, round(px_w * scale)), max(1, round(px_h * scale))
        if new_w >= px_w:
            continue
        before = os.path.getsize(path)
        total_before += before
        changed.append((path, px_w, px_h, new_w, new_h, dpi, before))

        if not args.apply or args.dry_run:
            continue
        if args.backup:
            bak = os.path.join("figure", "_orig", os.path.relpath(path, "figure"))
            os.makedirs(os.path.dirname(bak), exist_ok=True)
            if not os.path.exists(bak):
                shutil.copy2(path, bak)
        with Image.open(path) as im:
            im = im.resize((new_w, new_h), Image.LANCZOS)
            ext = os.path.splitext(path)[1].lower()
            if ext in (".jpg", ".jpeg"):
                im.convert("RGB").save(path, "JPEG", quality=args.jpeg_quality, optimize=True)
            elif ext == ".png":
                im.save(path, "PNG", optimize=True)
            else:
                im.save(path)
        total_after += os.path.getsize(path)

    print(f"目标 DPI: {args.target_dpi:g}；需要降采样 {len(changed)} 张")
    print(f"{'原像素':>14} -> {'新像素':>12} {'原MB':>6} {'DPI':>5}  path")
    for path, px_w, px_h, new_w, new_h, dpi, before in sorted(changed, key=lambda r: -r[6])[:30]:
        print(f"{px_w}x{px_h:<7} -> {new_w}x{new_h:<7} {before/1048576:6.1f} {dpi:5.0f}  {path}")
    if args.apply and not args.dry_run and changed:
        print(f"\n合计：{fmt_mb(total_before)} -> {fmt_mb(total_after)}"
              f"（{(1 - total_after / max(total_before, 1)) * 100:.0f}% 更小）")
        print("原图备份在 figure/_orig/，确认无误后可删除该目录。")
        print("下一步：重新编译，PDF 会明显变小、xdvipdfmx 会明显变快。")
    elif changed:
        print("\n这是预览，没有改任何文件。加 --apply 执行。")


if __name__ == "__main__":
    main()
