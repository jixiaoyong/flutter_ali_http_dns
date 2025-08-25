import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxy_config.freezed.dart';
part 'proxy_config.g.dart';

/// 代理配置模型
@freezed
class ProxyConfig with _$ProxyConfig {
  const factory ProxyConfig({
    /// 端口池配置（可选，如果指定则优先使用）
    List<int>? portPool,
    
    /// 自动分配的起始端口（默认4041）
    int? startPort,
    
    /// 自动分配的结束端口（可选，必须大于startPort）
    /// 如果未指定，则使用 startPort + 100
    /// 如果指定范围不足，会自动突破范围寻找可用端口
    int? endPort,
    
    /// 是否启用代理
    @Default(true) bool enabled,
    
    /// 代理服务器地址
    @Default('localhost') String host,
  }) = _ProxyConfig;

  factory ProxyConfig.fromJson(Map<String, dynamic> json) =>
      _$ProxyConfigFromJson(json);
}
