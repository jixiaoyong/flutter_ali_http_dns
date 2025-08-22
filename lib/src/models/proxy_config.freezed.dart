// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proxy_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProxyConfig _$ProxyConfigFromJson(Map<String, dynamic> json) {
  return _ProxyConfig.fromJson(json);
}

/// @nodoc
mixin _$ProxyConfig {
  /// 代理服务器端口
  int get port => throw _privateConstructorUsedError;

  /// 端口映射配置
  Map<String, int> get portMap => throw _privateConstructorUsedError;

  /// 固定域名映射
  Map<String, String> get fixedDomain => throw _privateConstructorUsedError;

  /// 是否启用代理
  bool get enabled => throw _privateConstructorUsedError;

  /// 代理服务器地址
  String get host => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProxyConfigCopyWith<ProxyConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProxyConfigCopyWith<$Res> {
  factory $ProxyConfigCopyWith(
          ProxyConfig value, $Res Function(ProxyConfig) then) =
      _$ProxyConfigCopyWithImpl<$Res, ProxyConfig>;
  @useResult
  $Res call(
      {int port,
      Map<String, int> portMap,
      Map<String, String> fixedDomain,
      bool enabled,
      String host});
}

/// @nodoc
class _$ProxyConfigCopyWithImpl<$Res, $Val extends ProxyConfig>
    implements $ProxyConfigCopyWith<$Res> {
  _$ProxyConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? port = null,
    Object? portMap = null,
    Object? fixedDomain = null,
    Object? enabled = null,
    Object? host = null,
  }) {
    return _then(_value.copyWith(
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      portMap: null == portMap
          ? _value.portMap
          : portMap // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      fixedDomain: null == fixedDomain
          ? _value.fixedDomain
          : fixedDomain // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      host: null == host
          ? _value.host
          : host // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProxyConfigImplCopyWith<$Res>
    implements $ProxyConfigCopyWith<$Res> {
  factory _$$ProxyConfigImplCopyWith(
          _$ProxyConfigImpl value, $Res Function(_$ProxyConfigImpl) then) =
      __$$ProxyConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int port,
      Map<String, int> portMap,
      Map<String, String> fixedDomain,
      bool enabled,
      String host});
}

/// @nodoc
class __$$ProxyConfigImplCopyWithImpl<$Res>
    extends _$ProxyConfigCopyWithImpl<$Res, _$ProxyConfigImpl>
    implements _$$ProxyConfigImplCopyWith<$Res> {
  __$$ProxyConfigImplCopyWithImpl(
      _$ProxyConfigImpl _value, $Res Function(_$ProxyConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? port = null,
    Object? portMap = null,
    Object? fixedDomain = null,
    Object? enabled = null,
    Object? host = null,
  }) {
    return _then(_$ProxyConfigImpl(
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      portMap: null == portMap
          ? _value._portMap
          : portMap // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      fixedDomain: null == fixedDomain
          ? _value._fixedDomain
          : fixedDomain // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      host: null == host
          ? _value.host
          : host // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProxyConfigImpl implements _ProxyConfig {
  const _$ProxyConfigImpl(
      {this.port = 4041,
      final Map<String, int> portMap = const {},
      final Map<String, String> fixedDomain = const {},
      this.enabled = true,
      this.host = 'localhost'})
      : _portMap = portMap,
        _fixedDomain = fixedDomain;

  factory _$ProxyConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProxyConfigImplFromJson(json);

  /// 代理服务器端口
  @override
  @JsonKey()
  final int port;

  /// 端口映射配置
  final Map<String, int> _portMap;

  /// 端口映射配置
  @override
  @JsonKey()
  Map<String, int> get portMap {
    if (_portMap is EqualUnmodifiableMapView) return _portMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_portMap);
  }

  /// 固定域名映射
  final Map<String, String> _fixedDomain;

  /// 固定域名映射
  @override
  @JsonKey()
  Map<String, String> get fixedDomain {
    if (_fixedDomain is EqualUnmodifiableMapView) return _fixedDomain;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_fixedDomain);
  }

  /// 是否启用代理
  @override
  @JsonKey()
  final bool enabled;

  /// 代理服务器地址
  @override
  @JsonKey()
  final String host;

  @override
  String toString() {
    return 'ProxyConfig(port: $port, portMap: $portMap, fixedDomain: $fixedDomain, enabled: $enabled, host: $host)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProxyConfigImpl &&
            (identical(other.port, port) || other.port == port) &&
            const DeepCollectionEquality().equals(other._portMap, _portMap) &&
            const DeepCollectionEquality()
                .equals(other._fixedDomain, _fixedDomain) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.host, host) || other.host == host));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      port,
      const DeepCollectionEquality().hash(_portMap),
      const DeepCollectionEquality().hash(_fixedDomain),
      enabled,
      host);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProxyConfigImplCopyWith<_$ProxyConfigImpl> get copyWith =>
      __$$ProxyConfigImplCopyWithImpl<_$ProxyConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProxyConfigImplToJson(
      this,
    );
  }
}

abstract class _ProxyConfig implements ProxyConfig {
  const factory _ProxyConfig(
      {final int port,
      final Map<String, int> portMap,
      final Map<String, String> fixedDomain,
      final bool enabled,
      final String host}) = _$ProxyConfigImpl;

  factory _ProxyConfig.fromJson(Map<String, dynamic> json) =
      _$ProxyConfigImpl.fromJson;

  @override

  /// 代理服务器端口
  int get port;
  @override

  /// 端口映射配置
  Map<String, int> get portMap;
  @override

  /// 固定域名映射
  Map<String, String> get fixedDomain;
  @override

  /// 是否启用代理
  bool get enabled;
  @override

  /// 代理服务器地址
  String get host;
  @override
  @JsonKey(ignore: true)
  _$$ProxyConfigImplCopyWith<_$ProxyConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
