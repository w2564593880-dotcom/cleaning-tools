#!/usr/bin/env bash
# 编译 main.tex：xelatex -no-pdf 两遍 + xdvipdfmx 生成 PDF
# （本机 xelatex 直接写 PDF 会报 "I can't write on file main.pdf"，故拆成 xdv -> pdf）
set -u
cd "$(dirname "$0")"
date
echo "== pass 1 =="
xelatex -no-pdf -interaction=nonstopmode -file-line-error main.tex > build_pass1.log 2>&1
echo "pass1 exit=$?"
echo "== pass 2 =="
xelatex -no-pdf -interaction=nonstopmode -file-line-error main.tex > build_pass2.log 2>&1
echo "pass2 exit=$?"
echo "== xdvipdfmx =="
xdvipdfmx -q main.xdv > build_xdvipdfmx.log 2>&1
echo "xdv exit=$?"
ls -la main.pdf
date
