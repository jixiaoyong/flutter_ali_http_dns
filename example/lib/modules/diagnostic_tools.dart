import 'dart:io';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns_example/credentials.dart';

/// 诊断工具 - 帮助用户检查HTTP DNS配置和网络环境
class DiagnosticTools {
  static const List<String> _testDomains = [
    'www.aliyun.com',
    'www.taobao.com',
    'www.tmall.com',
    'www.baidu.com',
    'www.qq.com',
  ];

  /// 运行完整诊断
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    // 1. 检查认证信息
    results['credentials'] = await _checkCredentials();
    
    // 2. 检查网络连接
    results['network'] = await _checkNetwork();
    
    // 3. 检查系统DNS
    results['systemDns'] = await _checkSystemDns();
    
    // 4. 检查HTTP DNS服务
    results['httpDns'] = await _checkHttpDns();
    
    return results;
  }

  /// 检查认证信息
  static Future<Map<String, dynamic>> _checkCredentials() async {
    final result = <String, dynamic>{};
    
    try {
      result['accountId'] = {
        'value': AliHttpDnsCredentials.accountId,
        'length': AliHttpDnsCredentials.accountId.length,
        'valid': AliHttpDnsCredentials.accountId.isNotEmpty && AliHttpDnsCredentials.accountId != '9999',
      };
      
      result['accessKeyId'] = {
        'value': AliHttpDnsCredentials.accessKeyId,
        'length': AliHttpDnsCredentials.accessKeyId.length,
        'valid': AliHttpDnsCredentials.accessKeyId.isNotEmpty && AliHttpDnsCredentials.accessKeyId != 'your_access_key_id',
      };
      
      result['accessKeySecret'] = {
        'value': AliHttpDnsCredentials.accessKeySecret,
        'length': AliHttpDnsCredentials.accessKeySecret.length,
        'valid': AliHttpDnsCredentials.accessKeySecret.isNotEmpty && AliHttpDnsCredentials.accessKeySecret != 'your_access_key_secret',
      };
      
      result['overall'] = result['accountId']['valid'] && 
                         result['accessKeyId']['valid'] && 
                         result['accessKeySecret']['valid'];
    } catch (e) {
      result['error'] = e.toString();
      result['overall'] = false;
    }
    
    return result;
  }

  /// 检查网络连接
  static Future<Map<String, dynamic>> _checkNetwork() async {
    final result = <String, dynamic>{};
    
    try {
      // 测试基本网络连接
      final addresses = await InternetAddress.lookup('8.8.8.8');
      result['basicConnectivity'] = addresses.isNotEmpty;
      
      // 测试DNS服务器连接
      final dnsAddresses = await InternetAddress.lookup('223.5.5.5'); // 阿里DNS
      result['dnsConnectivity'] = dnsAddresses.isNotEmpty;
      
      // 测试HTTP连接
      try {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('https://www.aliyun.com'));
        final response = await request.close();
        result['httpConnectivity'] = response.statusCode == 200;
        client.close();
      } catch (e) {
        result['httpConnectivity'] = false;
        result['httpError'] = e.toString();
      }
      
      result['overall'] = result['basicConnectivity'] && result['dnsConnectivity'];
    } catch (e) {
      result['error'] = e.toString();
      result['overall'] = false;
    }
    
    return result;
  }

  /// 检查系统DNS
  static Future<Map<String, dynamic>> _checkSystemDns() async {
    final result = <String, dynamic>{};
    final domainResults = <String, dynamic>{};
    
    try {
      for (final domain in _testDomains) {
        try {
          final addresses = await InternetAddress.lookup(domain);
          domainResults[domain] = {
            'success': true,
            'ips': addresses.map((a) => a.address).toList(),
            'count': addresses.length,
          };
        } catch (e) {
          domainResults[domain] = {
            'success': false,
            'error': e.toString(),
          };
        }
      }
      
      result['domains'] = domainResults;
      result['successCount'] = domainResults.values.where((r) => r['success'] == true).length;
      result['totalCount'] = _testDomains.length;
      result['successRate'] = (result['successCount'] / result['totalCount'] * 100).toStringAsFixed(1);
      result['overall'] = result['successCount'] > 0;
    } catch (e) {
      result['error'] = e.toString();
      result['overall'] = false;
    }
    
    return result;
  }

  /// 检查HTTP DNS服务
  static Future<Map<String, dynamic>> _checkHttpDns() async {
    final result = <String, dynamic>{};
    
    try {
      // 创建DNS服务实例进行测试
      final dnsService = FlutterAliHttpDns();
      
      // 配置
      final config = DnsConfig(
        accountId: AliHttpDnsCredentials.accountId,
        accessKeyId: AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
        enableCache: false, // 禁用缓存以便测试
        timeout: 10,
      );
      
      // 尝试初始化
      final initSuccess = await dnsService.initialize(config);
      result['initialization'] = {
        'success': initSuccess,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (initSuccess) {
        // 测试域名解析
        final domainResults = <String, dynamic>{};
        
        for (final domain in _testDomains) {
          try {
            final ip = await dnsService.resolveDomain(domain);
            domainResults[domain] = {
              'success': ip != domain && ip.isNotEmpty,
              'result': ip,
              'isOriginalDomain': ip == domain,
            };
          } catch (e) {
            domainResults[domain] = {
              'success': false,
              'error': e.toString(),
            };
          }
        }
        
        result['domains'] = domainResults;
        result['successCount'] = domainResults.values.where((r) => r['success'] == true).length;
        result['totalCount'] = _testDomains.length;
        result['successRate'] = (result['successCount'] / result['totalCount'] * 100).toStringAsFixed(1);
        result['overall'] = result['successCount'] > 0;
        
        // 清理资源
        await dnsService.dispose();
      } else {
        result['overall'] = false;
        result['error'] = 'DNS服务初始化失败';
      }
    } catch (e) {
      result['error'] = e.toString();
      result['overall'] = false;
    }
    
    return result;
  }

  /// 生成诊断报告
  static String generateReport(Map<String, dynamic> diagnostic) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== HTTP DNS 诊断报告 ===');
    buffer.writeln('生成时间: ${DateTime.now().toString()}');
    buffer.writeln();
    
    // 认证信息
    final credentials = diagnostic['credentials'] as Map<String, dynamic>;
    buffer.writeln('1. 认证信息检查:');
    buffer.writeln('   Account ID: ${credentials['accountId']['valid'] ? '✅' : '❌'} ${credentials['accountId']['value']}');
    buffer.writeln('   AccessKey ID: ${credentials['accessKeyId']['valid'] ? '✅' : '❌'} ${credentials['accessKeyId']['value']}');
    buffer.writeln('   AccessKey Secret: ${credentials['accessKeySecret']['valid'] ? '✅' : '❌'} [已隐藏]');
    buffer.writeln('   总体状态: ${credentials['overall'] ? '✅ 正常' : '❌ 异常'}');
    buffer.writeln();
    
    // 网络连接
    final network = diagnostic['network'] as Map<String, dynamic>;
    buffer.writeln('2. 网络连接检查:');
    buffer.writeln('   基本连接: ${network['basicConnectivity'] ? '✅' : '❌'}');
    buffer.writeln('   DNS连接: ${network['dnsConnectivity'] ? '✅' : '❌'}');
    buffer.writeln('   HTTP连接: ${network['httpConnectivity'] ? '✅' : '❌'}');
    buffer.writeln('   总体状态: ${network['overall'] ? '✅ 正常' : '❌ 异常'}');
    buffer.writeln();
    
    // 系统DNS
    final systemDns = diagnostic['systemDns'] as Map<String, dynamic>;
    buffer.writeln('3. 系统DNS检查:');
    buffer.writeln('   成功率: ${systemDns['successRate']}% (${systemDns['successCount']}/${systemDns['totalCount']})');
    buffer.writeln('   总体状态: ${systemDns['overall'] ? '✅ 正常' : '❌ 异常'}');
    buffer.writeln();
    
    // HTTP DNS
    final httpDns = diagnostic['httpDns'] as Map<String, dynamic>;
    buffer.writeln('4. HTTP DNS检查:');
    if (httpDns['initialization'] != null) {
      buffer.writeln('   初始化: ${httpDns['initialization']['success'] ? '✅ 成功' : '❌ 失败'}');
      if (httpDns['domains'] != null) {
        buffer.writeln('   解析成功率: ${httpDns['successRate']}% (${httpDns['successCount']}/${httpDns['totalCount']})');
      }
    }
    buffer.writeln('   总体状态: ${httpDns['overall'] ? '✅ 正常' : '❌ 异常'}');
    buffer.writeln();
    
    // 建议
    buffer.writeln('5. 建议:');
    if (!credentials['overall']) {
      buffer.writeln('   - 请检查认证信息配置是否正确');
    }
    if (!network['overall']) {
      buffer.writeln('   - 请检查网络连接是否正常');
    }
    if (!systemDns['overall']) {
      buffer.writeln('   - 系统DNS解析异常，请检查网络设置');
    }
    if (!httpDns['overall']) {
      buffer.writeln('   - HTTP DNS服务异常，可能的原因：');
      buffer.writeln('     * 认证信息权限不足');
      buffer.writeln('     * 网络环境限制（企业网络、VPN等）');
      buffer.writeln('     * 阿里云HTTP DNS服务暂时不可用');
    }
    if (credentials['overall'] && network['overall'] && systemDns['overall'] && httpDns['overall']) {
      buffer.writeln('   - 所有检查通过，HTTP DNS服务正常工作');
    }
    
    return buffer.toString();
  }
}
