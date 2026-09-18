#!/bin/bash

# 当前目录不是 OpenWrt 源码根目录
cd ./wrt/ 
# 1. 【关键】清理旧的 Feed 索引和临时文件，防止缓存干扰
rm -rf tmp/
rm -rf feeds/

# 2. 更新默认 feeds
echo "Updating default feeds..."
./scripts/feeds update -a

# 3. 【关键】只安装默认 feeds 中除了 xray-core 以外的包
# 先安装所有包
./scripts/feeds install -a

# 4. 手动获取最新 xray-core (覆盖默认源)
echo "Fetching latest xray-core manually..."
TMP_DIR="tmp_pw_fetch"
TARGET_DIR="package/custom/passwall_single_pkgs"

# 清理旧数据
rm -rf "$TMP_DIR" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 浅克隆 PassWall 包仓库
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git "$TMP_DIR"

# 提取 xray-core
if [ -d "$TMP_DIR/xray-core" ]; then
    cp -rf "$TMP_DIR/xray-core" "$TARGET_DIR/"
    echo "Successfully extracted xray-core to $TARGET_DIR"
    
    # 【重要】如果 xray-core 依赖 v2ray-geodata，也一起提取
    if [ -d "$TMP_DIR/v2ray-geodata" ]; then
        cp -rf "$TMP_DIR/v2ray-geodata" "$TARGET_DIR/"
        echo "Successfully extracted v2ray-geodata."
    fi
else
    echo "Error: xray-core not found!"
    exit 1
fi

# 清理临时文件
rm -rf "$TMP_DIR"

# 5. 【关键】重新生成 Package 索引，确保新包被识别且优先级正确
# 这一步会让构建系统重新扫描 package/ 目录，发现我们手动放入的新版本
./scripts/feeds update -i
./scripts/feeds install -i

echo "Environment prepared. New xray-core is now in package/custom/passwall_single_pkgs"
