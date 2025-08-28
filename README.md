# Flutter Ali HTTP DNS

一个基于[阿里云HTTPDNS](https://help.aliyun.com/zh/dns/httpdns-what-is-mobile-resolution-httpdns)的Flutter插件，提供智能域名解析和代理功能，支持HTTP/1.1和HTTP/2协议。

支持解析域名对应的 IP,也支持代理网络请求并解析域名。

网络请求示意图：

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Flutter App                                        │
│                                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │   Dio       │  │ HttpClient  │  │ WebSocket   │  │   Other     │           │
│  │  Client     │  │             │  │             │  │  Clients    │           │
│  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘           │
│        │                │                │                │                   │
│        └────────────────┼────────────────┼────────────────┘                   │
│                         │                │                                    │
│                         ▼                ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Local Proxy Server (localhost:4041)                      │ │
│  │                                                                             │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │ │
│  │  │   Request       │    │   DNS Resolver  │    │   Response      │        │ │
│  │  │   Parser        │    │                 │    │   Forwarder     │        │ │
│  │  │                 │    │  ┌─────────────┐ │    │                 │        │ │
│  │  │ • 解析请求协议   │    │  │   Cache     │ │    │ • 转发响应      │        │ │
│  │  │ • 提取域名端口   │    │  │             │ │    │ • 错误处理      │        │ │
│  │  │ • 识别协议类型   │    │  │ • IP缓存    │ │    │ • 日志记录      │        │ │
│  │  └─────┬───────────┘    │  │ • TTL管理   │ │    └─────────────────┘        │ │
│  │        │                │  └─────┬───────┘ │                               │ │
│  │        ▼                │        ▼         │                               │ │
│  │  ┌─────────────────┐    │  ┌─────────────┐ │    ┌─────────────────┐        │ │
│  │  │   Protocol      │    │  │ HTTPDNS     │ │    │   Connection     │        │ │
│  │  │   Detector      │    │  │ Resolver    │ │    │   Manager        │        │ │
│  │  │                 │    │  │             │ │    │                 │        │ │
│  │  │ • HTTP/1.1      │    │  │ • 阿里云    │ │    │ • 连接池管理     │        │ │
│  │  │ • HTTP/2        │    │  │   HTTPDNS   │ │    │ • 连接复用       │        │ │
│  │  │ • HTTPS         │    │  │ • 系统DNS   │ │    │ • 错误重试       │        │ │
│  │  │ • WebSocket     │    │  │   回退      │ │    │ • 超时处理       │        │ │
│  │  └─────────────────┘    │  └─────────────┘ │    └─────────────────┘        │ │
│  └─────────────────────────┼──────────────────┘                               │ │
│                            │                                                  │ │
│                            ▼                                                  │ │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Target Server Connection                                │ │
│  │                                                                             │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │ │
│  │  │   Socket        │    │   Request       │    │   Response      │        │ │
│  │  │   Connection    │    │   Forwarding    │    │   Processing    │        │ │
│  │  │                 │    │                 │    │                 │        │ │
│  │  │ • 连接目标IP     │    │ • 修改Host头    │    │ • 接收响应       │        │ │
│  │  │ • 处理连接错误   │    │ • 转发原始请求   │    │ • 解析响应头     │        │ │
│  │  │ • 重试机制      │    │ • 保持请求头     │    │ • 转发给客户端   │        │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Internet                                           │
│                                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │   阿里云    │  │   目标      │  │   目标      │  │   目标      │           │
│  │  HTTPDNS    │  │   服务器1   │  │   服务器2   │  │   服务器N   │           │
│  │   服务      │  │   (API)     │  │   (CDN)     │  │   (静态)    │           │
│  │             │  │             │  │             │  │             │           │
│  │ • 域名解析   │  │ • 业务逻辑   │  │ • 内容分发   │  │ • 静态资源   │           │
│  │ • IP优化    │  │ • 数据处理   │  │ • 媒体流     │  │ • 图片文件   │           │
│  │ • 负载均衡   │  │ • 响应生成   │  │ • 缓存压缩   │  │ • CSS/JS    │           │
│  │ • 故障转移   │  │ • 数据库查询 │  │ • 边缘计算   │  │ • 文档下载   │           │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────────────────────────────────────────┘
```

<details>
<summary><strong>📋 详细流程说明（点击展开）</strong></summary>

### 1. **应用层请求**
- Flutter应用中的各种HTTP客户端（Dio、HttpClient、WebSocket等）发起网络请求
- 请求被配置为通过本地代理服务器（localhost:4041）

### 2. **代理服务器处理**
- **请求解析器**：解析HTTP/HTTPS/WebSocket请求，提取目标域名和端口
- **协议检测器**：自动识别请求协议类型（HTTP/1.1、HTTP/2、HTTPS、WebSocket）
- **DNS解析器**：使用阿里云HTTPDNS服务解析域名对应的IP地址

### 3. **DNS解析流程**
- **缓存检查**：首先检查本地缓存中是否有有效的IP地址
- **HTTPDNS解析**：调用阿里云HTTPDNS服务进行域名解析
- **系统DNS回退**：如果HTTPDNS解析失败，自动回退到系统DNS
- **结果缓存**：将解析结果缓存到本地，提升后续请求速度

### 4. **目标服务器连接**
- **Socket连接**：使用解析得到的IP地址建立到目标服务器的连接
- **请求转发**：修改请求头中的Host信息，转发原始请求到目标服务器
- **响应处理**：接收目标服务器的响应，转发回客户端

### 5. **连接管理**
- **连接池**：管理Socket连接，支持连接复用
- **错误处理**：处理网络错误、超时、重试等异常情况
- **日志记录**：记录详细的请求处理日志，便于调试和监控

### 6. **性能优化**
- **智能缓存**：DNS解析结果缓存，减少重复解析
- **连接复用**：复用Socket连接，减少连接建立开销
- **协议优化**：支持HTTP/2协议，提升传输效率
- **负载均衡**：利用阿里云HTTPDNS的负载均衡能力

</details>

## 功能特性

- **HTTPDNS解析**: 通过阿里云HTTPDNS服务解析域名，提升解析速度和准确性
- **智能代理**: 自动启动本地代理服务器，支持HTTP/1.1和HTTP/2协议
- **端口管理**: 智能端口分配和冲突处理，无需手动管理
- **多客户端支持**: 完美支持Dio、HttpClient等主流HTTP客户端
- **缓存优化**: 内置DNS缓存机制，提升性能
- **错误处理**: 完善的错误处理和回退机制

## 快速开始

### 1. 添加依赖

#### 方式一：GitHub 依赖（推荐）

```yaml
dependencies:
  flutter_ali_http_dns:
    git:
      url: https://github.com/jixiaoyong/flutter_ali_http_dns
      ref: master  # 或指定版本标签，如 v0.0.1
```

#### 方式二：pub.dev 依赖（TODO：待发布到 pub.dev）

```yaml
# TODO: 插件发布到 pub.dev 后使用此方式
dependencies:
  flutter_ali_http_dns: ^0.0.1
```

### 2. 插件生命周期管理

#### 最佳实践：启动时机和关闭时机

插件应该在**用户同意隐私协议之后，第一次请求网络之前**进行初始化, 在应用不再使用或退出时调用 `dispose()` 方法：

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FlutterAliHttpDns _dnsService;
  bool _isPrivacyAccepted = false;

  @override
  void initState() {
    super.initState();
    _dnsService = FlutterAliHttpDns();
  }

  /// 用户同意隐私协议后初始化插件
  Future<void> _initializeAfterPrivacyAccept() async {
    if (_isPrivacyAccepted) {
      await _dnsService.initialize(DnsConfig(
        accountId: 'your_account_id',
        accessKeyId: 'your_access_key_id',
        accessKeySecret: 'your_access_key_secret',
      ));
      print('DNS服务初始化完成');
    }
  }

  @override
  void dispose() {
    // 应用退出时清理资源
    _dnsService.dispose();
    super.dispose();
  }
}
```


### 3. 最简单的用法

#### 仅域名解析（无需代理）

如果只需要域名解析功能，不需要代理服务器：

```dart
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

// 1. 初始化DNS服务
final dnsService = FlutterAliHttpDns();
await dnsService.initialize(DnsConfig(
  accountId: 'your_account_id',
  accessKeyId: 'your_access_key_id',
  accessKeySecret: 'your_access_key_secret',
));

// 2. 解析域名（无需启动代理）
final ip = await dnsService.resolveDomain('www.example.com');
print('解析结果: $ip');

// 3. 应用退出时清理资源
@override
void dispose() {
  dnsService.dispose();
  super.dispose();
}
```

#### 使用代理进行HTTP请求

```dart
// 1. 启动代理服务器（仅在需要代理时启动）
await dnsService.startProxy();

// 2. 配置HttpClient使用代理
final client = HttpClient();
await dnsService.configureHttpClient(client);

// 3. 发起请求
final request = await client.getUrl(Uri.parse('https://www.example.com'));
final response = await request.close();

// 4. 如果不再需要代理，可以停止代理服务器
// await dnsService.stopProxy();
```

## 进阶用法

### 1. 配置Dio客户端

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

// 启动代理
await dnsService.startProxy();

// 配置Dio使用代理
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

### 2. 自定义代理配置

SDK 会在本地启动一个代理服务器，转发网络请求，你可以配置这个代理服务器的端口范围，SDK 会优先遵循，但是如果指定限制下无法找到可用端口，也可能突破这个限制。

```dart
// 自定义端口池和端口范围
final proxyConfig = ProxyConfig(
  portPool: [4041, 4042, 4043],  // 优先使用的端口
  startPort: 4044,               // 自动分配起始端口
  endPort: 4050,                 // 自动分配结束端口
  enabled: true,
  host: 'localhost',
);

await dnsService.startProxy(proxyConfig);
```

### 3. 高级DNS配置

配置属性参考[云解析DNS/解析服务/移动解析HTTPDNS/开发参考](https://help.aliyun.com/zh/dns/httpdns-development-reference)

```dart
final dnsConfig = DnsConfig(
  accountId: 'your_account_id',
  accessKeyId: 'your_access_key_id',
  accessKeySecret: 'your_access_key_secret',
  enableCache: true,           // 启用缓存
  maxCacheSize: 1000,          // 最大缓存条目数
  enableSpeedTest: true,       // 启用测速
  timeout: 5,                  // 超时时间（秒）
  enableIPv6: false,           // 是否启用IPv6
  preloadDomains: [           // 预加载域名
    'www.example.com',
    'api.example.com',
  ],
);

await dnsService.initialize(dnsConfig);
```

## 高级功能

### 1. 端口管理

```dart
// 获取当前使用的端口
final mainPort = await dnsService.getMainPort();
final allPorts = await dnsService.getActualPorts();

// 检查端口可用性
final isAvailable = await dnsService.isPortAvailable(4041);

// 获取代理地址
final proxyAddress = await dnsService.getProxyAddress();
final http2Address = await dnsService.getHttp2ProxyAddress();
```

### 2. 日志控制

```dart
// 设置日志级别
FlutterAliHttpDns.setLogLevel(LogLevel.info);

// 启用/禁用日志
FlutterAliHttpDns.setLogEnabled(true);
```

### 3. 代理状态管理

```dart
// 检查代理状态
final isRunning = dnsService.isProxyRunning;
final isInitialized = dnsService.isInitialized;

// 停止代理
await dnsService.stopProxy();

// 检查代理状态
final status = await dnsService.checkProxyStatus();
```

### 4. 生命周期管理

#### 完整的应用生命周期示例

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FlutterAliHttpDns _dnsService;
  bool _isInitialized = false;
  bool _isProxyRunning = false;

  @override
  void initState() {
    super.initState();
    _dnsService = FlutterAliHttpDns();
  }

  /// 初始化DNS服务（在用户同意隐私协议后调用）
  Future<void> _initializeDns() async {
    try {
      final success = await _dnsService.initialize(DnsConfig(
        accountId: 'your_account_id',
        accessKeyId: 'your_access_key_id',
        accessKeySecret: 'your_access_key_secret',
      ));
      
      if (success) {
        setState(() => _isInitialized = true);
        print('DNS服务初始化成功');
      }
    } catch (e) {
      print('DNS服务初始化失败: $e');
    }
  }

  /// 启动代理服务器（仅在需要代理时调用）
  Future<void> _startProxy() async {
    if (!_isInitialized) {
      print('请先初始化DNS服务');
      return;
    }

    try {
      final success = await _dnsService.startProxy();
      if (success) {
        setState(() => _isProxyRunning = true);
        print('代理服务器启动成功');
      }
    } catch (e) {
      print('代理服务器启动失败: $e');
    }
  }

  /// 停止代理服务器
  Future<void> _stopProxy() async {
    try {
      await _dnsService.stopProxy();
      setState(() => _isProxyRunning = false);
      print('代理服务器已停止');
    } catch (e) {
      print('停止代理服务器失败: $e');
    }
  }

  @override
  void dispose() {
    // 应用退出时清理所有资源
    _dnsService.dispose();
    super.dispose();
  }
}
```

#### 按需启动代理

```dart
class NetworkService {
  final FlutterAliHttpDns _dnsService = FlutterAliHttpDns();
  bool _isProxyStarted = false;

  /// 初始化DNS服务
  Future<void> initialize() async {
    await _dnsService.initialize(DnsConfig(
      accountId: 'your_account_id',
      accessKeyId: 'your_access_key_id',
      accessKeySecret: 'your_access_key_secret',
    ));
  }

  /// 按需启动代理（仅在需要代理时调用）
  Future<void> _ensureProxyStarted() async {
    if (!_isProxyStarted) {
      await _dnsService.startProxy();
      _isProxyStarted = true;
    }
  }

  /// 使用代理发起HTTP请求
  Future<void> makeHttpRequest() async {
    await _ensureProxyStarted(); // 按需启动代理
    
    final client = HttpClient();
    await _dnsService.configureHttpClient(client);
    
    // 发起请求...
  }

  /// 仅解析域名（无需代理）
  Future<String> resolveDomain(String domain) async {
    return await _dnsService.resolveDomain(domain);
  }

  /// 清理资源
  void dispose() {
    _dnsService.dispose();
  }
}
```

### 5. 批量域名解析（无需代理）

```dart
// 批量解析域名，无需启动代理服务器
final domains = ['www.taobao.com', 'www.douyin.com', 'www.baidu.com'];
final results = <String, String>{};

for (final domain in domains) {
  try {
    final ip = await dnsService.resolveDomain(domain);
    results[domain] = ip;
    print('$domain -> $ip');
  } catch (e) {
    print('解析失败: $domain - $e');
  }
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
| `maxCacheSize` | `int` | `100` | 最大缓存大小 |
| `enableSpeedTest` | `bool` | `true` | 是否启用速度测试 |
| `timeout` | `int` | `3` | 超时时间（秒） |
| `enableIPv6` | `bool` | `false` | 是否启用IPv6 |
| `preloadDomains` | `List<String>` | `[]` | 预加载域名列表 |

### 代理配置 (ProxyConfig)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `portPool` | `List<int>?` | `null` | 端口池（优先使用的端口列表） |
| `startPort` | `int?` | `4041` | 自动分配的起始端口 |
| `endPort` | `int?` | `startPort + 100` | 自动分配的结束端口 |
| `enabled` | `bool` | `true` | 是否启用代理 |
| `host` | `String` | `'localhost'` | 代理主机 |

### 核心方法

#### 初始化和配置
```dart
Future<bool> initialize(DnsConfig config)
Future<bool> startProxy([ProxyConfig? config])
Future<bool> stopProxy()
```

#### 域名解析
```dart
Future<String> resolveDomain(String domain, {bool enableSystemDnsFallback = true})
Future<String?> resolveDomainNullable(String domain, {bool enableSystemDnsFallback = true})
```

#### 代理管理
```dart
Future<String?> getProxyAddress()
Future<String?> getHttp2ProxyAddress()
Future<Map<String, dynamic>?> getDioProxyConfig()
Future<bool> checkProxyStatus()
```

#### 端口管理
```dart
Future<int?> getMainPort()
Future<List<int>> getActualPorts()
Future<bool> isPortAvailable(int port)
```

#### 客户端配置
```dart
Future<void> configureHttpClient(HttpClient client)
```

## 工作原理

### 1. 插件生命周期

1. **初始化阶段**: 调用`initialize()`方法，配置DNS服务
2. **域名解析**: 可以直接使用`resolveDomain()`进行域名解析，无需代理
3. **代理启动**: 按需调用`startProxy()`启动代理服务器
4. **资源清理**: 调用`dispose()`清理所有资源

### 2. DNS解析流程

1. **HTTPDNS解析**: 优先使用阿里云HTTPDNS服务解析域名
2. **系统DNS回退**: 如果HTTPDNS解析失败，自动回退到系统DNS
3. **缓存机制**: 解析结果会被缓存，提升后续请求速度

### 3. 代理服务器

1. **按需启动**: 仅在需要代理HTTP请求时才启动代理服务器
2. **端口分配**: 智能分配可用端口，自动处理端口冲突
3. **协议支持**: 支持HTTP/1.1和HTTP/2协议
4. **请求转发**: 将客户端请求转发到目标服务器

### 3. 端口分配策略

1. **优先级1**: 使用配置的端口池中的端口
2. **优先级2**: 使用配置的端口范围（startPort到endPort）
3. **优先级3**: 自动寻找可用端口（突破配置范围）
4. **冲突处理**: 自动处理端口冲突

## 使用场景

### 1. 移动应用网络优化
- 提升域名解析速度
- 减少网络延迟
- 提高应用响应速度

### 2. 多端统一网络处理
- 统一Android和iOS的网络处理逻辑
- 简化网络配置管理

### 3. 网络调试和测试
- 本地代理便于网络调试
- 支持多种HTTP客户端

## 示例项目

查看 `example/` 目录获取完整的使用示例：

- **基础测试** (`basic_tests.dart`): 域名解析、HttpClient、Dio测试
- **HTTP/2测试** (`http2_tests.dart`): HTTP/2协议支持测试
- **高级功能测试** (`advanced_tests.dart`): 性能测试、错误处理测试

### 运行示例

```bash
cd example
flutter pub get
flutter run
```

### 示例项目依赖说明

示例项目使用 `path: ../` 依赖，因为它与插件在同一仓库中。如果您在自己的项目中使用，请参考上面的"添加依赖"部分，使用 GitHub 依赖方式。

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

### Q: 支持哪些HTTP客户端？
A: 支持Dio、HttpClient等主流HTTP客户端，也可以自定义配置其他客户端。

### Q: 什么时候应该初始化插件？
A: 建议在用户同意隐私协议之后，第一次请求网络之前进行初始化。这样可以确保在用户同意的情况下才开始网络活动。

### Q: 什么时候应该启动代理服务器？
A: 代理服务器应该按需启动。如果只需要域名解析功能，无需启动代理；只有在需要代理HTTP请求时才启动代理服务器。

### Q: 什么时候应该调用dispose()？
A: 在应用退出或不再使用插件时调用dispose()方法，它会自动停止代理服务器并清理所有资源。

### Q: 如果只做域名解析，需要启动代理吗？
A: 不需要。域名解析功能不需要代理服务器，只有HTTP请求代理才需要启动代理服务器。

## 开发指南

### Git Hooks 设置

项目包含自动版本号同步的 Git hooks，确保 `pubspec.yaml` 和 `README.md` 中的版本号始终保持一致。

#### 安装 Hooks

```bash
# 安装 Git hooks（首次克隆项目后运行）
./scripts/install-hooks.sh
```

#### 功能说明

- **自动检测**：当修改 `pubspec.yaml` 中的版本号时，会自动检查 `README.md` 中的版本号
- **自动同步**：如果版本号不一致，会自动同步并添加到当前提交中
- **提交保护**：如果同步失败，提交会被阻止

#### 手动运行

```bash
# 手动检查版本号同步
./scripts/sync-version.sh
```

## 许可证

MIT License
