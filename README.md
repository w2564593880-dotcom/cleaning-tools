# 9-5/8″ 井筒深度清洁关键技术升级研究及应用（结题报告 LaTeX 源码）

## 1. 编译入口

- 主文件：**`main.tex`**（务必编译它，**不要**直接编译 `chapters/chapter3/*.tex`，
  否则里面的 `figure/...` 相对路径找不到，会表现为“图片显示不出来/图丢失”）。
- 在仓库**根目录**编译：

```bash
./build-fast.sh              # 日常改完文字：约 40 秒出 main.pdf
./build-fast.sh --two-pass   # 目录/页码/交叉引用有变化时（改动较大时用它）
./build-fast.sh --draft      # 只想查错别字和排版：插图只画方框，约 15 秒
./build-fast.sh --final      # 定稿：2 遍 + 最高压缩，PDF 体积最小（约 3 分钟）
```

`main.toc`/`main.aux`/交叉引用需要编译 2 遍才稳定；不要再连跑 `xelatex ×3`，原因见第 6 节。

## 2. TeXStudio 设置（老师端常见“显示不了”问题）

1. 选项 → 构建 → 默认编译器 → **XeLaTeX**，然后“构建并查看”。
   （本项目在 VS Code 中配置的是“`xelatex -no-pdf` ×2 + `xdvipdfmx`”，见 `.vscode/settings.json`；
   TeXStudio 默认是 pdfLaTeX，两者都可用，但不要混用引擎编译同一份缓存。）
2. 若用 pdfLaTeX：请确保 TeX 发行版为**完整安装**（有 ctex 需要的中文字体）。
   Linux 需 `texlive-lang-chinese`（fandol 字体），macOS 下 ctex 会自动用系统字体。
3. **先 `git pull` 获取最新图片**，再编译；只看到旧图通常是没拉取最新提交。
4. 编译异常时先**清理辅助文件**（TeXStudio：工具 → 清理辅助文件），
   或删除 `main.aux / main.toc / main.out / main.synctex.gz` 后重新编译。
5. 参考文献在 `chapters/bib.tex` 中用 `thebibliography` 手工编写，**不需要 bibtex**；
   若 latexmk 提示找不到 `\citation`/`\bibdata`，忽略即可。

## 3. 主要宏包

ctex(ctexrep)、newtxtext、geometry、fancyhdr、hyperref、titlesec、graphicx、
booktabs、amsmath、caption、setspace、tikz、subfig、multirow、tabularx、
siunitx、gbt7714、footmisc（TeX Live 完整安装或 MiKTeX 自动安装即可）。

## 4. 图片

- 全部位于 `figure/`，`.tex` 中按**小写**书写路径，例如
  `figure/chapter3/mechanism-swiper-4-in-1.png`。
  Windows 不区分大小写，但 **Linux/macOS 区分**，请保持大小写一致。
- 支持 png / jpg / pdf。
- **插图 PDF 的生成方式很重要**：请用 Origin / MATLAB / SolidWorks 等**直接导出** PDF 或 PNG。
  不要用 “Microsoft Print to PDF” 之类的虚拟打印机生成插图 PDF——其内部 xref 表可能损坏，
  新版 pdfTeX 只会警告（`libxpdf: Illegal character ... / Couldn't read xref table`）仍能编译，
  但**较老的 TeX Live/MiKTeX 会直接报致命错误**
  （`!pdfTeX error: ... xpdf: reading PDF image failed ==> Fatal error occurred, no output PDF file produced!`），
  对方就完全看不到图、甚至生成不了 PDF。若已生成，可改用 PNG 重新导出，或用一个空文档
  `\includegraphics{旧.pdf}` 编译一遍得到“修复版”PDF。

## 5. 不要提交编译中间产物

`.gitignore` 已忽略 `main.aux/.log/.toc/.out/.synctex.gz`、`*.fls`、`latexmk.out`、
`.texpadtmp/`、`.DS_Store`、`Thumbs.db` 等。这些缓存里含**本机绝对路径**
（如 `D:/code/cleaning-tools/...`），提交后会让别人机器上的 TeXStudio 预览、
SyncTeX 正/反向定位和首次编译出现莫名其妙的错误。

`main.pdf` 作为成品仍然提交，便于直接查看；若不需要可一并加入 `.gitignore` 并 `git rm --cached main.pdf`。

## 6. 编译加速：瓶颈不在 LaTeX，在写 PDF

实测（本机，258 页、插图 145 MB）：

| 步骤 | 耗时 |
| --- | --- |
| `xelatex` 排版一遍（`-no-pdf`，只产出 `.xdv`） | 13 s |
| `xdvipdfmx` 生成 PDF（默认 `-z 9`） | 183 s |
| `xdvipdfmx -z 1` | 14~50 s（体积大约 20%） |

也就是说：**排版 13 秒，写 PDF 3 分钟**。`xelatex main.tex` 每跑一遍都会完整写一次 PDF，
所以旧的“×3 遍”配方 ≈ 10 分钟，其中 9 分钟是把同一件最贵的事重复了 3 次。两处改动：

1. **中间遍次加 `-no-pdf`，最后只写一次 PDF**——`build-fast.sh` 与 `.vscode/settings.json` 已改。
   从约 10 分钟降到约 40 秒。
2. **插图降到 300 DPI**——`tools/analyze_figures.py` 按 `\includegraphics` 的
   `width`/`height`（含 `\textwidth` 等）算出每张图在版面上的**实际** DPI，
   `tools/optimize_figures.py --apply` 把超过 300 DPI 的图等比缩到 300 DPI：

```bash
python tools/analyze_figures.py                  # 只看排名，不改文件
python tools/optimize_figures.py --dry-run       # 预览要缩哪些图
python tools/optimize_figures.py --apply         # 真改，原图备份到 figure/_orig/
python tools/optimize_figures.py --apply --target-dpi 400   # 需要更清晰时
```

已执行结果：80 张图 113 MB → 26 MB，`figure/` 166 MB → 26 MB，PDF 88 MB → 46 MB，
PDF 生成 183 s → 14 s。300 DPI 已高于印刷要求（正文插图 300 DPI 即为“照片级”）。

- 原图备份在 `figure/_orig/`（114 MB），检查 PDF 没问题后可删除：`rm -rf figure/_orig`。
- 想完全还原：`git checkout -- figure`，或把 `figure/_orig/` 里的文件拷回原位。
- 定稿若嫌 `-z 1` 的 PDF 偏大，跑 `./build-fast.sh --final`（`-z 9`，约 3 分钟）。

