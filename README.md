# flutter_ali_http_dns

一个 Flutter 插件，用于集成[阿里云 HttpDNS 服务](https://help.aliyun.com/zh/dns/httpdns-what-is-mobile-resolution-httpdns)，提供域名解析和智能 HTTP 代理功能。

## 功能特性

- ✅ 阿里云 HttpDNS SDK 集成
- ✅ 域名解析功能
- ✅ 智能 HTTP 代理服务器
- ✅ 支持 HttpClient 和 Dio 集成
- ✅ 端口映射和固定域名映射
- ✅ 缓存管理
- ✅ IPv6 支持
- ✅ 测速功能
- ✅ 预加载域名
- ✅ 智能代理场景支持（Dio 场景和 Nakama 场景）
- ✅ 可控制的日志系统

## 支持的平台

- Android (API 21+)
- iOS (12.0+)

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter_ali_http_dns:
    git:
      url: https://github.com/jixiaoyong/flutter_ali_http_dns.git
      ref: master  # 或者特定的commit/tag
```

### 开发环境设置

如果您要开发或修改此插件，请按以下步骤设置开发环境：

```bash
# 1. 克隆项目
git clone https://github.com/jixiaoyong/flutter_ali_http_dns.git
cd flutter_ali_http_dns

# 2. 安装依赖
flutter pub get

# 3. 生成代码（Freezed 和 JSON 序列化）
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行测试
flutter test
```

**注意**：修改模型文件后，需要重新运行代码生成命令：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

或者使用监听模式自动生成：
```bash
flutter pub run build_runner watch
```

### iOS 配置

插件会自动处理阿里云 HttpDNS iOS SDK 的依赖，无需额外配置。

**注意**: 如果遇到编译问题，请确保您的 iOS 项目支持 CocoaPods。

## 使用方法

### 快速开始

```dart
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

void main() async {
  // 1. 初始化插件
  final dnsPlugin = FlutterAliHttpDns.instance;
  
  final dnsConfig = DnsConfig(
    accountId: 'your_account_id',
    accessKeyId: 'your_access_key_id',
    accessKeySecret: 'your_access_key_secret',
    preloadDomains: ['www.taobao.com'],
  );
  
  await dnsPlugin.initialize(dnsConfig);
  
  // 2. 域名解析
  String ip = await dnsPlugin.resolveDomain('www.taobao.com');
  print('解析结果: $ip');
  
  // 3. 启动代理（可选，用于无法直接配置代理的客户端）
  final proxyConfig = ProxyConfig(
    port: 4041,
    portMap: {'4041': 7350},
    fixedDomain: {'4041': 'api.game-service.com'},
  );
  
  await dnsPlugin.startProxy(proxyConfig);
  
  // 4. 配置 HttpClient
  final client = HttpClient();
  await dnsPlugin.configureHttpClient(client);
  
  // 5. 发送请求
  final request = await client.getUrl(Uri.parse('https://www.taobao.com'));
  final response = await request.close();
  
  // 6. 清理资源
  await dnsPlugin.dispose();
}
```

### 1. 配置阿里云 HttpDNS

在使用插件之前，您需要配置阿里云 HttpDNS 的认证信息：

```dart
// 创建认证配置文件 lib/credentials.dart
class AliHttpDnsCredentials {
  static const String accountId = 'your_account_id';
  static const String accessKeyId = 'your_access_key_id';
  static const String accessKeySecret = 'your_access_key_secret';
}

// 创建其他配置文件 lib/dns_config.dart
class AliHttpDnsConfig {
  static const bool enableCache = true;
  static const int maxCacheSize = 100;
  // 其他配置...
}

// 在 main.dart 中使用
final dnsConfig = DnsConfig(
  accountId: AliHttpDnsCredentials.accountId,
  accessKeyId: AliHttpDnsCredentials.accessKeyId,
  accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
  enableCache: AliHttpDnsConfig.enableCache,
  // 其他配置...
);
```

**注意**: 请将 `credentials.dart` 文件添加到 `.gitignore` 中，避免提交敏感信息。

### 2. 配置日志

```dart
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

// 设置日志级别
FlutterAliHttpDns.setLogLevel(LogLevel.info);

// 启用或禁用日志
FlutterAliHttpDns.setLogEnabled(true);
```

### 3. 初始化插件



### 4. 域名解析

```dart
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

final dnsPlugin = FlutterAliHttpDns.instance;

// 配置 DNS 服务
final dnsConfig = DnsConfig(
  accountId: 'your_account_id', // 阿里云控制台的 Account ID（必填）
  accessKeyId: 'your_access_key_id', // 阿里云 AccessKey ID（必填）
  accessKeySecret: 'your_access_key_secret', // 阿里云 AccessKey Secret（必填）
  enableCache: true, // 是否启用缓存，建议开启以提高解析速度
  maxCacheSize: 100, // 最大缓存大小，控制内存中缓存的域名数量
  maxNegativeCache: 30, // 最大否定缓存时间（秒），解析失败时的缓存时间
  enableIPv6: false, // 是否启用 IPv6 解析，根据网络环境选择
  enableShort: false, // 是否启用短连接，影响网络请求的连接方式
  enableSpeedTest: true, // 是否启用测速功能，自动选择最快的IP
  preloadDomains: ['www.taobao.com', 'www.douyin.com'], // 预加载域名列表，提前解析常用域名
  keepAliveDomains: [], // 缓存保持域名列表，TTL * 75%时自动更新缓存
  timeout: 3, // 超时时间（秒），DNS解析请求的超时设置
  maxCacheTTL: 3600, // 最大缓存 TTL 时间（秒），控制缓存的有效期
  ispEnable: true, // 是否启用 ISP 网络区分，根据运营商优化解析
  speedPort: 80, // 测速端口，用于IP测速的端口号
);

// 初始化
await dnsPlugin.initialize(dnsConfig);
```

### 4. 域名解析

```dart
// 解析域名
String ip = await dnsPlugin.resolveDomain('www.taobao.com');
print('解析结果: $ip');
```

### 5. 启动智能代理服务器

```dart
// 配置智能代理服务器
final proxyConfig = ProxyConfig(
  port: 4041,
  portMap: {
    '4041': 7350, // 端口映射：4041 -> 7350
    '4042': 7349, // 端口映射：4042 -> 7349
  },
  fixedDomain: {
    '4041': 'api.game-service.com',    // 游戏服务域名
    '4042': 'chat.game-service.com',   // 聊天服务域名
    '4043': 'auth.game-service.com',   // 认证服务域名
  },
  enabled: true,
  host: 'localhost',
);

// 启动代理
await dnsPlugin.startProxy(proxyConfig);
```

### 6. 智能代理场景

#### Dio 场景（普通 HTTP 请求）
对于普通的 HTTP 请求，代理会保持原始域名和端口不变：

```dart
import 'dart:io';

final client = HttpClient();
await dnsPlugin.configureHttpClient(client);

// 请求 https://www.taobao.com:443
// 代理会保持原域名和端口，只进行 DNS 解析
final request = await client.getUrl(Uri.parse('https://www.taobao.com'));
final response = await request.close();
```

#### 本地代理场景（无法直接配置代理的客户端）
对于连接到 localhost 或 127.0.0.1 的请求，代理会应用固定域名映射和端口映射。这种场景适用于无法直接配置代理的客户端或服务（如游戏服务器、第三方 SDK 等）：

```dart
// 请求 https://localhost:4041
// 代理会自动映射到固定域名和端口映射
final request = await client.getUrl(Uri.parse('https://localhost:4041'));
// 实际会连接到 api.game-service.com:7350

// 请求 https://localhost:4042  
// 实际会连接到 chat.game-service.com:7349

// 请求 https://localhost:4043
// 实际会连接到 auth.game-service.com:7348
```

#### 多域名映射规则
代理服务器根据端口号选择对应的域名：

- **端口 4041** → 使用 `4041` 对应的域名
- **端口 4042** → 使用 `4042` 对应的域名  
- **端口 4043** → 使用 `4043` 对应的域名
- **其他端口** → 使用第一个配置的域名作为默认

#### 映射机制说明
`fixedDomain` 使用端口号作为 key，实现灵活的端口到域名映射：

```dart
fixedDomain: {
  '4041': 'api.game-service.com',    // 端口 4041 映射到游戏服务
  '4042': 'chat.game-service.com',   // 端口 4042 映射到聊天服务
  '4043': 'auth.game-service.com',   // 端口 4043 映射到认证服务
  '8080': 'user-service.company.com', // 端口 8080 映射到用户服务
  '8081': 'order-service.company.com', // 端口 8081 映射到订单服务
}
```

这种设计让使用者可以完全自定义端口到域名的映射关系，而不需要修改 SDK 代码。

#### 使用场景说明

**本地代理场景的典型应用：**

1. **游戏服务器**：如 Nakama、Unity 游戏服务器等，这些服务通常无法直接配置 HTTP 代理
2. **第三方 SDK**：某些第三方 SDK 不支持代理配置，只能连接到 localhost
3. **遗留系统**：一些老旧的系统或服务无法修改代理配置
4. **嵌入式设备**：某些嵌入式设备或 IoT 设备无法配置复杂的代理设置

**工作原理：**
- 客户端连接到 `localhost:端口号`
- 代理服务器根据端口号查找对应的真实域名
- 代理服务器将请求转发到真实的服务器
- 客户端无需修改任何配置，即可享受 HTTPDNS 的优势

### 7. 配置 HttpClient

```dart
import 'dart:io';

final client = HttpClient();
await dnsPlugin.configureHttpClient(client);

// 使用 HttpClient 发送请求
final request = await client.getUrl(Uri.parse('https://www.taobao.com'));
final response = await request.close();
final responseBody = await response.transform(utf8.decoder).join();
```

### 8. 配置 Dio

```dart
import 'package:dio/dio.dart';

final dio = Dio();
final proxyConfig = await dnsPlugin.getDioProxyConfig();

if (proxyConfig != null) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) => 'PROXY ${proxyConfig['host']}:${proxyConfig['port']}';
      return client;
    },
  );
}

// 使用 Dio 发送请求
final response = await dio.get('https://www.douyin.com');
```

### 9. 多域名映射完整示例

#### 游戏服务场景（以 Nakama 为例）
```dart
// 配置多域名映射
final proxyConfig = ProxyConfig(
  port: 4041,
  portMap: {
    '4041': 7350, // 游戏服务端口
    '4042': 7349, // 聊天服务端口
    '4043': 7348, // 认证服务端口
  },
  fixedDomain: {
    '4041': 'api.game-service.com',    // 游戏服务域名
    '4042': 'chat.game-service.com',   // 聊天服务域名
    '4043': 'auth.game-service.com',   // 认证服务域名
  },
  enabled: true,
  host: 'localhost',
);
```

#### 微服务架构场景
```dart
final proxyConfig = ProxyConfig(
  port: 8080,
  portMap: {
    '8080': 80,   // 用户服务端口
    '8081': 80,   // 订单服务端口
    '8082': 80,   // 支付服务端口
    '8083': 80,   // 通知服务端口
  },
  fixedDomain: {
    '8080': 'user-service.company.com',
    '8081': 'order-service.company.com',
    '8082': 'payment-service.company.com',
    '8083': 'notification-service.company.com',
  },
  enabled: true,
  host: 'localhost',
);

// 启动代理
await dnsPlugin.startProxy(proxyConfig);

// 配置 HttpClient
final client = HttpClient();
await dnsPlugin.configureHttpClient(client);

// 使用不同端口访问不同服务
// 游戏服务
final gameRequest = await client.getUrl(Uri.parse('https://localhost:4041'));
// 实际连接到：api.game-service.com:7350

// 聊天服务  
final chatRequest = await client.getUrl(Uri.parse('https://localhost:4042'));
// 实际连接到：chat.game-service.com:7349

// 认证服务
final authRequest = await client.getUrl(Uri.parse('https://localhost:4043'));
// 实际连接到：auth.game-service.com:7348
```

### 10. 获取代理信息

```dart
// 获取代理地址
String? proxyAddress = await dnsPlugin.getProxyAddress();
print('代理地址: $proxyAddress'); // localhost:4041

// 获取代理配置字符串
String? proxyConfigString = await dnsPlugin.getProxyConfigString();
print('代理配置: $proxyConfigString'); // PROXY localhost:4041

// 检查代理状态
bool isRunning = await dnsPlugin.checkProxyStatus();
print('代理运行状态: $isRunning');
```

### 11. 停止代理服务器

```dart
await dnsPlugin.stopProxy();
```

### 12. 清理资源

```dart
await dnsPlugin.dispose();
```



## 日志系统

插件提供了可控制的日志系统，支持不同级别的日志输出：

### 日志级别

- `LogLevel.debug`: 调试信息
- `LogLevel.info`: 一般信息
- `LogLevel.warning`: 警告信息
- `LogLevel.error`: 错误信息

### 日志配置

```dart
// 设置日志级别
FlutterAliHttpDns.setLogLevel(LogLevel.info);

// 启用或禁用日志
FlutterAliHttpDns.setLogEnabled(true);
```

### 日志输出示例

```
[flutter_ali_http_dns] [2024-01-01T12:00:00.000Z] [INFO] DNS service initialized successfully
[flutter_ali_http_dns] [2024-01-01T12:00:01.000Z] [INFO] Domain resolved: www.taobao.com -> 203.119.24.0
[flutter_ali_http_dns] [2024-01-01T12:00:02.000Z] [INFO] Proxy server started successfully
```

## 智能代理工作原理

### Dio 场景
- **目标**: 保持原始域名和端口不变
- **处理**: 只进行 DNS 解析，不进行域名和端口映射
- **适用**: 普通的 HTTP/HTTPS 请求

### 本地代理场景
- **目标**: 支持无法直接配置代理的客户端
- **处理**: 
  1. 检测到 localhost 或 127.0.0.1 时，应用固定域名映射
  2. 应用端口映射配置
  3. 进行 DNS 解析
- **适用**: 游戏服务器、第三方 SDK、遗留系统等无法直接配置代理的场景

## 配置参数说明

### DnsConfig 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| accountId | String | - | 阿里云控制台的 Account ID（必填），用于标识您的账户 |
| accessKeyId | String | - | 阿里云 AccessKey ID（必填），用于身份认证 |
| accessKeySecret | String | - | 阿里云 AccessKey Secret（必填），用于身份认证 |
| enableCache | bool | true | 是否启用缓存，建议开启以提高解析速度，减少网络请求 |
| maxCacheSize | int | 100 | 最大缓存大小，控制内存中缓存的域名数量，避免内存占用过多 |
| maxNegativeCache | int | 30 | 最大否定缓存时间（秒），解析失败时的缓存时间，避免频繁重试 |
| enableIPv6 | bool | false | 是否启用 IPv6 解析，根据网络环境选择，IPv6网络建议开启 |
| enableShort | bool | false | 是否启用短连接，影响网络请求的连接方式，长连接可提高性能 |
| enableSpeedTest | bool | true | 是否启用测速功能，自动选择最快的IP，提高访问速度 |
| preloadDomains | List<String> | [] | 预加载域名列表，提前解析常用域名，减少首次访问延迟 |
| keepAliveDomains | List<String> | [] | 缓存保持域名列表，TTL * 75%时自动更新缓存，确保缓存有效性 |
| timeout | int | 3 | 超时时间（秒），DNS解析请求的超时设置，避免长时间等待 |
| maxCacheTTL | int | 3600 | 最大缓存 TTL 时间（秒），控制缓存的有效期，平衡新鲜度和性能 |
| ispEnable | bool | true | 是否启用 ISP 网络区分，根据运营商优化解析，提高解析准确性 |
| speedPort | int | 80 | 测速端口，用于IP测速的端口号，通常为80或443 |

### ProxyConfig 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| port | int | 4041 | 代理服务器端口 |
| portMap | Map<String, int> | {} | 端口映射配置（字符串键） |
| fixedDomain | Map<String, String> | {} | 固定域名映射 |
| enabled | bool | true | 是否启用代理 |
| host | String | 'localhost' | 代理服务器地址 |

## API 参考

### FlutterAliHttpDns 类

#### 主要方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `initialize(DnsConfig config)` | `Future<void>` | 初始化 DNS 服务 |
| `resolveDomain(String domain)` | `Future<String>` | 解析域名 |
| `startProxy(ProxyConfig config)` | `Future<void>` | 启动代理服务器 |
| `stopProxy()` | `Future<void>` | 停止代理服务器 |
| `configureHttpClient(HttpClient client)` | `Future<void>` | 配置 HttpClient |
| `getDioProxyConfig()` | `Future<Map<String, dynamic>?>` | 获取 Dio 代理配置 |
| `getProxyAddress()` | `Future<String?>` | 获取代理地址 |
| `getProxyConfigString()` | `Future<String?>` | 获取代理配置字符串 |
| `checkProxyStatus()` | `Future<bool>` | 检查代理状态 |
| `dispose()` | `Future<void>` | 清理资源 |

#### 静态方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `setLogLevel(LogLevel level)` | `void` | 设置日志级别 |
| `setLogEnabled(bool enabled)` | `void` | 启用/禁用日志 |

### 配置类

#### DnsConfig
DNS 服务配置类，包含阿里云 HttpDNS 的所有配置参数。

#### ProxyConfig
代理服务器配置类，包含端口映射、域名映射等配置。

## 示例项目

查看 `example/` 目录中的完整示例项目，了解插件的详细使用方法。

运行示例项目：

```bash
cd example
flutter pub get
flutter run
```

## 注意事项

1. **配置信息**：请确保使用正确的阿里云 HttpDNS 配置信息，包括 Account ID、AccessKey ID 和 AccessKey Secret。

2. **官方文档参考**：更多详细的配置说明和最佳实践，请参考[阿里云移动解析HTTPDNS官方文档](https://help.aliyun.com/zh/dns/httpdns-android-sdk-development-guide)。

3. **网络权限**：确保应用具有网络访问权限。

4. **代理端口**：默认代理端口为 4041，请确保该端口未被其他应用占用。

5. **iOS 配置**：iOS 项目需要添加网络权限配置和阿里云 HttpDNS SDK 依赖。

6. **Android 配置**：Android 项目需要添加网络权限。

7. **端口映射**：端口映射的键必须是字符串类型。

8. **日志控制**：默认只在 debug 模式下打印日志，可以通过 API 控制日志级别和开关。

9. **域名映射**：`fixedDomain` 使用端口号作为 key，支持灵活的端口到域名映射。

10. **代理场景**：插件支持两种代理场景，Dio 场景保持原域名，Nakama 场景应用域名映射。

11. **资源管理**：使用完毕后请调用 `dispose()` 方法清理资源。

## 错误处理

插件提供了完善的错误处理机制：

```dart
try {
  await dnsPlugin.initialize(dnsConfig);
} catch (e) {
  print('初始化失败: $e');
}

try {
  String ip = await dnsPlugin.resolveDomain('www.example.com');
} catch (e) {
  print('域名解析失败: $e');
}
```

## 常见问题

### Q: 如何获取阿里云 HttpDNS 的配置信息？
A: 登录阿里云控制台，进入 HttpDNS 服务，在控制台中可以找到 Account ID、AccessKey ID 和 AccessKey Secret。

### Q: 代理服务器启动失败怎么办？
A: 检查端口是否被占用，可以尝试更换其他端口。确保应用有网络权限。

### Q: 域名解析失败怎么办？
A: 检查网络连接和阿里云 HttpDNS 配置信息是否正确。可以查看日志获取详细错误信息。

### Q: 如何自定义端口到域名的映射？
A: 使用 `fixedDomain` 配置，以端口号作为 key，域名作为 value：
```dart
fixedDomain: {
  '8080': 'api.example.com',
  '8081': 'chat.example.com',
}
```

### Q: 什么时候需要使用本地代理场景？
A: 当客户端或服务无法直接配置 HTTP 代理时，可以使用本地代理场景。例如：
- 游戏服务器（如 Nakama、Unity 游戏服务器）
- 第三方 SDK 不支持代理配置
- 遗留系统无法修改代理设置
- 嵌入式设备或 IoT 设备

客户端只需要连接到 `localhost:端口号`，代理会自动将请求转发到对应的真实服务器。

### Q: 支持哪些 HTTP 客户端？
A: 目前支持 `HttpClient` 和 `Dio`，可以通过相应的方法进行配置。

### Q: 如何控制日志输出？
A: 使用 `FlutterAliHttpDns.setLogLevel()` 和 `FlutterAliHttpDns.setLogEnabled()` 方法控制日志级别和开关。



## 贡献

欢迎提交 Issue 和 Pull Request！

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
