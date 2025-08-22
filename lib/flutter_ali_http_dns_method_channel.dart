import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_ali_http_dns_platform_interface.dart';
import 'src/models/dns_config.dart';
import 'src/utils/logger.dart';

/// An implementation of [FlutterAliHttpDnsPlatform] that uses method channels.
class MethodChannelFlutterAliHttpDns extends FlutterAliHttpDnsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ali_http_dns');

  @override
  Future<bool> initializeDns(DnsConfig config) async {
    try {
      final configJson = config.toJson();
      Logger.debug('Sending config to native: $configJson');
      
      final result = await methodChannel.invokeMethod<bool>(
        'initializeDns',
        configJson,
      );
      
      Logger.debug('Native initialization result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Failed to initialize DNS: ${e.message}');
      Logger.debug('Error code: ${e.code}');
      Logger.debug('Error details: ${e.details}');
      return false;
    } catch (e) {
      Logger.error('Unexpected error during initialization: $e');
      return false;
    }
  }

  @override
  Future<String?> resolveDomain(String domain) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'resolveDomain',
        {'domain': domain},
      );
      return result;
    } on PlatformException catch (e) {
      Logger.error('Failed to resolve domain: ${e.message}');
      return null;
    }
  }
}
