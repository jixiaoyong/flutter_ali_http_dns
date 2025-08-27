import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// Nakama服务器配置
class NakamaConfig {
  /// Nakama服务器基础URL
  static const String nakamaBaseUrl = 'api.example.com';
  
  /// Nakama HTTP端口
  static const int nakamaPortHttp = 7350;
  
  /// Nakama gRPC端口（不安全连接）
  static const int nakamaPortGrpc = 7349;
  
  /// Nakama WebSocket端口
  static const int nakamaPortWs = 7350;
  
  /// 获取Nakama HTTP URL
  static String get nakamaHttpUrl => 'http://$nakamaBaseUrl:$nakamaPortHttp';
  
  /// 获取Nakama gRPC URL（不安全连接）
  static String get nakamaGrpcUrl => 'http://$nakamaBaseUrl:$nakamaPortGrpc';
  
  /// 获取Nakama WebSocket URL
  static String get nakamaWsUrl => 'ws://$nakamaBaseUrl:$nakamaPortWs';
  
  /// 示例：如何注册不安全的gRPC连接
  static Future<int?> registerInsecureGrpcMapping() async {
    // 对于只支持HTTP的gRPC服务，设置isSecure: false
    return await FlutterAliHttpDns.instance.registerMapping(
      targetPort: nakamaPortGrpc,
      targetDomain: nakamaBaseUrl,
      name: 'Nakama gRPC (Insecure)',
      description: 'Nakama gRPC服务 - 不安全连接',
      isSecure: false, // 关键：设置为false表示使用HTTP而不是HTTPS
    );
  }
  
  /// 示例：如何注册安全的HTTP连接
  static Future<int?> registerSecureHttpMapping() async {
    // 对于支持HTTPS的服务，使用默认的isSecure: true
    return await FlutterAliHttpDns.instance.registerMapping(
      targetPort: nakamaPortHttp,
      targetDomain: nakamaBaseUrl,
      name: 'Nakama HTTP (Secure)',
      description: 'Nakama HTTP服务 - 安全连接',
      isSecure: true, // 默认值，可以省略
    );
  }
  
  /// 验证配置是否有效
  static bool isValid() {
    return nakamaBaseUrl.isNotEmpty && 
           nakamaBaseUrl != '*' && 
           nakamaPortHttp > 0 && 
           nakamaPortGrpc > 0;
  }
}
