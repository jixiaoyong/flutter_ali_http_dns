# flutter_ali_http_dns_example

Demonstrates how to use the flutter_ali_http_dns plugin.

## 依赖配置

### 在您自己的项目中使用

由于插件尚未发布到 pub.dev，请使用 GitHub 依赖：

```yaml
dependencies:
  flutter_ali_http_dns:
    git:
      url: https://github.com/jixiaoyong/flutter_ali_http_dns
      ref: master  # 或指定版本标签，如 v0.0.1
```

### 示例项目配置

本示例项目使用 `path: ../` 依赖，因为它与插件在同一仓库中：

```yaml
dependencies:
  flutter_ali_http_dns:
    path: ../
```

## 配置说明

在使用此示例项目之前，您需要配置阿里云 HttpDNS 的认证信息：

### 1. 创建认证配置文件

复制示例认证文件：
```bash
cp lib/credentials.example.dart lib/credentials.dart
```

### 2. 修改认证信息

编辑 `lib/credentials.dart` 文件，替换以下认证信息：

```dart
class AliHttpDnsCredentials {
  // 阿里云控制台的 Account ID
  static const String accountId = '9999'; // 替换为您的 Account ID
  
  // 阿里云 AccessKey ID
  static const String accessKeyId = 'your_access_key_id'; // 替换为您的 AccessKey ID
  
  // 阿里云 AccessKey Secret
  static const String accessKeySecret = 'your_access_key_secret'; // 替换为您的 AccessKey Secret
}
```

### 3. 其他配置（可选）

其他配置信息在 `lib/dns_config.dart` 文件中，可以根据需要修改：

```dart
class AliHttpDnsConfig {
  static const bool enableCache = true;
  static const int maxCacheSize = 100;
  // 其他配置...
}
```

### 3. 获取阿里云配置信息

1. 登录 [阿里云控制台](https://dns.console.aliyun.com/)
2. 进入 "移动解析HTTPDNS" 服务
3. 在 "接入配置" 页面获取 Account ID
4. 创建 AccessKey 并获取 AccessKey ID 和 AccessKey Secret

### 4. 安全注意事项

- `credentials.dart` 文件已添加到 `.gitignore` 中，不会被提交到版本控制
- 请确保不要将真实的认证信息提交到代码仓库
- 建议在生产环境中使用更安全的配置管理方式

## 功能演示

此示例项目演示了以下功能：

1. **DNS 初始化**：配置并初始化阿里云 HttpDNS 服务
2. **域名解析**：使用 HttpDNS 解析域名获取 IP 地址
3. **智能代理**：启动 HTTP 代理服务器，支持 Dio 和 Nakama 场景
4. **HTTP 客户端测试**：演示 HttpClient 和 Dio 的使用

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
