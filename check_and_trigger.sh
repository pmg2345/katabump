#!/bin/bash


echo "DEBUG: SCRIPT PATH=$(realpath "$0")"

STATE="$HOME/.katabump_last_success"
RETRY="$HOME/.katabump_need_retry"

echo "DEBUG: USING STATE=$STATE"
echo "DEBUG: USING RETRY=$RETRY"

# === 固定状态文件路径（推荐） ===
STATE="$HOME/.katabump_last_success"
RETRY="$HOME/.katabump_need_retry"

echo "=== Katabump Daily Check ==="

# 读取上次成功时间
if [ -f "$STATE" ]; then
    LAST=$(cat "$STATE")
else
    LAST=0
fi

NOW=$(date +%s)
DIFF_SEC=$((NOW - LAST))
THRESHOLD=$((4 * 86400))

echo "上次成功续期（0 点归一化）: $LAST"
echo "距离上次成功秒数: $DIFF_SEC"

# 未到 4 天且没有 retry 标记 → 跳过
if [ $DIFF_SEC -lt $THRESHOLD ] && [ ! -f "$RETRY" ]; then
    echo "未到续期周期，跳过执行。"
    exit 0
fi

echo "开始执行续期任务..."

# 执行 Node 脚本
RESULT=$(xvfb-run --auto-servernum --server-args="-screen 0 1280x720x24" node action_renew.js)

echo "$RESULT"

# 判断是否真正续期成功
if echo "$RESULT" | grep -qi '"success"[[:space:]]*:[[:space:]]*true'; then
    echo "真正续期成功！"

    # 归一化到当天 0 点
    TODAY_ZERO=$(( NOW / 86400 * 86400 ))

    echo "DEBUG: TODAY_ZERO=$TODAY_ZERO"
    echo "DEBUG: STATE FILE PATH=$STATE"

    echo $TODAY_ZERO > "$STATE"

    echo "DEBUG: Written content:"
    cat "$STATE"

    rm -f "$RETRY"
else
    echo "未续期成功（可能还没到时间）"
    touch "$RETRY"
fi

echo "=== 主任务结束 ==="
