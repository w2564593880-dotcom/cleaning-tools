#!/usr/bin/env bash
# 快速编译脚本（xbatch: 本机 xelatex 直接写 main.pdf 会被占用/锁住，故统一走 xdv -> pdf）
#
# 用法：
#   ./build-fast.sh            日常改文字：1 遍排版 + 1 次生成 PDF（最快出成品）
#   ./build-fast.sh --two-pass 目录/交叉引用/页码有变化：2 遍排版 + 1 次生成 PDF
#   ./build-fast.sh --draft    只查错别字和排版：插图只画方框，10~20 秒
#   ./build-fast.sh --final    定稿：2 遍排版 + 最高压缩（PDF 最小）
#
# 说明：
#   * 中间那几遍用 -no-pdf，只有最后一遍才真正写 PDF。
#     你这篇文档 256 页、插图 145 MB，写一次 PDF 约 3 分钟，排版一遍只要 13 秒，
#     所以“xelatex 连跑 3 遍”等于把最贵的一步重复了 3 次。
#   * -z 1 是 xdvipdfmx 的 zlib 压缩级别，默认 9。级别 1 生成的 PDF 约大 20%，
#     但耗时从 183 秒降到 50 秒；定稿再用 -z 9 换取最小体积。
set -u
cd "$(dirname "$0")"

MODE="${1:-fast}"
TEX="xelatex -no-pdf -interaction=nonstopmode -file-line-error"
XDV="xdvipdfmx -q"

run_pass() { # $1=log, $2...=extra args
    local log="$1"; shift
    local t0; t0=$(date +%s)
    if ! $TEX "$@" main.tex > "$log" 2>&1; then
        echo "!! 排版失败，错误如下（完整日志：$log）："
        grep -n -A3 '^!\|:[0-9]*: ' "$log" | head -40
        exit 1
    fi
    echo "   pass ok ($(( $(date +%s) - t0 ))s) -> $log"
}

case "$MODE" in
--draft)
    echo "== draft（插图只画方框，不生成正式 PDF）=="
    t0=$(date +%s)
    $TEX -jobname=main-draft "\PassOptionsToPackage{draft}{graphicx}\input{main.tex}" > build_draft.log 2>&1 \
        || { grep -n -A3 '^!' build_draft.log | head -40; exit 1; }
    if $XDV -z 1 -o main-draft.pdf main-draft.xdv; then
        echo "== done: main-draft.pdf（$(( $(date +%s) - t0 ))s，仅供校对，不要交付）=="
    fi
    ;;
--two-pass)
    echo "== pass 1/2 =="; run_pass build_pass1.log
    echo "== pass 2/2 =="; run_pass build_pass2.log
    t0=$(date +%s); $XDV -z 1 -o main.pdf main.xdv && \
        echo "== done: main.pdf（PDF 用 $(( $(date +%s) - t0 ))s）=="
    ;;
--final)
    echo "== pass 1/2 =="; run_pass build_pass1.log
    echo "== pass 2/2 =="; run_pass build_pass2.log
    t0=$(date +%s); $XDV -z 9 -o main.pdf main.xdv && \
        echo "== done: main.pdf（PDF 用 $(( $(date +%s) - t0 ))s，-z 9）=="
    ;;
fast|"")
    echo "== 单遍排版 =="; run_pass build.log
    t0=$(date +%s); $XDV -z 1 -o main.pdf main.xdv && \
        echo "== done: main.pdf（PDF 用 $(( $(date +%s) - t0 ))s）=="
    echo "提示：若目录、交叉引用、页码没更新，改用 ./build-fast.sh --two-pass"
    ;;
*)
    echo "未知参数：$MODE（可用：--draft / (空) / --two-pass / --final）"; exit 2
    ;;
esac

ls -la main.pdf 2>/dev/null || true
