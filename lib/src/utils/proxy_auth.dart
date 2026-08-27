import 'dart:convert';
import 'dart:math';

/// 代理鉴权凭据。
///
/// 由代理服务器在每次成功启动时生成：
/// - [username] 固定为 `httpdns`
/// - [token] 由 [Random.secure] 生成的 32 字节 hex 字符串（256 位熵）
///
/// 该凭据仅用于宿主 SDK 与本地代理之间的 Basic Auth，
/// 不落盘、不用于任何业务请求。
class ProxyCredentials {
  static const String defaultUsername = 'httpdns';

  /// 407 挑战使用的 realm（与 dart:io HttpClient.addProxyCredentials 预置匹配）。
  static const String realm = 'httpdns-proxy';

  /// 固定用户名。
  final String username;

  /// 随机生成的 token（32 字节 hex）。
  final String token;

  const ProxyCredentials({required this.username, required this.token});

  /// 生成一组新的高熵随机凭据。
  factory ProxyCredentials.generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );
    return ProxyCredentials(
      username: defaultUsername,
      token: bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  /// 用于「服务端验证」的 Auth 头字段名。
  static const String authHeaderName = 'Proxy-Authorization';

  /// 用于响应 407 的「服务端指定挑战」头字段名。
  static const String authenticateHeaderName = 'Proxy-Authenticate';

  /// 生成 `Proxy-Authorization: Basic ...` 头的 value 部分。
  String basicAuthValue() {
    final raw = '$username:$token';
    return 'Basic ${base64Encode(utf8.encode(raw))}';
  }

  /// 生成 `Proxy-Authenticate` 挑战头 value（供 407 响应）。
  String authenticateHeaderValue() {
    return 'Basic realm="$realm"';
  }

  /// 校验传入的 `Proxy-Authorization` 头值是否为「当前凭据的 Basic Auth」。
  bool validate(String? authValue) {
    if (authValue == null) {
      return false;
    }
    return _constantTimeEquals(authValue.trim(), basicAuthValue());
  }

  /// 简单常量时间比较，避免用字符串相等泄露时延信息。
  static bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    if (aBytes.length != bBytes.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < aBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
  }
}