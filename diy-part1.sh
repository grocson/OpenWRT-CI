#!/bin/bash

# 假设当前目录已是 OpenWrt 源码根目录
cd ./wrt/ 

echo "Step 1: Update and install default feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "Step 2: Manually fetch xray-core from PassWall repo"

# 定义临时目录和目標目錄
TMP_DIR="tmp_pw_fetch"
TARGET_DIR="package/custom/passwall_single_pkgs"

# 清理旧数据
rm -rf "$TMP_DIR" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 浅克隆 PassWall 包仓库 (depth 1 节省流量和时间)
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git "$TMP_DIR"

# 提取 xray-core
if [ -d "$TMP_DIR/xray-core" ]; then
    cp -rf "$TMP_DIR/xray-core" "$TARGET_DIR/"
    echo "Successfully extracted xray-core."
    
    # 【可选】如果 xray-core 依赖 v2ray-geodata 等，也在这里提取
    # if [ -d "$TMP_DIR/v2ray-geodata" ]; then
    #     cp -rf "$TMP_DIR/v2ray-geodata" "$TARGET_DIR/"
    # fi
else
    echo "Error: xray-core not found in the repository!"
    exit 1
fi

# 清理临时克隆
rm -rf "$TMP_DIR"

echo "Step 3: Done. The build system will now detect xray-core in $TARGET_DIR"
