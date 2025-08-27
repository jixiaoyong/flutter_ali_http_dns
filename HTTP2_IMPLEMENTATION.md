# HTTP/2 代理服务器实现

## 概述

本项目已经实现了基于 `http2` 库的HTTP/2代理服务器，用于处理HTTP/2协议请求，支持HTTPDNS解析和域名映射功能。

## 实现架构

### 1. 核心组件

- **Http2ProxyServer**: 专门的HTTP/2代理服务器类
- **ServerTransportConnection**: HTTP/2服务器传输连接
- **ClientTransportConnection**: HTTP/2客户端传输连接
- **StreamMessage**: HTTP/2流消息处理

### 2. 工作流程

```
客户端 (Nakama) 
    ↓ HTTP/2请求
代理服务器 (localhost:port)
    ↓ 解析并修改头部
HTTP/2服务器 (http2库)
    ↓ 转发到目标服务器
目标服务器 (api.example.com)
```

## 主要功能

### 1. HTTP/2协议支持
- 使用官方的 `http2` 库处理HTTP/2协议
- 自动处理HPACK压缩和流管理
- 支持多路复用和流优先级

### 2. 域名映射
- 支持localhost到目标域名的映射
- 动态端口映射管理
- 与现有代理服务器集成

### 3. HTTPDNS解析
- 集成阿里云HTTPDNS服务
- 自动解析域名到IP地址
- 支持缓存和错误处理

### 4. 双向数据转发
- 客户端到目标服务器的数据转发
- 目标服务器到客户端的响应转发
- 保持HTTP/2协议完整性

## API 使用

### 1. 启动HTTP/2代理服务器

```dart
// 启动代理服务器（自动包含HTTP/2支持）
final dnsService = FlutterAliHttpDns.instance;
await dnsService.startProxy();

// 获取HTTP/2代理地址
final http2Address = await dnsService.getHttp2ProxyAddress();
print('HTTP/2代理地址: $http2Address');
```

### 2. 注册端口映射

```dart
// 注册gRPC端口映射（HTTP/2）
final grpcPort = await dnsService.registerMapping(
  targetPort: 7350, // Nakama gRPC端口
  targetDomain: 'your-nakama-server.com',
  name: 'nakama-grpc',
  description: 'Nakama gRPC HTTP/2 service',
);
```

### 3. 使用HTTP/2客户端

```dart
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';

// 连接到HTTP/2代理
final socket = await Socket.connect('localhost', grpcPort);
final clientTransport = ClientTransportConnection.viaSocket(socket);

// 创建HTTP/2请求
final headers = [
  Header.ascii(':method', 'GET'),
  Header.ascii(':path', '/'),
  Header.ascii(':scheme', 'https'),
  Header.ascii(':authority', 'localhost:$grpcPort'),
];

final stream = clientTransport.makeRequest(headers, endStream: true);

// 处理响应
stream.incomingMessages.listen((message) {
  if (message is HeadersStreamMessage) {
    // 处理响应头
  } else if (message is DataStreamMessage) {
    // 处理响应数据
  }
});
```

## 测试功能

### 1. HTTP/2代理服务器测试

```dart
final http2Tests = Http2AdvancedTests(
  dnsService: dnsService,
  onLogMessage: (message) => print(message),
  onResultUpdate: (result) => print(result),
  isProxyRunning: true,
);

// 测试HTTP/2代理服务器
await http2Tests.testHttp2ProxyServer();

// 测试域名解析
await http2Tests.testHttp2DomainResolution();

// 测试端口映射
await http2Tests.testHttp2PortMapping();

// 测试性能
await http2Tests.testHttp2Performance();
```

## 配置说明

### 1. 代理配置

```dart
final proxyConfig = ProxyConfig(
  host: 'localhost',
  startPort: 4041,
  endPort: 4141,
  portPool: [4041, 4042, 4043], // 可选端口池
);
```

### 2. DNS配置

```dart
final dnsConfig = DnsConfig(
  accountId: 'your-account-id',
  accessKeyId: 'your-access-key-id',
  accessKeySecret: 'your-access-key-secret',
  enableCache: true,
);
```

## 优势

### 1. 相比手动帧解析的优势
- **更可靠**: 使用官方库，减少协议实现错误
- **更易维护**: 代码更清晰，易于理解和修改
- **更完整**: 自动处理HTTP/2的所有复杂特性
- **更高效**: 库级别的优化，性能更好

### 2. 功能特性
- **协议完整性**: 保持HTTP/2协议的所有特性
- **错误处理**: 完善的错误处理和恢复机制
- **性能优化**: 连接池和流管理优化
- **监控支持**: 详细的日志和状态监控

## 注意事项

### 1. 依赖要求
- 需要添加 `http2: ^2.3.1` 依赖
- 确保Flutter SDK版本兼容

### 2. 网络配置
- 确保防火墙允许HTTP/2端口
- 检查网络代理设置

### 3. 性能考虑
- HTTP/2连接复用可以提高性能
- 合理设置超时和重试机制

## 故障排除

### 1. 常见问题

**问题**: HTTP/2连接失败
**解决**: 检查目标服务器是否支持HTTP/2，确认端口映射正确

**问题**: 域名解析失败
**解决**: 检查HTTPDNS配置，确认网络连接正常

**问题**: 性能问题
**解决**: 检查连接池设置，优化超时配置

### 2. 调试方法

```dart
// 启用详细日志
FlutterAliHttpDns.setLogLevel(LogLevel.debug);
FlutterAliHttpDns.setLogEnabled(true);

// 检查代理状态
final isRunning = await dnsService.checkProxyStatus();
final addresses = await dnsService.getAllProxyAddresses();
```

## 未来改进

### 1. 计划功能
- HTTP/3协议支持
- 更高级的负载均衡
- 更完善的监控和指标

### 2. 性能优化
- 连接池优化
- 内存使用优化
- 并发处理优化

## 总结

新的HTTP/2实现提供了更可靠、更易维护的HTTP/2代理功能，完全替代了之前的手动帧解析方式。通过使用官方的 `http2` 库，我们获得了更好的协议支持、更完善的错误处理和更高的性能。

这个实现特别适合需要HTTP/2支持的场景，如gRPC服务、现代Web API等，同时保持了与现有HTTP/1.1代理功能的完全兼容。
