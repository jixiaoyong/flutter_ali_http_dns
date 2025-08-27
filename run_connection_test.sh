#!/bin/bash

echo "🚀 启动连接协议测试脚本"
echo "================================"

# 检查Dart是否安装
if ! command -v dart &> /dev/null; then
    echo "❌ 错误: 未找到Dart命令，请先安装Dart SDK"
    exit 1
fi

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: 未找到Flutter命令，请先安装Flutter SDK"
    exit 1
fi

echo "✅ Dart版本: $(dart --version | head -n 1)"
echo "✅ Flutter版本: $(flutter --version | head -n 1)"

# 获取依赖
echo ""
echo "📦 获取项目依赖..."
flutter pub get

# 运行连接协议测试
echo ""
echo "🧪 运行连接协议测试..."
echo "目标服务器: api.example.com:7349"
echo ""

dart test_connection_protocols.dart

# 检查测试结果
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 连接协议测试完成"
else
    echo ""
    echo "❌ 连接协议测试失败"
    exit 1
fi

echo ""
echo "🎉 所有测试完成！"
