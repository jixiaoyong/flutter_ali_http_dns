import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxy_config.freezed.dart';
part 'proxy_config.g.dart';

/// 代理配置模型
@freezed
class ProxyConfig with _$ProxyConfig {
  const factory ProxyConfig({
    /// 代理服务器端口
    @Default(4041) int port,
    
    /// 端口映射配置
    @Default({}) Map<String, int> portMap,
    
    /// 固定域名映射
    @Default({}) Map<String, String> fixedDomain,
    
    /// 是否启用代理
    @Default(true) bool enabled,
    
    /// 代理服务器地址
    @Default('localhost') String host,
  }) = _ProxyConfig;

  factory ProxyConfig.fromJson(Map<String, dynamic> json) =>
      _$ProxyConfigFromJson(json);
}
