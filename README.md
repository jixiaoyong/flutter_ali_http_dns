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

#### Nakama场景（使用动态端口映射）

```dart
// 注册端口映射（自动分配端口）
final localPort = await dnsService.registerMapping(
  targetPort: 7350,                    // 目标端口
  targetDomain: 'api.game-service.com', // 目标域名
  name: 'Nakama HTTP',                 // 映射名称
  description: 'Nakama HTTP service',  // 描述
);

if (localPort != null) {
  print('Nakama HTTP 服务监听在端口: $localPort');
  
  // 使用映射的端口
  final client = HttpClient();
  await dnsService.configureHttpClient(client);
  final request = await client.getUrl(Uri.parse('http://localhost:$localPort'));
  
  // 移除映射
  await dnsService.removeMapping(localPort);
}
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

#### 端口映射（自动分配）
```dart
Future<int?> registerMapping({
  int? targetPort,           // 目标端口（可选）
  required String targetDomain, // 目标域名
  String? name,              // 映射名称（可选）
  String? description,       // 描述信息（可选）
})

Future<bool> removeMapping(int localPort)
Future<Map<String, dynamic>?> getMapping(int localPort)
Future<Map<String, Map<String, dynamic>>> getAllMappings()
```

#### 域名解析
```dart
Future<String> resolveDomain(String domain)
Future<void> configureHttpClient(HttpClient client)
Future<Map<String, dynamic>?> getDioProxyConfig()
```

#### 端口管理（内部使用）
```dart
Future<List<int>> getAvailablePorts()     // 获取当前监听的端口
Future<bool> registerPort(int port)       // 注册端口监听
Future<bool> deregisterPort(int port)     // 取消注册端口监听
Future<bool> isPortListening(int port)    // 检查端口是否正在监听
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
2. **自动端口分配**: 当用户调用`registerMapping`时，SDK自动查找可用端口
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
- 启动时监听一个默认端口（用于Dio等普通场景）
- 通过`registerMapping`动态添加额外端口（用于Nakama等特殊场景）
- 所有端口共享相同的代理逻辑和配置

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

### 2. Nakama游戏服务器
```dart
// 为Nakama服务注册映射
final httpPort = await dnsService.registerMapping(
  targetPort: 7350,
  targetDomain: 'api.game-service.com',
  name: 'Nakama HTTP',
);

final grpcPort = await dnsService.registerMapping(
  targetPort: 7349,
  targetDomain: 'api.game-service.com',
  name: 'Nakama gRPC',
);

// 使用映射的端口
// ... 配置Nakama客户端
```

### 3. 多服务代理
```dart
// 批量注册多个服务
final services = [
  {'name': 'API', 'port': 7350, 'domain': 'api.service.com'},
  {'name': 'Chat', 'port': 7349, 'domain': 'chat.service.com'},
  {'name': 'Auth', 'port': null, 'domain': 'auth.service.com'},
];

for (final service in services) {
  final localPort = await dnsService.registerMapping(
    targetPort: service['port'] as int?,
    targetDomain: service['domain'] as String,
    name: service['name'] as String,
  );
  print('${service['name']} 服务监听在端口: $localPort');
}
```

## 示例项目

查看 `example/` 目录获取完整的使用示例：

- **基础测试** (`basic_tests.dart`): 域名解析、HttpClient、Dio测试
- **Nakama测试** (`nakama_tests.dart`): 游戏服务器代理测试
- **端口管理测试** (`port_management_tests.dart`): 端口冲突、动态映射测试
- **高级功能测试** (`advanced_tests.dart`): 批量操作、配置选项、性能测试

## 模块化架构说明

示例项目采用模块化架构，便于维护和扩展：

```
example/lib/modules/
├── modules.dart              # 统一导出文件
├── service_manager.dart      # 服务管理器
├── basic_tests.dart          # 基础功能测试
├── nakama_tests.dart         # Nakama场景测试
├── port_management_tests.dart # 端口管理测试
├── advanced_tests.dart       # 高级功能测试
└── ui_components.dart        # UI组件
```

### 模块职责

- **ServiceManager**: 管理DNS和代理服务的初始化、启动、停止
- **BasicTests**: 处理域名解析、HttpClient、Dio等基础功能测试
- **NakamaTests**: 专门处理Nakama游戏服务器的代理测试
- **PortManagementTests**: 处理端口冲突、动态映射、端口管理等测试
- **AdvancedTests**: 处理高级功能、配置选项、性能测试等
- **UIComponents**: 提供可复用的UI组件

### 使用示例

```dart
// 在main.dart中统一管理所有模块
class _MyHomePageState extends State<MyHomePage> {
  late final ServiceManager _serviceManager;
  late final BasicTests _basicTests;
  late final NakamaTests _nakamaTests;
  late final PortManagementTests _portManagementTests;
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
A: 使用`getMainPort()`获取默认代理端口，或使用`registerMapping()`自动分配端口。

### Q: 如何处理端口冲突？
A: SDK会自动处理端口冲突，如果指定端口被占用，会自动寻找下一个可用端口。

### Q: 如何批量管理多个服务？
A: 使用循环调用`registerMapping()`方法，SDK会自动为每个服务分配可用端口。

### Q: 代理服务器会自动清理端口吗？
A: 是的，当调用`stopProxy()`时，所有动态注册的端口都会被自动清理。

### Q: 如何检查端口是否可用？
A: 使用`isPortAvailable(int port)`方法检查端口是否可用。

## 许可证

MIT License
