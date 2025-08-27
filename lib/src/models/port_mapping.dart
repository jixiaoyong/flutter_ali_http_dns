import 'package:freezed_annotation/freezed_annotation.dart';

part 'port_mapping.freezed.dart';
part 'port_mapping.g.dart';

/// 端口映射模型
@freezed
class PortMapping with _$PortMapping {
  const factory PortMapping({
    /// 本地端口
    required int localPort,
    
    /// 目标端口（可选，null表示使用原始端口）
    int? targetPort,
    
    /// 目标域名
    required String targetDomain,
    
    /// 映射名称（可选）
    String? name,
    
    /// 描述信息（可选）
    String? description,
    
    /// 创建时间
    DateTime? createdAt,
    
    /// 是否激活
    @Default(true) bool isActive,
    
    /// 是否为安全连接 (HTTPS/TLS)
    @Default(true) bool isSecure,
    
    /// 是否在:authority头部中包含域名信息
    /// true: 包含域名信息 (api.example.com:443)
    /// false: 只使用IP地址 (198.1.1.1:443)
    @Default(true) bool includeDomainInAuthority,
  }) = _PortMapping;

  factory PortMapping.fromJson(Map<String, dynamic> json) =>
      _$PortMappingFromJson(json);
}
