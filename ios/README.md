# iOS 配置说明

## 自动依赖管理

本插件会自动处理阿里云 HttpDNS iOS SDK 的依赖，使用插件的项目无需额外配置。

## 技术实现

插件内部集成了阿里云 HttpDNS iOS SDK (`AlicloudPDNS`)，通过以下方式实现：

### 1. 依赖声明

在 `ios/flutter_ali_http_dns.podspec` 中声明了对 `AlicloudPDNS` 的依赖：

```ruby
s.dependency 'AlicloudPDNS'
```

### 2. SDK 集成

插件使用运行时反射和 KVC 方式集成 SDK，以保持兼容性：

```swift
// 获取 DNSResolver 实例
let dnsResolverClass = NSClassFromString("DNSResolver") as! NSObject.Type
dnsResolver = dnsResolverClass.perform(NSSelectorFromString("share"))?.takeUnretainedValue() as? NSObject

// 使用 KVC 设置配置
dnsResolver?.setValue(accountId, forKey: "accountId")
dnsResolver?.setValue(accessKeyId, forKey: "accessKeyId")
dnsResolver?.setValue(accessKeySecret, forKey: "accessKeySecret")
```

### 3. 配置参数

插件支持以下配置参数：

- `accountId`: 阿里云控制台的 Account ID
- `accessKeyId`: 阿里云 AccessKey ID  
- `accessKeySecret`: 阿里云 AccessKey Secret
- `enableCache`: 是否启用缓存
- `maxCacheSize`: 最大缓存大小
- `timeout`: 超时时间
- `enableIPv6`: 是否启用 IPv6
- `enableSpeedTest`: 是否启用测速功能
- `speedPort`: 测速端口
- `maxNegativeCache`: 否定缓存时间
- `maxCacheTTL`: 最大缓存 TTL
- `ispEnable`: 是否启用 ISP 网络区分
- `keepAliveDomains`: 保持连接的域名列表

## 官方文档参考

本插件的 iOS 实现基于以下官方文档：
- [iOS SDK开发指南](https://help.aliyun.com/zh/dns/httpdns-ios-sdk-development-guide)

## 注意事项

- 确保您的 iOS 项目支持 CocoaPods
- SDK 支持最低版本为 iOS 12.0
- 建议在真机上测试 DNS 解析功能
- 模拟器环境下 DNS 功能会受限，会直接返回原域名
- **ATS 无需配置**：插件 HTTPDNS 解析走 HTTPS，默认不需要任何 ATS 例外；插件自身 `Info.plist` 不声明 `NSAppTransportSecurity`
- **ATS 例外写在哪**：如宿主 App 因业务需要访问明文 HTTP 上游，必须在宿主 App（Flutter 工程为 `ios/Runner/Info.plist`）中配置例外；写在插件 framework 的 `Info.plist` 不生效，也不会从 framework 继承到宿主 App

## 故障排除

如果遇到问题，请检查：

1. 是否运行了 `pod install`
2. 是否重新构建了项目
3. 是否在真机上测试（模拟器可能有限制）
4. 阿里云 HttpDNS 配置信息是否正确
5. 需要明文 HTTP 访问时，是否在宿主 App 的 `ios/Runner/Info.plist` 中精确配置了 ATS 例外（推荐 `NSExceptionDomains` 按域名，避免全局 `NSAllowsArbitraryLoads`）
