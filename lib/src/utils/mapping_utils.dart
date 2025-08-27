import '../utils/logger.dart';

/// 映射工具类
/// 提供域名映射和端口映射的通用逻辑
class MappingUtils {
  /// 应用域名映射
  /// 
  /// [host] 原始域名
  /// [port] 端口号
  /// [proxyServer] 代理服务器实例（用于获取映射）
  /// 返回映射后的域名
  static String applyDomainMapping(String host, int port, dynamic proxyServer) {
    // 1. 如果请求包含明确域名，直接返回（Dio场景）
    if (host != '127.0.0.1' && host != 'localhost') {
      return host;
    }

    // 2. 如果是localhost，查找动态端口映射
    final dynamicMapping = proxyServer.getMapping(port);
    if (dynamicMapping != null && dynamicMapping.targetDomain.isNotEmpty) {
      Logger.info(
          'Applied dynamic domain mapping: $host:$port -> ${dynamicMapping.targetDomain}');
      return dynamicMapping.targetDomain;
    }

    // 3. 没有映射，返回原始域名
    Logger.warning(
        'No domain mapping found for $host:$port, using original host');
    return host;
  }

  /// 应用端口映射
  /// 
  /// [port] 原始端口
  /// [proxyServer] 代理服务器实例（用于获取映射）
  /// 返回映射后的端口
  static int applyPortMapping(int port, dynamic proxyServer) {
    final originalPort = port;

    // 查找动态端口映射
    final dynamicMapping = proxyServer.getMapping(port);
    if (dynamicMapping != null && dynamicMapping.targetPort != null) {
      Logger.info(
          'Applied dynamic port mapping: $originalPort -> ${dynamicMapping.targetPort}');
      return dynamicMapping.targetPort!;
    }

    // 没有映射或targetPort为null，返回原始端口
    Logger.debug(
        'No port mapping found for $originalPort, using original port');
    return port;
  }

  /// 应用域名和端口映射
  /// 
  /// [host] 原始域名
  /// [port] 原始端口
  /// [proxyServer] 代理服务器实例（用于获取映射）
  /// 返回映射结果，包含映射后的域名和端口
  static MapMappingResult applyMapping(String host, int port, dynamic proxyServer) {
    // 获取映射信息（只调用一次）
    final dynamicMapping = proxyServer.getMapping(port);
    
    Logger.debug('Mapping lookup for port $port: ${dynamicMapping?.toString()}');
    Logger.debug('isSecure from mapping: ${dynamicMapping?.isSecure}');
    
    final mappedHost = applyDomainMapping(host, port, proxyServer);
    final mappedPort = applyPortMapping(port, proxyServer);
    
    // 从映射中获取安全连接设置
    final isSecure = dynamicMapping?.isSecure ?? true; // 默认使用安全连接
    
    Logger.debug('Final isSecure value: $isSecure');
    
    return MapMappingResult(
      originalHost: host,
      originalPort: port,
      mappedHost: mappedHost,
      mappedPort: mappedPort,
      isSecure: isSecure,
    );
  }
}

/// 映射结果类
class MapMappingResult {
  final String originalHost;
  final int originalPort;
  final String mappedHost;
  final int mappedPort;
  final bool? isSecure;

  const MapMappingResult({
    required this.originalHost,
    required this.originalPort,
    required this.mappedHost,
    required this.mappedPort,
    this.isSecure,
  });

  @override
  String toString() {
    return 'MapMappingResult($originalHost:$originalPort -> $mappedHost:$mappedPort)';
  }
}
