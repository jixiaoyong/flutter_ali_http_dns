import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 调试映射信息的工具类
class DebugMapping {
  static Future<void> debugMapping(int port) async {
    print('=== 调试端口 $port 的映射信息 ===');
    
    try {
      // 获取映射信息
      final mapping = await FlutterAliHttpDns.instance.getMapping(port);
      
      if (mapping != null) {
        print('✅ 找到映射信息:');
        print('   - localPort: ${mapping['localPort']}');
        print('   - targetPort: ${mapping['targetPort']}');
        print('   - targetDomain: ${mapping['targetDomain']}');
        print('   - isSecure: ${mapping['isSecure']}');
        print('   - name: ${mapping['name']}');
        print('   - description: ${mapping['description']}');
        print('   - isActive: ${mapping['isActive']}');
      } else {
        print('❌ 未找到端口 $port 的映射信息');
      }
      
      // 获取所有映射
      print('\n=== 所有映射信息 ===');
      final allMappings = await FlutterAliHttpDns.instance.getAllMappings();
      if (allMappings.isNotEmpty) {
        for (final entry in allMappings.entries) {
          final port = entry.key;
          final mapping = entry.value;
          print('端口 $port:');
          print('   - targetDomain: ${mapping['targetDomain']}');
          print('   - targetPort: ${mapping['targetPort']}');
          print('   - isSecure: ${mapping['isSecure']}');
          print('   - name: ${mapping['name']}');
        }
      } else {
        print('❌ 没有找到任何映射信息');
      }
      
    } catch (e) {
      print('❌ 调试过程中发生错误: $e');
    }
  }
  
  static Future<void> testRegisterAndDebug() async {
    print('=== 测试注册和调试映射 ===');
    
    try {
      // 注册一个不安全的映射
      final localPort = await FlutterAliHttpDns.instance.registerMapping(
        targetPort: 7349,
        targetDomain: 'api.example.com',
        name: 'Test Insecure Mapping',
        description: '测试不安全连接',
        isSecure: false,
      );
      
      if (localPort != null) {
        print('✅ 注册成功，本地端口: $localPort');
        
        // 立即调试这个映射
        await debugMapping(localPort);
      } else {
        print('❌ 注册失败');
      }
      
    } catch (e) {
      print('❌ 测试过程中发生错误: $e');
    }
  }
}
