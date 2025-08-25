# Android Module Configuration

## ProGuard Rules

This Flutter plugin includes ProGuard rules for the Alibaba Cloud HttpDNS SDK to ensure proper functionality when the app is obfuscated.

### Automatic ProGuard Rules

The plugin automatically includes the following ProGuard rules in `android/src/main/proguard-rules.pro`:

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

### How It Works

1. **Automatic Inclusion**: The ProGuard rules are automatically included in the plugin's Android library module
2. **Transitive Application**: When an app uses this Flutter plugin, these ProGuard rules are automatically applied to the app's build process
3. **No Manual Configuration Required**: App developers don't need to manually add ProGuard rules for the HttpDNS SDK

### Build Configuration

The plugin's `build.gradle` file is configured to include the ProGuard rules for both debug and release builds:

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

### Dependencies

The plugin includes the following Android dependencies:

- `com.alibaba.pdns:alidns-android-sdk:2.2.8` - Alibaba Cloud HttpDNS SDK
- `com.google.code.gson:gson:2.8.5` - JSON serialization
- `com.squareup.okhttp3:okhttp:4.9.1` - HTTP client
- `com.squareup.retrofit2:retrofit:2.9.0` - HTTP client wrapper
- `com.squareup.retrofit2:converter-gson:2.9.0` - JSON converter for Retrofit

### Notes for App Developers

- **No Additional Configuration**: App developers using this plugin don't need to add any ProGuard rules manually
- **Automatic Protection**: The HttpDNS SDK classes are automatically protected from obfuscation
- **Compatibility**: The rules ensure compatibility with both debug and release builds
