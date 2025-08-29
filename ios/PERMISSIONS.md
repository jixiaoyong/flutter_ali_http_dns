# iOS 权限说明

## 网络权限

本插件需要以下网络权限来支持 HTTPDNS 功能：

### 1. App Transport Security (ATS)

**基于阿里云官方文档要求**，插件在 `Info.plist` 中声明了以下网络权限：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- 允许HTTP协议访问（用于HTTPDNS解析） -->
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 2. 权限说明

- **NSAllowsArbitraryLoads**: 允许任意HTTP连接（**阿里云官方要求**）
  - 这个设置已经足够支持HTTPDNS的所有功能
  - 不需要为特定域名设置例外

### 3. 阿里云官方文档要求

根据[阿里云HTTPDNS iOS SDK开发指南](https://help.aliyun.com/zh/dns/httpdns-ios-sdk-development-guide)：

> **使用HTTP协议请求时，需要在`Info.plist`中设置`App Transport Security Settings->Allow Arbitrary Loads`为`YES`。**

**重要说明**：
- SDK默认并推荐使用HTTPS协议进行解析，因为HTTPS协议安全性更好
- 移动解析HTTPDNS的计费项是按HTTP的解析次数进行收费，其中HTTPS是按5倍HTTP流量进行计费

### 4. 生产环境建议

对于生产环境，建议使用更严格的设置：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>your-api-domain.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 5. 与Android对比

| 平台 | 权限声明位置 | 权限类型 |
|------|-------------|----------|
| Android | `AndroidManifest.xml` | `INTERNET`, `ACCESS_NETWORK_STATE` |
| iOS | `Info.plist` | `NSAppTransportSecurity` |

### 6. 注意事项

1. **插件级别权限**: 这些权限在插件级别声明，使用插件的应用会自动继承
2. **应用级别覆盖**: 应用可以在自己的 `Info.plist` 中覆盖这些设置
3. **审核要求**: 使用 `NSAllowsArbitraryLoads` 需要在 App Store 审核时说明原因
4. **安全性**: 建议在生产环境中使用更严格的域名例外设置
