// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProxyConfigImpl _$$ProxyConfigImplFromJson(Map<String, dynamic> json) =>
    _$ProxyConfigImpl(
      portPool: (json['portPool'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      startPort: (json['startPort'] as num?)?.toInt(),
      endPort: (json['endPort'] as num?)?.toInt(),
      enabled: json['enabled'] as bool? ?? true,
      host: json['host'] as String? ?? 'localhost',
    );

Map<String, dynamic> _$$ProxyConfigImplToJson(_$ProxyConfigImpl instance) =>
    <String, dynamic>{
      'portPool': instance.portPool,
      'startPort': instance.startPort,
      'endPort': instance.endPort,
      'enabled': instance.enabled,
      'host': instance.host,
    };
