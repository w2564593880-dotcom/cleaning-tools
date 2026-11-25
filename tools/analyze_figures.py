# -*- coding: utf-8 -*-
"""统计 main.tex 所用图片的像素尺寸与“有效 DPI”，找出拖慢编译的超大图。

用法（在 cleaning-tools 目录下）：
    python tools/analyze_figures.py
"""
import os
import re
from collections import Counter

from PIL import Image

TEXTWIDTH_MM = 159.2   # geometry: A4 210mm - 2*25.4mm
TEXTHEIGHT_MM = 246.2  # geometry: A4 297mm - 2*25.4mm

INCLUDE_RE = re.compile(r"\\includegraphics\s*\[([^\]]*)\]\s*\{([^}]+)\}")
WIDTH_RE = re.compile(r"width\s*=\s*([0-9.]+)\s*\\(?:textwidth|linewidth|columnwidth)")
HEIGHT_RE = re.compile(r"height\s*=\s*([0-9.]+)\s*\\(?:textheight|height)")
LEN_RE = re.compile(r"(width|height)\s*=\s*([0-9.]+)\s*(mm|cm|in|pt)")


def dims_from_opts(opts):
    """返回 (width_mm, height_mm)，没有指定则为 None。"""
    width_mm = height_mm = None
    for kind, value, unit in LEN_RE.findall(opts):
        value = float(value)
        mm = {"mm": value, "cm": value * 10, "in": value * 25.4, "pt": value * 25.4 / 72.27}[unit]
        if kind == "width":
            width_mm = mm
        else:
            height_mm = mm
    m = WIDTH_RE.search(opts)
    if m and width_mm is None:
        width_mm = float(m.group(1)) * TEXTWIDTH_MM
    m = HEIGHT_RE.search(opts)
    if m and height_mm is None:
        height_mm = float(m.group(1)) * TEXTHEIGHT_MM
    return width_mm, height_mm


def collect(tex_root):
    """{图片路径: (width_mm, height_mm)}。

    同一张图可能在多处被引用、打印宽度不同；这里对每个方向取最大值，
    保证降采样后即使按最大的那处排版也仍有目标 DPI。
    """
    seen = {}
    for dirpath, dirnames, filenames in os.walk(tex_root):
        dirnames[:] = [d for d in dirnames
                       if d not in {"_backup_ai_20261018", "_backup_ai_20261114", ".git", "build", "_build", "_timing_proj", "_timing", "_timing_draft"}]
        for name in filenames:
            if not name.endswith(".tex"):
                continue
            path = os.path.join(dirpath, name)
            try:
                text = open(path, encoding="utf-8", errors="ignore").read()
            except OSError:
                continue
            for opts, target in INCLUDE_RE.findall(text):
                target = target.strip()
                if not os.path.exists(target):
                    continue
                width_mm, height_mm = dims_from_opts(opts)
                old_w, old_h = seen.get(target, (None, None))
                seen[target] = (
                    max([v for v in (old_w, width_mm) if v] or [None]),
                    max([v for v in (old_h, height_mm) if v] or [None]),
                )
    return seen


def effective_dpi(px_w, px_h, width_mm, height_mm):
    """按实际缩放比例算有效 DPI（keepaspectratio 时取较大的那个方向）。"""
    ratios = []
    if width_mm:
        ratios.append(px_w / (width_mm / 25.4))
    if height_mm:
        ratios.append(px_h / (height_mm / 25.4))
    return max(ratios) if ratios else None


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)
    figs = collect(".")
    rows = []
    for path, (width_mm, height_mm) in figs.items():
        try:
            with Image.open(path) as im:
                px_w, px_h = im.size
        except Exception:
            continue
        size_mb = os.path.getsize(path) / 1048576
        rows.append((path, px_w, px_h, size_mb, width_mm, height_mm,
                     effective_dpi(px_w, px_h, width_mm, height_mm)))

    rows.sort(key=lambda r: -(r[6] or 0))
    over = [r for r in rows if r[6] and r[6] > 400]
    print(f"引用图片 {len(rows)} 张，合计 {sum(r[3] for r in rows):.1f} MB")
    print(f"有效 DPI > 400 的图片：{len(over)} 张，占 {sum(r[3] for r in over):.1f} MB")
    print("\n前 25 张（按有效 DPI）:")
    print(f"{'DPI':>6} {'像素':>14} {'MB':>6}  path")
    for path, px_w, px_h, size_mb, width_mm, height_mm, dpi in rows[:25]:
        print(f"{(dpi or 0):6.0f} {px_w}x{px_h:<8} {size_mb:6.1f}  {path}")

    buckets = Counter()
    for r in rows:
        d = r[6] or 0
        if d > 1200:
            buckets[">1200"] += 1
        elif d > 900:
            buckets["900-1200"] += 1
        elif d > 600:
            buckets["600-900"] += 1
        elif d > 400:
            buckets["400-600"] += 1
        elif d > 300:
            buckets["300-400"] += 1
        else:
            buckets["<=300/尺寸未指定"] += 1
    print("\nDPI 分布:", dict(buckets))


if __name__ == "__main__":
    main()
