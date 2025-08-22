// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dns_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DnsConfig _$DnsConfigFromJson(Map<String, dynamic> json) {
  return _DnsConfig.fromJson(json);
}

/// @nodoc
mixin _$DnsConfig {
  /// 阿里云控制台的 Account ID
  String get accountId => throw _privateConstructorUsedError;

  /// 阿里云 AccessKey ID
  String get accessKeyId => throw _privateConstructorUsedError;

  /// 阿里云 AccessKey Secret
  String get accessKeySecret => throw _privateConstructorUsedError;

  /// 是否启用缓存
  bool get enableCache => throw _privateConstructorUsedError;

  /// 最大缓存大小
  int get maxCacheSize => throw _privateConstructorUsedError;

  /// 最大否定缓存时间（秒）
  int get maxNegativeCache => throw _privateConstructorUsedError;

  /// 是否启用 IPv6
  bool get enableIPv6 => throw _privateConstructorUsedError;

  /// 是否启用短连接
  bool get enableShort => throw _privateConstructorUsedError;

  /// 是否启用测速功能
  bool get enableSpeedTest => throw _privateConstructorUsedError;

  /// 预加载域名列表
  List<String> get preloadDomains => throw _privateConstructorUsedError;

  /// 缓存保持域名列表
  List<String> get keepAliveDomains => throw _privateConstructorUsedError;

  /// 超时时间（秒）
  int get timeout => throw _privateConstructorUsedError;

  /// 最大缓存 TTL 时间（秒）
  int get maxCacheTTL => throw _privateConstructorUsedError;

  /// 是否启用 ISP 网络区分
  bool get ispEnable => throw _privateConstructorUsedError;

  /// 测速端口
  int get speedPort => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DnsConfigCopyWith<DnsConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DnsConfigCopyWith<$Res> {
  factory $DnsConfigCopyWith(DnsConfig value, $Res Function(DnsConfig) then) =
      _$DnsConfigCopyWithImpl<$Res, DnsConfig>;
  @useResult
  $Res call(
      {String accountId,
      String accessKeyId,
      String accessKeySecret,
      bool enableCache,
      int maxCacheSize,
      int maxNegativeCache,
      bool enableIPv6,
      bool enableShort,
      bool enableSpeedTest,
      List<String> preloadDomains,
      List<String> keepAliveDomains,
      int timeout,
      int maxCacheTTL,
      bool ispEnable,
      int speedPort});
}

/// @nodoc
class _$DnsConfigCopyWithImpl<$Res, $Val extends DnsConfig>
    implements $DnsConfigCopyWith<$Res> {
  _$DnsConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? accessKeyId = null,
    Object? accessKeySecret = null,
    Object? enableCache = null,
    Object? maxCacheSize = null,
    Object? maxNegativeCache = null,
    Object? enableIPv6 = null,
    Object? enableShort = null,
    Object? enableSpeedTest = null,
    Object? preloadDomains = null,
    Object? keepAliveDomains = null,
    Object? timeout = null,
    Object? maxCacheTTL = null,
    Object? ispEnable = null,
    Object? speedPort = null,
  }) {
    return _then(_value.copyWith(
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      accessKeyId: null == accessKeyId
          ? _value.accessKeyId
          : accessKeyId // ignore: cast_nullable_to_non_nullable
              as String,
      accessKeySecret: null == accessKeySecret
          ? _value.accessKeySecret
          : accessKeySecret // ignore: cast_nullable_to_non_nullable
              as String,
      enableCache: null == enableCache
          ? _value.enableCache
          : enableCache // ignore: cast_nullable_to_non_nullable
              as bool,
      maxCacheSize: null == maxCacheSize
          ? _value.maxCacheSize
          : maxCacheSize // ignore: cast_nullable_to_non_nullable
              as int,
      maxNegativeCache: null == maxNegativeCache
          ? _value.maxNegativeCache
          : maxNegativeCache // ignore: cast_nullable_to_non_nullable
              as int,
      enableIPv6: null == enableIPv6
          ? _value.enableIPv6
          : enableIPv6 // ignore: cast_nullable_to_non_nullable
              as bool,
      enableShort: null == enableShort
          ? _value.enableShort
          : enableShort // ignore: cast_nullable_to_non_nullable
              as bool,
      enableSpeedTest: null == enableSpeedTest
          ? _value.enableSpeedTest
          : enableSpeedTest // ignore: cast_nullable_to_non_nullable
              as bool,
      preloadDomains: null == preloadDomains
          ? _value.preloadDomains
          : preloadDomains // ignore: cast_nullable_to_non_nullable
              as List<String>,
      keepAliveDomains: null == keepAliveDomains
          ? _value.keepAliveDomains
          : keepAliveDomains // ignore: cast_nullable_to_non_nullable
              as List<String>,
      timeout: null == timeout
          ? _value.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as int,
      maxCacheTTL: null == maxCacheTTL
          ? _value.maxCacheTTL
          : maxCacheTTL // ignore: cast_nullable_to_non_nullable
              as int,
      ispEnable: null == ispEnable
          ? _value.ispEnable
          : ispEnable // ignore: cast_nullable_to_non_nullable
              as bool,
      speedPort: null == speedPort
          ? _value.speedPort
          : speedPort // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DnsConfigImplCopyWith<$Res>
    implements $DnsConfigCopyWith<$Res> {
  factory _$$DnsConfigImplCopyWith(
          _$DnsConfigImpl value, $Res Function(_$DnsConfigImpl) then) =
      __$$DnsConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String accountId,
      String accessKeyId,
      String accessKeySecret,
      bool enableCache,
      int maxCacheSize,
      int maxNegativeCache,
      bool enableIPv6,
      bool enableShort,
      bool enableSpeedTest,
      List<String> preloadDomains,
      List<String> keepAliveDomains,
      int timeout,
      int maxCacheTTL,
      bool ispEnable,
      int speedPort});
}

/// @nodoc
class __$$DnsConfigImplCopyWithImpl<$Res>
    extends _$DnsConfigCopyWithImpl<$Res, _$DnsConfigImpl>
    implements _$$DnsConfigImplCopyWith<$Res> {
  __$$DnsConfigImplCopyWithImpl(
      _$DnsConfigImpl _value, $Res Function(_$DnsConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? accessKeyId = null,
    Object? accessKeySecret = null,
    Object? enableCache = null,
    Object? maxCacheSize = null,
    Object? maxNegativeCache = null,
    Object? enableIPv6 = null,
    Object? enableShort = null,
    Object? enableSpeedTest = null,
    Object? preloadDomains = null,
    Object? keepAliveDomains = null,
    Object? timeout = null,
    Object? maxCacheTTL = null,
    Object? ispEnable = null,
    Object? speedPort = null,
  }) {
    return _then(_$DnsConfigImpl(
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      accessKeyId: null == accessKeyId
          ? _value.accessKeyId
          : accessKeyId // ignore: cast_nullable_to_non_nullable
              as String,
      accessKeySecret: null == accessKeySecret
          ? _value.accessKeySecret
          : accessKeySecret // ignore: cast_nullable_to_non_nullable
              as String,
      enableCache: null == enableCache
          ? _value.enableCache
          : enableCache // ignore: cast_nullable_to_non_nullable
              as bool,
      maxCacheSize: null == maxCacheSize
          ? _value.maxCacheSize
          : maxCacheSize // ignore: cast_nullable_to_non_nullable
              as int,
      maxNegativeCache: null == maxNegativeCache
          ? _value.maxNegativeCache
          : maxNegativeCache // ignore: cast_nullable_to_non_nullable
              as int,
      enableIPv6: null == enableIPv6
          ? _value.enableIPv6
          : enableIPv6 // ignore: cast_nullable_to_non_nullable
              as bool,
      enableShort: null == enableShort
          ? _value.enableShort
          : enableShort // ignore: cast_nullable_to_non_nullable
              as bool,
      enableSpeedTest: null == enableSpeedTest
          ? _value.enableSpeedTest
          : enableSpeedTest // ignore: cast_nullable_to_non_nullable
              as bool,
      preloadDomains: null == preloadDomains
          ? _value._preloadDomains
          : preloadDomains // ignore: cast_nullable_to_non_nullable
              as List<String>,
      keepAliveDomains: null == keepAliveDomains
          ? _value._keepAliveDomains
          : keepAliveDomains // ignore: cast_nullable_to_non_nullable
              as List<String>,
      timeout: null == timeout
          ? _value.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as int,
      maxCacheTTL: null == maxCacheTTL
          ? _value.maxCacheTTL
          : maxCacheTTL // ignore: cast_nullable_to_non_nullable
              as int,
      ispEnable: null == ispEnable
          ? _value.ispEnable
          : ispEnable // ignore: cast_nullable_to_non_nullable
              as bool,
      speedPort: null == speedPort
          ? _value.speedPort
          : speedPort // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DnsConfigImpl implements _DnsConfig {
  const _$DnsConfigImpl(
      {required this.accountId,
      required this.accessKeyId,
      required this.accessKeySecret,
      this.enableCache = true,
      this.maxCacheSize = 100,
      this.maxNegativeCache = 30,
      this.enableIPv6 = false,
      this.enableShort = false,
      this.enableSpeedTest = true,
      final List<String> preloadDomains = const [],
      final List<String> keepAliveDomains = const [],
      this.timeout = 3,
      this.maxCacheTTL = 3600,
      this.ispEnable = true,
      this.speedPort = 80})
      : _preloadDomains = preloadDomains,
        _keepAliveDomains = keepAliveDomains;

  factory _$DnsConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$DnsConfigImplFromJson(json);

  /// 阿里云控制台的 Account ID
  @override
  final String accountId;

  /// 阿里云 AccessKey ID
  @override
  final String accessKeyId;

  /// 阿里云 AccessKey Secret
  @override
  final String accessKeySecret;

  /// 是否启用缓存
  @override
  @JsonKey()
  final bool enableCache;

  /// 最大缓存大小
  @override
  @JsonKey()
  final int maxCacheSize;

  /// 最大否定缓存时间（秒）
  @override
  @JsonKey()
  final int maxNegativeCache;

  /// 是否启用 IPv6
  @override
  @JsonKey()
  final bool enableIPv6;

  /// 是否启用短连接
  @override
  @JsonKey()
  final bool enableShort;

  /// 是否启用测速功能
  @override
  @JsonKey()
  final bool enableSpeedTest;

  /// 预加载域名列表
  final List<String> _preloadDomains;

  /// 预加载域名列表
  @override
  @JsonKey()
  List<String> get preloadDomains {
    if (_preloadDomains is EqualUnmodifiableListView) return _preloadDomains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_preloadDomains);
  }

  /// 缓存保持域名列表
  final List<String> _keepAliveDomains;

  /// 缓存保持域名列表
  @override
  @JsonKey()
  List<String> get keepAliveDomains {
    if (_keepAliveDomains is EqualUnmodifiableListView)
      return _keepAliveDomains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keepAliveDomains);
  }

  /// 超时时间（秒）
  @override
  @JsonKey()
  final int timeout;

  /// 最大缓存 TTL 时间（秒）
  @override
  @JsonKey()
  final int maxCacheTTL;

  /// 是否启用 ISP 网络区分
  @override
  @JsonKey()
  final bool ispEnable;

  /// 测速端口
  @override
  @JsonKey()
  final int speedPort;

  @override
  String toString() {
    return 'DnsConfig(accountId: $accountId, accessKeyId: $accessKeyId, accessKeySecret: $accessKeySecret, enableCache: $enableCache, maxCacheSize: $maxCacheSize, maxNegativeCache: $maxNegativeCache, enableIPv6: $enableIPv6, enableShort: $enableShort, enableSpeedTest: $enableSpeedTest, preloadDomains: $preloadDomains, keepAliveDomains: $keepAliveDomains, timeout: $timeout, maxCacheTTL: $maxCacheTTL, ispEnable: $ispEnable, speedPort: $speedPort)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DnsConfigImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.accessKeyId, accessKeyId) ||
                other.accessKeyId == accessKeyId) &&
            (identical(other.accessKeySecret, accessKeySecret) ||
                other.accessKeySecret == accessKeySecret) &&
            (identical(other.enableCache, enableCache) ||
                other.enableCache == enableCache) &&
            (identical(other.maxCacheSize, maxCacheSize) ||
                other.maxCacheSize == maxCacheSize) &&
            (identical(other.maxNegativeCache, maxNegativeCache) ||
                other.maxNegativeCache == maxNegativeCache) &&
            (identical(other.enableIPv6, enableIPv6) ||
                other.enableIPv6 == enableIPv6) &&
            (identical(other.enableShort, enableShort) ||
                other.enableShort == enableShort) &&
            (identical(other.enableSpeedTest, enableSpeedTest) ||
                other.enableSpeedTest == enableSpeedTest) &&
            const DeepCollectionEquality()
                .equals(other._preloadDomains, _preloadDomains) &&
            const DeepCollectionEquality()
                .equals(other._keepAliveDomains, _keepAliveDomains) &&
            (identical(other.timeout, timeout) || other.timeout == timeout) &&
            (identical(other.maxCacheTTL, maxCacheTTL) ||
                other.maxCacheTTL == maxCacheTTL) &&
            (identical(other.ispEnable, ispEnable) ||
                other.ispEnable == ispEnable) &&
            (identical(other.speedPort, speedPort) ||
                other.speedPort == speedPort));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      accountId,
      accessKeyId,
      accessKeySecret,
      enableCache,
      maxCacheSize,
      maxNegativeCache,
      enableIPv6,
      enableShort,
      enableSpeedTest,
      const DeepCollectionEquality().hash(_preloadDomains),
      const DeepCollectionEquality().hash(_keepAliveDomains),
      timeout,
      maxCacheTTL,
      ispEnable,
      speedPort);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DnsConfigImplCopyWith<_$DnsConfigImpl> get copyWith =>
      __$$DnsConfigImplCopyWithImpl<_$DnsConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DnsConfigImplToJson(
      this,
    );
  }
}

abstract class _DnsConfig implements DnsConfig {
  const factory _DnsConfig(
      {required final String accountId,
      required final String accessKeyId,
      required final String accessKeySecret,
      final bool enableCache,
      final int maxCacheSize,
      final int maxNegativeCache,
      final bool enableIPv6,
      final bool enableShort,
      final bool enableSpeedTest,
      final List<String> preloadDomains,
      final List<String> keepAliveDomains,
      final int timeout,
      final int maxCacheTTL,
      final bool ispEnable,
      final int speedPort}) = _$DnsConfigImpl;

  factory _DnsConfig.fromJson(Map<String, dynamic> json) =
      _$DnsConfigImpl.fromJson;

  @override

  /// 阿里云控制台的 Account ID
  String get accountId;
  @override

  /// 阿里云 AccessKey ID
  String get accessKeyId;
  @override

  /// 阿里云 AccessKey Secret
  String get accessKeySecret;
  @override

  /// 是否启用缓存
  bool get enableCache;
  @override

  /// 最大缓存大小
  int get maxCacheSize;
  @override

  /// 最大否定缓存时间（秒）
  int get maxNegativeCache;
  @override

  /// 是否启用 IPv6
  bool get enableIPv6;
  @override

  /// 是否启用短连接
  bool get enableShort;
  @override

  /// 是否启用测速功能
  bool get enableSpeedTest;
  @override

  /// 预加载域名列表
  List<String> get preloadDomains;
  @override

  /// 缓存保持域名列表
  List<String> get keepAliveDomains;
  @override

  /// 超时时间（秒）
  int get timeout;
  @override

  /// 最大缓存 TTL 时间（秒）
  int get maxCacheTTL;
  @override

  /// 是否启用 ISP 网络区分
  bool get ispEnable;
  @override

  /// 测速端口
  int get speedPort;
  @override
  @JsonKey(ignore: true)
  _$$DnsConfigImplCopyWith<_$DnsConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
