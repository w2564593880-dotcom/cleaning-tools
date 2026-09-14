# 9-5/8″ 井筒深度清洁关键技术升级研究及应用（结题报告 LaTeX 源码）

## 1. 编译入口

- 主文件：**`main.tex`**（务必编译它，**不要**直接编译 `chapters/chapter3/*.tex`，
  否则里面的 `figure/...` 相对路径找不到，会表现为“图片显示不出来/图丢失”）。
- 在仓库**根目录**编译：

```bash
xelatex main.tex && xelatex main.tex && xelatex main.tex   # 推荐
# 或
pdflatex main.tex && pdflatex main.tex                     # Windows 下亦可用（中文用 ctex 的 Windows 字体集）
# 或
latexmk -xelatex main.tex
```

`main.toc`/`main.aux`/交叉引用需要编译 2~3 遍才稳定。

## 2. TeXStudio 设置（老师端常见“显示不了”问题）

1. 选项 → 构建 → 默认编译器 → **XeLaTeX**，然后“构建并查看”。
   （本项目在 VS Code 中配置的是 `xelatex ×3`，见 `.vscode/settings.json`；TeXStudio 默认是 pdfLaTeX，两者都可用，但不要混用引擎编译同一份缓存。）
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
