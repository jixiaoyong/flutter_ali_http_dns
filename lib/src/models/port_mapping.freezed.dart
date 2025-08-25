// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'port_mapping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PortMapping _$PortMappingFromJson(Map<String, dynamic> json) {
  return _PortMapping.fromJson(json);
}

/// @nodoc
mixin _$PortMapping {
  /// 本地端口
  int get localPort => throw _privateConstructorUsedError;

  /// 目标端口（可选，null表示使用原始端口）
  int? get targetPort => throw _privateConstructorUsedError;

  /// 目标域名
  String get targetDomain => throw _privateConstructorUsedError;

  /// 映射名称（可选）
  String? get name => throw _privateConstructorUsedError;

  /// 描述信息（可选）
  String? get description => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// 是否激活
  bool get isActive => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortMappingCopyWith<PortMapping> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortMappingCopyWith<$Res> {
  factory $PortMappingCopyWith(
          PortMapping value, $Res Function(PortMapping) then) =
      _$PortMappingCopyWithImpl<$Res, PortMapping>;
  @useResult
  $Res call(
      {int localPort,
      int? targetPort,
      String targetDomain,
      String? name,
      String? description,
      DateTime? createdAt,
      bool isActive});
}

/// @nodoc
class _$PortMappingCopyWithImpl<$Res, $Val extends PortMapping>
    implements $PortMappingCopyWith<$Res> {
  _$PortMappingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localPort = null,
    Object? targetPort = freezed,
    Object? targetDomain = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? createdAt = freezed,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      localPort: null == localPort
          ? _value.localPort
          : localPort // ignore: cast_nullable_to_non_nullable
              as int,
      targetPort: freezed == targetPort
          ? _value.targetPort
          : targetPort // ignore: cast_nullable_to_non_nullable
              as int?,
      targetDomain: null == targetDomain
          ? _value.targetDomain
          : targetDomain // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortMappingImplCopyWith<$Res>
    implements $PortMappingCopyWith<$Res> {
  factory _$$PortMappingImplCopyWith(
          _$PortMappingImpl value, $Res Function(_$PortMappingImpl) then) =
      __$$PortMappingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int localPort,
      int? targetPort,
      String targetDomain,
      String? name,
      String? description,
      DateTime? createdAt,
      bool isActive});
}

/// @nodoc
class __$$PortMappingImplCopyWithImpl<$Res>
    extends _$PortMappingCopyWithImpl<$Res, _$PortMappingImpl>
    implements _$$PortMappingImplCopyWith<$Res> {
  __$$PortMappingImplCopyWithImpl(
      _$PortMappingImpl _value, $Res Function(_$PortMappingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localPort = null,
    Object? targetPort = freezed,
    Object? targetDomain = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? createdAt = freezed,
    Object? isActive = null,
  }) {
    return _then(_$PortMappingImpl(
      localPort: null == localPort
          ? _value.localPort
          : localPort // ignore: cast_nullable_to_non_nullable
              as int,
      targetPort: freezed == targetPort
          ? _value.targetPort
          : targetPort // ignore: cast_nullable_to_non_nullable
              as int?,
      targetDomain: null == targetDomain
          ? _value.targetDomain
          : targetDomain // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortMappingImpl implements _PortMapping {
  const _$PortMappingImpl(
      {required this.localPort,
      this.targetPort,
      required this.targetDomain,
      this.name,
      this.description,
      this.createdAt,
      this.isActive = true});

  factory _$PortMappingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortMappingImplFromJson(json);

  /// 本地端口
  @override
  final int localPort;

  /// 目标端口（可选，null表示使用原始端口）
  @override
  final int? targetPort;

  /// 目标域名
  @override
  final String targetDomain;

  /// 映射名称（可选）
  @override
  final String? name;

  /// 描述信息（可选）
  @override
  final String? description;

  /// 创建时间
  @override
  final DateTime? createdAt;

  /// 是否激活
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'PortMapping(localPort: $localPort, targetPort: $targetPort, targetDomain: $targetDomain, name: $name, description: $description, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortMappingImpl &&
            (identical(other.localPort, localPort) ||
                other.localPort == localPort) &&
            (identical(other.targetPort, targetPort) ||
                other.targetPort == targetPort) &&
            (identical(other.targetDomain, targetDomain) ||
                other.targetDomain == targetDomain) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, localPort, targetPort,
      targetDomain, name, description, createdAt, isActive);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortMappingImplCopyWith<_$PortMappingImpl> get copyWith =>
      __$$PortMappingImplCopyWithImpl<_$PortMappingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortMappingImplToJson(
      this,
    );
  }
}

abstract class _PortMapping implements PortMapping {
  const factory _PortMapping(
      {required final int localPort,
      final int? targetPort,
      required final String targetDomain,
      final String? name,
      final String? description,
      final DateTime? createdAt,
      final bool isActive}) = _$PortMappingImpl;

  factory _PortMapping.fromJson(Map<String, dynamic> json) =
      _$PortMappingImpl.fromJson;

  @override

  /// 本地端口
  int get localPort;
  @override

  /// 目标端口（可选，null表示使用原始端口）
  int? get targetPort;
  @override

  /// 目标域名
  String get targetDomain;
  @override

  /// 映射名称（可选）
  String? get name;
  @override

  /// 描述信息（可选）
  String? get description;
  @override

  /// 创建时间
  DateTime? get createdAt;
  @override

  /// 是否激活
  bool get isActive;
  @override
  @JsonKey(ignore: true)
  _$$PortMappingImplCopyWith<_$PortMappingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
