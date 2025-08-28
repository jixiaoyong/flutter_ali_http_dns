#!/bin/bash

# Git Hooks 安装脚本
# 用于在项目克隆后安装必要的 Git hooks

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 安装 Git Hooks...${NC}"

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# 检查是否在 Git 仓库中
if [ ! -d "$HOOKS_DIR" ]; then
    echo -e "${YELLOW}⚠️  警告: 未找到 .git/hooks 目录，请确保在 Git 仓库中运行此脚本${NC}"
    exit 1
fi

# 设置脚本执行权限
echo "📝 设置脚本执行权限..."
chmod +x "$PROJECT_ROOT/scripts/sync-version.sh"
chmod +x "$PROJECT_ROOT/scripts/install-hooks.sh"

# 检查 pre-commit hook 是否已存在
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    echo -e "${YELLOW}⚠️  pre-commit hook 已存在，跳过安装${NC}"
else
    echo "🔗 创建 pre-commit hook..."
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Git Pre-commit Hook
# 在提交前自动检查并同步版本号

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SYNC_SCRIPT="$PROJECT_ROOT/scripts/sync-version.sh"

# 检查是否修改了 pubspec.yaml
if git diff --cached --name-only | grep -q "pubspec.yaml"; then
    echo "🔍 检测到 pubspec.yaml 变更，检查版本号同步..."
    
    # 检查同步脚本是否存在
    if [ ! -f "$SYNC_SCRIPT" ]; then
        echo "❌ 错误: 版本同步脚本不存在: $SYNC_SCRIPT"
        exit 1
    fi
    
    # 检查脚本是否可执行
    if [ ! -x "$SYNC_SCRIPT" ]; then
        echo "🔧 设置脚本执行权限..."
        chmod +x "$SYNC_SCRIPT"
    fi
    
    # 运行版本同步脚本
    if "$SYNC_SCRIPT"; then
        echo "✅ 版本号检查完成"
    else
        echo "❌ 版本号同步失败，提交被阻止"
        exit 1
    fi
else
    echo "ℹ️  未检测到 pubspec.yaml 变更，跳过版本号检查"
fi

exit 0
EOF

    chmod +x "$HOOKS_DIR/pre-commit"
    echo -e "${GREEN}✅ pre-commit hook 安装完成${NC}"
fi

echo -e "${GREEN}🎉 Git Hooks 安装完成！${NC}"
echo ""
echo "📋 功能说明："
echo "   • 当修改 pubspec.yaml 中的版本号时，会自动检查 README.md 中的版本号"
echo "   • 如果版本号不一致，会自动同步并添加到当前提交中"
echo "   • 如果同步失败，提交会被阻止"
echo ""
echo "🔧 手动运行版本同步："
echo "   ./scripts/sync-version.sh"
