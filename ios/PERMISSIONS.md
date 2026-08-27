# iOS 权限说明

## 网络权限

本插件在 iOS 上通过阿里云 HTTPDNS SDK（走 HTTPS）解析域名，插件的 `Info.plist` 不声明任何 ATS（App Transport Security）例外。

### 1. App Transport Security (ATS)

**插件本身不需要任何 ATS 配置**，原因：

- 插件进行 HTTPDNS 解析时使用 HTTPS（或 DNS 协议），不受 ATS 对明文 HTTP 的限制影响。
- ATS 配置**只在该配置所在的 App 的 `Info.plist`（即宿主工程的 `ios/AppName/Info.plist`，Flutter 工程默认是 `ios/Runner/Info.plist`）中生效**。
- **插件 framework 自己的 `Info.plist` 不会被系统在宿主 App 中读取**：`NSAppTransportSecurity` 不会从 framework 的 Info.plist 继承到宿主 App。
- 因此，插件不应在自身 `Info.plist` 中声明 `NSAllowsArbitraryLoads`（本插件已删除）。即便声明了，对宿主 App 也不生效，反而可能误导开发者以为 ATS 已全局放开。

### 2. 宿主 App 需要访问明文 HTTP 上游时的配置

只有你自身的业务需要访问明文 HTTP 上游（例如某个 API 或 CDN 只能走 HTTP）时，**才**需要在宿主 App 的 `Info.plist`（如 `ios/Runner/Info.plist`）中按 Apple 指南精确声明例外。

**推荐：按域名声明例外（`NSExceptionDomains`），不要全局放开：**

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

- 只对你确需要的域名放开明文 HTTP，其他请求仍然受 ATS 保护。
- 域名不带协议头，如：`your-api-domain.com`，不是 `http://your-api-domain.com`。

**不推荐：全局 `NSAllowsArbitraryLoads`（安全性影响）**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

- 这会关闭宿主 App 全局的 ATS 保护，允许所有明文 HTTP 流量，显著降低传输安全。
- 与宿主 App 对密码、支付、用户数据等敏感信息的 HTTPS 要求冲突。
- 若确需使用，注意 App Store 审核时需提供理由，并承担更大的安全风险。
- 对插件本身的 HTTPDNS 功能而言，**不需要**这个全局放宽。

### 3. 与 Android 对比

| 平台 | 权限声明位置 | 权限类型 |
|------|-------------|----------|
| Android | `AndroidManifest.xml` | `INTERNET`, `ACCESS_NETWORK_STATE` |
| iOS | （插件不需要） | ATS 例外只在宿主 App 的 `Info.plist` 生效 |

### 4. 注意事项

1. **ATS 例外必须写在宿主 App 的 `Info.plist`**（Flutter 工程为 `ios/Runner/Info.plist`），写在插件 framework 的 `Info.plist` 不生效。
2. **按域名例外**：优先使用 `NSExceptionDomains` 逐域名配置，避免全局 `NSAllowsArbitraryLoads` 关闭整体 ATS 保护。
3. **审核要求**：使用 `NSAllowsArbitraryLoads`（或大范围例外）要在 App Store 审核时说明原因。
4. **安全基线**：ATS 是 Apple 提供的传输安全保护，全局放开会削弱宿主 App 的安全性；非业务必需，不要配置。
