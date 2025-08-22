import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_ali_http_dns_method_channel.dart';
import 'src/models/dns_config.dart';

abstract class FlutterAliHttpDnsPlatform extends PlatformInterface {
  /// Constructs a FlutterAliHttpDnsPlatform.
  FlutterAliHttpDnsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAliHttpDnsPlatform _instance = MethodChannelFlutterAliHttpDns();

  /// The default instance of [FlutterAliHttpDnsPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAliHttpDns].
  static FlutterAliHttpDnsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAliHttpDnsPlatform] when
  /// they register themselves.
  static set instance(FlutterAliHttpDnsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 初始化 DNS 服务
  Future<bool> initializeDns(DnsConfig config) {
    throw UnimplementedError('initializeDns() has not been implemented.');
  }

  /// 解析域名
  Future<String?> resolveDomain(String domain) {
    throw UnimplementedError('resolveDomain() has not been implemented.');
  }
}
