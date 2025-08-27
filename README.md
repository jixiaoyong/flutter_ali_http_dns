# Flutter Ali HTTP DNS

一个基于阿里云HTTPDNS的Flutter插件，提供智能域名解析和代理功能。

## 功能特性

- **HTTPDNS解析**: 通过阿里云HTTPDNS服务解析域名
- **智能端口分配**: 支持端口池和动态端口分配
- **多端口监听**: 可以同时监听多个端口
- **代理转发**: 将HTTP/HTTPS请求转发到目标服务器
- **动态端口映射**: 自动分配端口，无需手动管理
- **自动端口管理**: SDK内部自动处理端口分配和冲突

## 快速开始

### 1. 添加依赖

```yaml
dependencies:
  flutter_ali_http_dns: ^1.0.0
```

### 2. 初始化DNS服务

```dart
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

// 初始化DNS配置
final dnsConfig = DnsConfig(
  accountId: 'your_account_id',
  accessKeyId: 'your_access_key_id',
  accessKeySecret: 'your_access_key_secret',
  enableCache: true,
  maxCacheSize: 1000,
  enableSpeedTest: true,
  timeout: 5,
);

final dnsService = FlutterAliHttpDns();
await dnsService.initialize(dnsConfig);
```

### 3. 启动代理服务器

```dart
// 配置代理服务器
final proxyConfig = ProxyConfig(
  portPool: [4041, 4042, 4043],  // 端口池
  startPort: 4044,               // 起始端口
  endPort: 4050,                 // 结束端口
  enabled: true,                 // 启用代理
  host: 'localhost',             // 代理主机
);

// 启动默认代理（用于Dio等普通场景）
await dnsService.startProxy(proxyConfig);

// 获取默认端口
final mainPort = await dnsService.getMainPort(); // 4041
```

### 4. 使用代理

#### Dio场景（使用默认代理）

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

final dio = Dio();
final proxyConfig = await dnsService.getDioProxyConfig();

if (proxyConfig != null) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) => 'PROXY ${proxyConfig['host']}:${proxyConfig['port']}';
      return client;
    },
  );
}

// 发起请求
final response = await dio.get('https://www.example.com');
```

#### 基本代理场景

```dart
// 启动代理服务器
await dnsService.startProxy();

// 获取代理地址
final proxyAddress = await dnsService.getProxyAddress();
print('代理服务器地址: $proxyAddress');

// 配置HttpClient使用代理
final client = HttpClient();
await dnsService.configureHttpClient(client);

// 发起请求
final request = await client.getUrl(Uri.parse('https://www.example.com'));
final response = await request.close();
```

## API 参考

### DNS配置 (DnsConfig)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `accountId` | `String` | - | 阿里云账号ID |
| `accessKeyId` | `String` | - | 访问密钥ID |
| `accessKeySecret` | `String` | - | 访问密钥Secret |
| `enableCache` | `bool` | `true` | 是否启用缓存 |
| `maxCacheSize` | `int` | `1000` | 最大缓存大小 |
| `enableSpeedTest` | `bool` | `true` | 是否启用速度测试 |
| `timeout` | `int` | `5` | 超时时间（秒） |

### 代理配置 (ProxyConfig)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `portPool` | `List<int>?` | `null` | 端口池（优先使用的端口列表） |
| `startPort` | `int?` | `4041` | 自动分配的起始端口 |
| `endPort` | `int?` | `startPort + 100` | 自动分配的结束端口（必须大于startPort） |
| `enabled` | `bool` | `true` | 是否启用代理 |
| `host` | `String` | `'localhost'` | 代理主机 |

### 核心方法

#### 初始化
```dart
Future<bool> initialize(DnsConfig config)
```

#### 代理管理
```dart
Future<bool> startProxy(ProxyConfig config)
Future<bool> stopProxy()
Future<bool> checkProxyStatus()
Future<int> getMainPort()
```

#### 代理管理
```dart
Future<String?> getProxyAddress()
Future<String?> getHttp2ProxyAddress()
Future<List<String>> getAllProxyAddresses()
Future<String?> getProxyConfigString()
Future<Map<String, dynamic>?> getDioProxyConfig()
```

#### 域名解析
```dart
Future<String> resolveDomain(String domain)
Future<void> configureHttpClient(HttpClient client)
Future<Map<String, dynamic>?> getDioProxyConfig()
```

#### 端口管理
```dart
Future<List<int>> getActualPorts()        // 获取实际使用的端口
Future<int?> getMainPort()                // 获取主要端口
Future<List<int>> getAvailablePorts()     // 获取当前监听的端口
Future<bool> registerPort(int port)       // 注册端口监听
Future<bool> deregisterPort(int port)     // 取消注册端口监听
Future<bool> isPortListening(int port)    // 检查端口是否正在监听
Future<bool> isPortAvailable(int port)    // 检查端口是否可用
```

#### 工具方法
```dart
Future<bool> isPortAvailable(int port)
Future<Map<String, dynamic>> getPortInfo(int port)
Future<bool> isPortUsedByOwnApp(int port)
Future<String> getProxyConfigString()
```

## 智能代理工作原理

1. **默认代理启动**: SDK启动时创建一个默认代理服务器，监听一个可用端口
2. **自动端口分配**: SDK自动查找可用端口并启动代理服务
3. **动态端口管理**: 端口分配、监听、清理都由SDK内部管理
4. **智能冲突处理**: 自动处理端口冲突，确保服务稳定运行

### 端口分配策略

1. **优先级1**: 使用配置的端口池中的端口
2. **优先级2**: 使用配置的端口范围（startPort到endPort）
3. **优先级3**: 如果指定范围不足，自动突破范围寻找可用端口
   - 向上突破：endPort+1 到 endPort+100
   - 向下突破：startPort-1 到 startPort-100
4. **冲突处理**: 如果端口被占用，自动寻找下一个可用端口

### 代理模式

当前SDK采用**单端口默认模式**：
- 启动时监听一个默认端口（用于HttpClient、Dio等场景）
- 支持HTTP/2协议
- 所有请求共享相同的代理逻辑和配置

## 使用场景

### 1. Dio HTTP客户端
```dart
// 启动默认代理
await dnsService.startProxy(proxyConfig);

// 配置Dio使用代理
final dio = Dio();
final proxyConfig = await dnsService.getDioProxyConfig();
// ... 配置代理
```

### 2. HTTP/2代理
```dart
// 启动代理服务器
await dnsService.startProxy();

// 获取HTTP/2代理地址
final http2Address = await dnsService.getHttp2ProxyAddress();
print('HTTP/2代理地址: $http2Address');

// 使用HTTP/2代理
// ... 配置HTTP/2客户端
```

### 3. 多端口代理
```dart
// 启动代理服务器
await dnsService.startProxy();

// 获取所有代理地址
final allAddresses = await dnsService.getAllProxyAddresses();
print('所有代理地址: ${allAddresses.join(', ')}');

// 获取主要端口
final mainPort = await dnsService.getMainPort();
print('主要端口: $mainPort');
```

## 示例项目

查看 `example/` 目录获取完整的使用示例：

- **基础测试** (`basic_tests.dart`): 域名解析、HttpClient、Dio测试
- **HTTP/2测试** (`http2_tests.dart`): HTTP/2协议支持测试
- **高级功能测试** (`advanced_tests.dart`): 性能测试、错误处理测试

## 模块化架构说明

示例项目采用模块化架构，便于维护和扩展：

```
example/lib/modules/
├── modules.dart              # 统一导出文件
├── service_manager.dart      # 服务管理器
├── basic_tests.dart          # 基础功能测试
├── http2_tests.dart          # HTTP/2协议测试
├── http2_advanced_tests.dart # HTTP/2高级测试
├── advanced_tests.dart       # 高级功能测试
└── ui_components.dart        # UI组件
```

### 模块职责

- **ServiceManager**: 管理DNS和代理服务的初始化、启动、停止
- **BasicTests**: 处理域名解析、HttpClient、Dio等基础功能测试
- **Http2Tests**: 处理HTTP/2协议支持测试
- **Http2AdvancedTests**: 处理HTTP/2高级功能测试
- **AdvancedTests**: 处理性能测试、错误处理等高级功能
- **UIComponents**: 提供可复用的UI组件

### 使用示例

```dart
// 在main.dart中统一管理所有模块
class _MyHomePageState extends State<MyHomePage> {
  late final ServiceManager _serviceManager;
  late final BasicTests _basicTests;
  late final AdvancedTests _advancedTests;

  @override
  void initState() {
    super.initState();
    _serviceManager = ServiceManager(
      onLogMessage: _addLog,
      onResultUpdate: _updateResult,
    );
    // ... 初始化其他模块
  }
}
```

## 常见问题

### Q: 如何获取代理端口？
A: 使用`getMainPort()`获取默认代理端口，或使用`getProxyAddress()`获取代理地址。

### Q: 如何处理端口冲突？
A: SDK会自动处理端口冲突，如果指定端口被占用，会自动寻找下一个可用端口。

### Q: 如何获取HTTP/2代理地址？
A: 使用`getHttp2ProxyAddress()`获取HTTP/2代理地址。

### Q: 代理服务器会自动清理端口吗？
A: 是的，当调用`stopProxy()`时，所有端口都会被自动清理。

### Q: 如何检查端口是否可用？
A: 使用`isPortAvailable(int port)`方法检查端口是否可用。

## 许可证

MIT License
