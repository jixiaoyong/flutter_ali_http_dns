// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port_mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortMappingImpl _$$PortMappingImplFromJson(Map<String, dynamic> json) =>
    _$PortMappingImpl(
      localPort: (json['localPort'] as num).toInt(),
      targetPort: (json['targetPort'] as num?)?.toInt(),
      targetDomain: json['targetDomain'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isSecure: json['isSecure'] as bool? ?? true,
      includeDomainInAuthority:
          json['includeDomainInAuthority'] as bool? ?? true,
    );

Map<String, dynamic> _$$PortMappingImplToJson(_$PortMappingImpl instance) =>
    <String, dynamic>{
      'localPort': instance.localPort,
      'targetPort': instance.targetPort,
      'targetDomain': instance.targetDomain,
      'name': instance.name,
      'description': instance.description,
      'createdAt': instance.createdAt?.toIso8601String(),
      'isActive': instance.isActive,
      'isSecure': instance.isSecure,
      'includeDomainInAuthority': instance.includeDomainInAuthority,
    };
