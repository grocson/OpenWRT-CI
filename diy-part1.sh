#!/bin/bash

# 进入 OpenWrt 源码根目录
cd ./wrt/ 

# 在 cd ./wrt/ 之后执行这行命令，给报错的脚本补加执行权限
chmod +x /mnt/build_wrt/package/network/utils/fullconenat-sonic/patches/apply-luci-feed.sh
#如果后续还可能遇到其他同类脚本权限报错，可以启用下句直接批量给所有 sh 脚本添加执行权限
#find /mnt/build_wrt/package -name "*.sh" -exec chmod +x {} \;

# 1. 全量清理所有干扰项，彻底清除旧的缓存和 feed 索引
rm -rf tmp/
rm -rf feeds/
# 额外删除任何可能残留的默认源 xray-core 相关目录
rm -rf feeds/packages/net/xray-core
rm -rf package/feeds/packages/xray-core

# 2. 更新默认 feeds
echo "Updating default feeds..."
./scripts/feeds update -a

# 3. 安装所有默认包后，立刻强制删除 feed 里的默认 xray-core
./scripts/feeds install -a
# 关键：彻底删掉 feed 生成的旧版 xray-core 软链接和目录，从索引里抹去它的存在
rm -rf feeds/packages/net/xray-core
rm -rf package/feeds/packages/xray-core
echo "Deleted default old xray-core from feeds index"

# 4. 手动拉取 PassWall 官方包仓库，提取最新版 xray-core
echo "Fetching latest xray-core manually..."
TMP_DIR="tmp_pw_fetch"
TARGET_DIR="package/custom/passwall_single_pkgs"

# 清理旧数据
rm -rf "$TMP_DIR" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 浅克隆该 PassWall 包仓库
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git "$TMP_DIR"

# 提取仓库内的 xray-core 包
if [ -d "$TMP_DIR/xray-core" ]; then
    cp -rf "$TMP_DIR/xray-core" "$TARGET_DIR/"
    echo "Successfully extracted xray-core to $TARGET_DIR"
    
    # 同步提取同仓库里 xray-core 必须的依赖 v2ray-geodata，避免后续编译缺依赖报错
    if [ -d "$TMP_DIR/v2ray-geodata" ]; then
        cp -rf "$TMP_DIR/v2ray-geodata" "$TARGET_DIR/"
        echo "Successfully extracted v2ray-geodata."
    fi
else
    echo "Error: xray-core not found in the repo!"
    exit 1
fi

# 清理临时克隆目录
rm -rf "$TMP_DIR"

# 5. 强制更新本地包索引，让系统优先识别你放入的自定义包
./scripts/feeds update -i
# 只从本地自定义目录安装新版 xray-core，完全跳过 feed 索引
./scripts/feeds install -p custom xray-core
./scripts/feeds install -p custom v2ray-geodata

# 设置 Go 代理避免编译时依赖下载失败
export GOPROXY="https://goproxy.cn,direct"
export GOFLAGS="-mod=readonly"
echo "GOPROXY=https://goproxy.cn,direct" >> $GITHUB_ENV
echo "GOFLAGS=-mod=readonly" >> $GITHUB_ENV

echo "Environment prepared. New xray-core is now the only valid version in build system"
