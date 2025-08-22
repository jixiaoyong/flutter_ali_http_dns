// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DnsConfigImpl _$$DnsConfigImplFromJson(Map<String, dynamic> json) =>
    _$DnsConfigImpl(
      accountId: json['accountId'] as String,
      accessKeyId: json['accessKeyId'] as String,
      accessKeySecret: json['accessKeySecret'] as String,
      enableCache: json['enableCache'] as bool? ?? true,
      maxCacheSize: (json['maxCacheSize'] as num?)?.toInt() ?? 100,
      maxNegativeCache: (json['maxNegativeCache'] as num?)?.toInt() ?? 30,
      enableIPv6: json['enableIPv6'] as bool? ?? false,
      enableShort: json['enableShort'] as bool? ?? false,
      enableSpeedTest: json['enableSpeedTest'] as bool? ?? true,
      preloadDomains: (json['preloadDomains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      keepAliveDomains: (json['keepAliveDomains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      timeout: (json['timeout'] as num?)?.toInt() ?? 3,
      maxCacheTTL: (json['maxCacheTTL'] as num?)?.toInt() ?? 3600,
      ispEnable: json['ispEnable'] as bool? ?? true,
      speedPort: (json['speedPort'] as num?)?.toInt() ?? 80,
    );

Map<String, dynamic> _$$DnsConfigImplToJson(_$DnsConfigImpl instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'accessKeyId': instance.accessKeyId,
      'accessKeySecret': instance.accessKeySecret,
      'enableCache': instance.enableCache,
      'maxCacheSize': instance.maxCacheSize,
      'maxNegativeCache': instance.maxNegativeCache,
      'enableIPv6': instance.enableIPv6,
      'enableShort': instance.enableShort,
      'enableSpeedTest': instance.enableSpeedTest,
      'preloadDomains': instance.preloadDomains,
      'keepAliveDomains': instance.keepAliveDomains,
      'timeout': instance.timeout,
      'maxCacheTTL': instance.maxCacheTTL,
      'ispEnable': instance.ispEnable,
      'speedPort': instance.speedPort,
    };
