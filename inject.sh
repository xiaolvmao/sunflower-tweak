#!/bin/bash
# =====================================================================
# inject.sh — 把 SunflowerTweak.dylib 注入向日葵 IPA (TrollStore)
# 用法: ./inject.sh /path/to/向日葵-15.5.10.ipa
# 产物: SunflowerTweak_ injected.ipa (同目录)
# 依赖: insert_dylib (https://github.com/Tyilo/insert_dylib)
# =====================================================================
set -e

IPA="$1"
if [ -z "$IPA" ]; then
    echo "用法: $0 <向日葵.ipa>"
    exit 1
fi

DYLIB="SunflowerTweak.dylib"
if [ ! -f "$DYLIB" ]; then
    echo "[!] 未找到 $DYLIB ，请先编译"
    exit 1
fi

WORK="$(mktemp -d)"
echo "[*] 工作目录: $WORK"
cd "$WORK"
unzip -q "$IPA" -d extracted
APP=$(find extracted -maxdepth 2 -name "*.app" -type d | head -1)
if [ -z "$APP" ]; then
    echo "[!] 未找到 .app 目录"
    exit 1
fi
echo "[*] App: $APP"

BIN=$(defaults read "$(pwd)/$APP/Info" CFBundleExecutable 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$APP/Info.plist")
echo "[*] 可执行文件: $BIN"

# 注入 dylib 到可执行文件 (加载命令 LC_LOAD_DYLIB)
cp "$OLDPWD/$DYLIB" "$APP/"
insert_dylib --inplace --weak "@executable_path/$DYLIB" "$APP/$BIN"

# 可选: 去除签名 (TrollStore 会重签, 但去掉可避免冲突)
# ldid -S "$APP/$BIN"

OUT="$(dirname "$IPA")/SunflowerTweak_injected.ipa"
cd extracted
zip -qry "$OUT" Payload
echo "[+] 完成: $OUT"
echo "[+] 请用 TrollStore 安装该 IPA"
