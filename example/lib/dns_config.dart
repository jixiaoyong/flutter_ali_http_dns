// 阿里云 HttpDNS 公共配置文件
// 此文件包含非敏感的配置信息，可以被 git 追踪
class AliHttpDnsConfig {
  // 其他可选配置
  static const bool enableCache = true;
  static const int maxCacheSize = 100;
  static const bool enableIPv6 = false;
  static const bool enableSpeedTest = true;
  static const int speedPort = 80;
  static const int maxNegativeCache = 30;
  static const int maxCacheTTL = 3600;
  static const bool ispEnable = true;
  static const int timeout = 3;
  
  // 预加载域名列表
  static const List<String> preloadDomains = [
    'www.taobao.com',
    'www.tmall.com',
    'www.alibaba.com',
  ];
  
  // 保持连接的域名列表
  static const List<String> keepAliveDomains = [
    'www.taobao.com',
    'www.tmall.com',
  ];
}
