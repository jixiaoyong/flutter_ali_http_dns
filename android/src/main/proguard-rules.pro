# Flutter Ali HttpDNS Plugin ProGuard Rules

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
