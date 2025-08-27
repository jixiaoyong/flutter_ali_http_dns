# HTTP/2 安全连接支持

## 概述

Flutter Ali HttpDNS 插件现在支持配置HTTP/2连接的安全级别，可以处理只支持HTTP的服务器（如某些gRPC服务）。

## 问题背景

某些服务器（特别是gRPC服务）可能只支持HTTP而不支持HTTPS。当代理服务尝试与这些服务器建立HTTPS/TLS连接时，会导致连接失败和Stream错误。

## 解决方案

通过新增的 `isSecure` 参数，可以在注册端口映射时指定连接类型：

### 安全连接（默认）

```dart
// 对于支持HTTPS的服务器
final localPort = await FlutterAliHttpDns.instance.registerMapping(
  targetPort: 443,
  targetDomain: 'api.example.com',
  name: 'Secure API',
  isSecure: true, // 默认值，可以省略
);
```

### 不安全连接

```dart
// 对于只支持HTTP的服务器（如某些gRPC服务）
final localPort = await FlutterAliHttpDns.instance.registerMapping(
  targetPort: 7349,
  targetDomain: 'api.example.com',
  name: 'Nakama gRPC (Insecure)',
  isSecure: false, // 关键：设置为false表示使用HTTP
);
```

## 技术实现

### 1. PortMapping 模型扩展

```dart
@freezed
class PortMapping with _$PortMapping {
  const factory PortMapping({
    // ... 其他字段
    @Default(true) bool isSecure, // 新增字段
  }) = _PortMapping;
}
```

### 2. HTTP/2 处理逻辑

在 `Http2Handler` 中根据 `isSecure` 标志决定连接类型：

```dart
if (mapping.isSecure) {
  // 安全连接 - 使用默认的TLS处理
  clientTransport = ClientTransportConnection.viaSocket(targetSocket);
  Logger.debug('Using secure HTTP/2 connection (HTTPS)');
} else {
  // 不安全连接 - 使用h2c (HTTP/2 over cleartext)
  clientTransport = ClientTransportConnection.viaSocket(targetSocket);
  Logger.debug('Using insecure HTTP/2 connection (h2c)');
}
```

### 3. 头部处理

自动根据连接类型设置正确的 `:scheme` 头部：

```dart
if (name == ':scheme') {
  // 根据连接类型设置正确的scheme
  value = isSecure ? 'https' : 'http';
  Logger.debug('Modified HTTP/2 scheme header: $name = $value (secure: $isSecure)');
}
```

## 使用示例

### Nakama gRPC 服务

```dart
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

class NakamaConfig {
  static const String nakamaBaseUrl = 'api.example.com';
  static const int nakamaPortGrpc = 7349;
  
  /// 注册不安全的gRPC连接
  static Future<int?> registerInsecureGrpcMapping() async {
    return await FlutterAliHttpDns.instance.registerMapping(
      targetPort: nakamaPortGrpc,
      targetDomain: nakamaBaseUrl,
      name: 'Nakama gRPC (Insecure)',
      description: 'Nakama gRPC服务 - 不安全连接',
      isSecure: false, // 关键：设置为false
    );
  }
}
```

### 混合环境

```dart
// 同时支持安全和不安全的连接
final securePort = await FlutterAliHttpDns.instance.registerMapping(
  targetPort: 443,
  targetDomain: 'api.secure.com',
  isSecure: true,
);

final insecurePort = await FlutterAliHttpDns.instance.registerMapping(
  targetPort: 8080,
  targetDomain: 'api.insecure.com',
  isSecure: false,
);
```

## 注意事项

1. **默认行为**：`isSecure` 默认为 `true`，保持向后兼容性
2. **性能影响**：不安全连接通常比安全连接更快，但安全性较低
3. **协议兼容性**：确保目标服务器确实支持HTTP/2 over cleartext (h2c)
4. **错误处理**：连接失败时会自动清理资源并记录详细日志

## 故障排除

### 常见错误

1. **TLS握手失败**：检查目标服务器是否支持HTTPS
2. **连接被拒绝**：确认端口和域名配置正确
3. **Stream错误**：检查是否设置了正确的 `isSecure` 值

### 调试技巧

启用详细日志来查看连接过程：

```dart
FlutterAliHttpDns.setLogLevel(LogLevel.debug);
```

日志会显示：
- 连接类型（安全/不安全）
- 头部修改过程
- 错误详情

## 版本兼容性

- **新增功能**：`isSecure` 参数
- **向后兼容**：现有代码无需修改，默认使用安全连接
- **推荐升级**：对于使用不安全服务的应用，建议升级并设置 `isSecure: false`
