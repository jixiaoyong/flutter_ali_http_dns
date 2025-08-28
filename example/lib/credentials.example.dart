// 阿里云 HttpDNS 认证信息配置文件示例
// 请复制此文件为 credentials.dart 并替换为您的实际认证信息
class AliHttpDnsCredentials {
  // 阿里云控制台的 Account ID
  // 获取方式：登录阿里云控制台 -> 右上角头像 -> 安全设置 -> 查看Account ID
  static const String accountId = '9999';
  
  // 阿里云 AccessKey ID
  // 获取方式：登录阿里云控制台 -> 右上角头像 -> AccessKey 管理 -> 创建AccessKey
  static const String accessKeyId = 'your_access_key_id';
  
  // 阿里云 AccessKey Secret
  // 获取方式：登录阿里云控制台 -> 右上角头像 -> AccessKey 管理 -> 创建AccessKey
  static const String accessKeySecret = 'your_access_key_secret';
  
  /// 检查认证信息是否已配置
  static bool get isConfigured {
    return accountId != '9999' && 
           accessKeyId != 'your_access_key_id' && 
           accessKeySecret != 'your_access_key_secret';
  }
  
  /// 获取配置状态描述
  static String get configurationStatus {
    if (isConfigured) {
      return '已配置';
    } else {
      return '未配置 - 请复制 credentials.example.dart 为 credentials.dart 并填入真实认证信息';
    }
  }
  
  /// 验证认证信息格式
  static String? validateCredentials() {
    if (accountId == '9999') {
      return 'Account ID 未配置';
    }
    if (accessKeyId == 'your_access_key_id') {
      return 'AccessKey ID 未配置';
    }
    if (accessKeySecret == 'your_access_key_secret') {
      return 'AccessKey Secret 未配置';
    }
    if (accountId.length < 10) {
      return 'Account ID 格式不正确';
    }
    if (accessKeyId.length < 10) {
      return 'AccessKey ID 格式不正确';
    }
    if (accessKeySecret.length < 10) {
      return 'AccessKey Secret 格式不正确';
    }
    return null;
  }
}
