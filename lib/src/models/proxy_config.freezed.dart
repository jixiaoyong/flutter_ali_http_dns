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
  /// 端口池配置（可选，如果指定则优先使用）
  List<int>? get portPool => throw _privateConstructorUsedError;

  /// 自动分配的起始端口（默认4041）
  int? get startPort => throw _privateConstructorUsedError;

  /// 自动分配的结束端口（可选，必须大于startPort）
  /// 如果未指定，则使用 startPort + 100
  /// 如果指定范围不足，会自动突破范围寻找可用端口
  int? get endPort => throw _privateConstructorUsedError;

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
      {List<int>? portPool,
      int? startPort,
      int? endPort,
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
    Object? portPool = freezed,
    Object? startPort = freezed,
    Object? endPort = freezed,
    Object? enabled = null,
    Object? host = null,
  }) {
    return _then(_value.copyWith(
      portPool: freezed == portPool
          ? _value.portPool
          : portPool // ignore: cast_nullable_to_non_nullable
              as List<int>?,
      startPort: freezed == startPort
          ? _value.startPort
          : startPort // ignore: cast_nullable_to_non_nullable
              as int?,
      endPort: freezed == endPort
          ? _value.endPort
          : endPort // ignore: cast_nullable_to_non_nullable
              as int?,
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
      {List<int>? portPool,
      int? startPort,
      int? endPort,
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
    Object? portPool = freezed,
    Object? startPort = freezed,
    Object? endPort = freezed,
    Object? enabled = null,
    Object? host = null,
  }) {
    return _then(_$ProxyConfigImpl(
      portPool: freezed == portPool
          ? _value._portPool
          : portPool // ignore: cast_nullable_to_non_nullable
              as List<int>?,
      startPort: freezed == startPort
          ? _value.startPort
          : startPort // ignore: cast_nullable_to_non_nullable
              as int?,
      endPort: freezed == endPort
          ? _value.endPort
          : endPort // ignore: cast_nullable_to_non_nullable
              as int?,
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
      {final List<int>? portPool,
      this.startPort,
      this.endPort,
      this.enabled = true,
      this.host = 'localhost'})
      : _portPool = portPool;

  factory _$ProxyConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProxyConfigImplFromJson(json);

  /// 端口池配置（可选，如果指定则优先使用）
  final List<int>? _portPool;

  /// 端口池配置（可选，如果指定则优先使用）
  @override
  List<int>? get portPool {
    final value = _portPool;
    if (value == null) return null;
    if (_portPool is EqualUnmodifiableListView) return _portPool;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// 自动分配的起始端口（默认4041）
  @override
  final int? startPort;

  /// 自动分配的结束端口（可选，必须大于startPort）
  /// 如果未指定，则使用 startPort + 100
  /// 如果指定范围不足，会自动突破范围寻找可用端口
  @override
  final int? endPort;

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
    return 'ProxyConfig(portPool: $portPool, startPort: $startPort, endPort: $endPort, enabled: $enabled, host: $host)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProxyConfigImpl &&
            const DeepCollectionEquality().equals(other._portPool, _portPool) &&
            (identical(other.startPort, startPort) ||
                other.startPort == startPort) &&
            (identical(other.endPort, endPort) || other.endPort == endPort) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.host, host) || other.host == host));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_portPool),
      startPort,
      endPort,
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
      {final List<int>? portPool,
      final int? startPort,
      final int? endPort,
      final bool enabled,
      final String host}) = _$ProxyConfigImpl;

  factory _ProxyConfig.fromJson(Map<String, dynamic> json) =
      _$ProxyConfigImpl.fromJson;

  @override

  /// 端口池配置（可选，如果指定则优先使用）
  List<int>? get portPool;
  @override

  /// 自动分配的起始端口（默认4041）
  int? get startPort;
  @override

  /// 自动分配的结束端口（可选，必须大于startPort）
  /// 如果未指定，则使用 startPort + 100
  /// 如果指定范围不足，会自动突破范围寻找可用端口
  int? get endPort;
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
