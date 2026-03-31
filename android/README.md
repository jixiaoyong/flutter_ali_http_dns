# Android 模块配置

## 开发环境要求

- JDK 17
- Gradle 7.5（`gradle/wrapper/gradle-wrapper.properties`）
- Android Gradle Plugin 7.3.0
- Kotlin 1.7.10
- Android SDK：`compileSdk 34`，`minSdk 21`

## ProGuard 规则

该 Flutter 插件内置了阿里云 HttpDNS SDK 的 ProGuard 规则，用于确保应用在混淆后依然可以正常运行。

### 自动 ProGuard 规则

插件会自动把以下 ProGuard 规则包含到 `android/src/main/proguard-rules.pro` 中：

```proguard
# 阿里云 HttpDNS SDK 混淆规则
-keep class com.alibaba.pdns.** {*;}

# 保持DNS解析相关的类和方法
-keep class com.alibaba.pdns.DNSResolver {*;}
-keepclassmembers class com.alibaba.pdns.DNSResolver {
    public static void Init(android.content.Context, java.lang.String, java.lang.String, java.lang.String);
    public static void setKeepAliveDomains(java.lang.String[]);
    public java.lang.String getIPV4ByHost(java.lang.String);
    public void preLoadDomains(int, java.lang.String[]);
}

# 保持网络相关的类
-keep class com.alibaba.pdns.network.** {*;}
-keep class com.alibaba.pdns.cache.** {*;}
-keep class com.alibaba.pdns.utils.** {*;}

# 保持JSON序列化相关的类（如果SDK内部使用）
-keep class com.alibaba.pdns.model.** {*;}

# 避免混淆DNS相关的常量
-keepclassmembers class com.alibaba.pdns.DNSResolver {
    public static final int QTYPE_IPV4;
    public static final int QTYPE_IPV6;
}

# 保持插件自身的类不被混淆
-keep class io.github.jixiaoyong.flutter_ali_http_dns.** {*;}

# 保持方法通道相关的类
-keep class io.flutter.plugin.common.** {*;}
-keep class io.flutter.embedding.engine.** {*;}
```

### 工作原理

1. **自动包含**：ProGuard 规则会自动包含在插件的 Android library 模块中
2. **传递生效**：当应用使用该 Flutter 插件时，这些 ProGuard 规则会自动应用到应用的构建流程
3. **无需手动配置**：应用侧无需再手动添加 HttpDNS SDK 的 ProGuard 规则

### 构建配置

插件的 `build.gradle` 已配置在 debug 与 release 构建中包含 ProGuard 规则：

```gradle
buildTypes {
    release {
        minifyEnabled false
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'src/main/proguard-rules.pro'
    }
    debug {
        minifyEnabled false
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'src/main/proguard-rules.pro'
    }
}
```

### 依赖

插件包含以下 Android 依赖：

- `com.alibaba.pdns:alidns-android-sdk:2.2.8` - 阿里云 HttpDNS SDK
- `com.google.code.gson:gson:2.8.5` - JSON 序列化
- `com.squareup.okhttp3:okhttp:4.9.1` - HTTP 客户端
- `com.squareup.retrofit2:retrofit:2.9.0` - HTTP 客户端封装
- `com.squareup.retrofit2:converter-gson:2.9.0` - Retrofit 的 JSON 转换器

### 应用侧注意事项

- **无需额外配置**：使用该插件的应用无需手动添加任何 ProGuard 规则
- **自动保护**：HttpDNS SDK 的类会自动被保护不被混淆
- **兼容性**：规则确保 debug 与 release 构建均可正常工作
