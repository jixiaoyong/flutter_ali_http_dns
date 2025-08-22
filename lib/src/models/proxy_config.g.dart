// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProxyConfigImpl _$$ProxyConfigImplFromJson(Map<String, dynamic> json) =>
    _$ProxyConfigImpl(
      port: (json['port'] as num?)?.toInt() ?? 4041,
      portMap: (json['portMap'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      fixedDomain: (json['fixedDomain'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      enabled: json['enabled'] as bool? ?? true,
      host: json['host'] as String? ?? 'localhost',
    );

Map<String, dynamic> _$$ProxyConfigImplToJson(_$ProxyConfigImpl instance) =>
    <String, dynamic>{
      'port': instance.port,
      'portMap': instance.portMap,
      'fixedDomain': instance.fixedDomain,
      'enabled': instance.enabled,
      'host': instance.host,
    };
