#!/bin/bash

# 版本同步脚本
# 用于检测 pubspec.yaml 和 README.md 中的版本号是否一致

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 检查版本号同步..."

# 从 pubspec.yaml 提取版本号
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ 错误: pubspec.yaml 文件不存在${NC}"
    exit 1
fi

PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo "📦 pubspec.yaml 版本: $PUBSPEC_VERSION"

# 从 README.md 提取版本号
if [ ! -f "README.md" ]; then
    echo -e "${RED}❌ 错误: README.md 文件不存在${NC}"
    exit 1
fi

README_VERSION=$(grep -A 1 "dependencies:" README.md | grep "flutter_ali_http_dns:" | sed 's/.*flutter_ali_http_dns: \^//' | tr -d ' ')
echo "📖 README.md 版本: $README_VERSION"

# 检查版本号是否一致
if [ "$PUBSPEC_VERSION" = "$README_VERSION" ]; then
    echo -e "${GREEN}✅ 版本号已同步${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  版本号不一致，正在自动同步...${NC}"
    
    # 备份 README.md
    cp README.md README.md.backup
    
    # 更新 README.md 中的版本号
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/flutter_ali_http_dns: \^[0-9.]*/flutter_ali_http_dns: ^$PUBSPEC_VERSION/" README.md
    else
        # Linux
        sed -i "s/flutter_ali_http_dns: \^[0-9.]*/flutter_ali_http_dns: ^$PUBSPEC_VERSION/" README.md
    fi
    
    # 验证更新是否成功
    NEW_README_VERSION=$(grep -A 1 "dependencies:" README.md | grep "flutter_ali_http_dns:" | sed 's/.*flutter_ali_http_dns: \^//' | tr -d ' ')
    
    if [ "$PUBSPEC_VERSION" = "$NEW_README_VERSION" ]; then
        echo -e "${GREEN}✅ 版本号同步成功${NC}"
        echo "📝 README.md 已更新，版本号: $PUBSPEC_VERSION"
        
        # 将更新添加到当前提交
        git add README.md
        echo "📤 已将 README.md 添加到当前提交"
        
        # 清理备份文件
        rm README.md.backup
        
        exit 0
    else
        echo -e "${RED}❌ 版本号同步失败${NC}"
        # 恢复备份
        mv README.md.backup README.md
        exit 1
    fi
fi
