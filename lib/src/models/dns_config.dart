import 'package:freezed_annotation/freezed_annotation.dart';

part 'dns_config.freezed.dart';
part 'dns_config.g.dart';

/// DNS 配置模型
@freezed
class DnsConfig with _$DnsConfig {
  const factory DnsConfig({
    /// 阿里云控制台的 Account ID
    required String accountId,
    
    /// 阿里云 AccessKey ID
    required String accessKeyId,
    
    /// 阿里云 AccessKey Secret
    required String accessKeySecret,
    
    /// 是否启用缓存
    @Default(true) bool enableCache,
    
    /// 最大缓存大小
    @Default(100) int maxCacheSize,
    
    /// 最大否定缓存时间（秒）
    @Default(30) int maxNegativeCache,
    
    /// 是否启用 IPv6
    @Default(false) bool enableIPv6,
    
    /// 是否启用短连接
    @Default(false) bool enableShort,
    
    /// 是否启用测速功能
    @Default(true) bool enableSpeedTest,
    
    /// 预加载域名列表
    @Default([]) List<String> preloadDomains,
    
    /// 缓存保持域名列表
    @Default([]) List<String> keepAliveDomains,
    
    /// 超时时间（秒）
    @Default(3) int timeout,
    
    /// 最大缓存 TTL 时间（秒）
    @Default(3600) int maxCacheTTL,
    
    /// 是否启用 ISP 网络区分
    @Default(true) bool ispEnable,
    
    /// 测速端口
    @Default(80) int speedPort,
  }) = _DnsConfig;

  factory DnsConfig.fromJson(Map<String, dynamic> json) =>
      _$DnsConfigFromJson(json);
}
