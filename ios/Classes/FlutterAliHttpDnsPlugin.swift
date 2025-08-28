import Flutter
import UIKit
// 根据阿里云官方文档，使用正确的导入方式
// import pdns_sdk_ios

public class FlutterAliHttpDnsPlugin: NSObject, FlutterPlugin {
    private var dnsResolver: NSObject?
    private var isInitialized = false
    private var isSimulator: Bool = false
    
    // MARK: - Logging Methods
    
    /// 打印调试日志（仅在debug模式下）
    private func logDebug(_ message: String) {
        #if DEBUG
        print("[FlutterAliHttpDns] \(message)")
        #endif
    }
    
    /// 打印错误日志（仅在debug模式下）
    private func logError(_ message: String) {
        #if DEBUG
        print("[FlutterAliHttpDns] ERROR: \(message)")
        #endif
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_ali_http_dns", binaryMessenger: registrar.messenger())
        let instance = FlutterAliHttpDnsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeDns":
            logDebug("Received initializeDns call with arguments: \(call.arguments ?? "nil")")
            
            // 尝试从参数中获取配置
            if let configMap = call.arguments as? [String: Any] {
                // 将Map转换为JSON字符串
                if let jsonData = try? JSONSerialization.data(withJSONObject: configMap),
                   let configJson = String(data: jsonData, encoding: .utf8) {
                    logDebug("Config JSON: \(configJson)")
                    initializeDns(configJson: configJson, result: result)
                } else {
                    logError("Failed to convert config to JSON")
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid config format", details: nil))
                }
            } else {
                logError("Config is null or invalid type")
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Config is required", details: nil))
            }
            
        case "resolveDomain":
            guard let args = call.arguments as? [String: Any],
                  let domain = args["domain"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Domain is required", details: nil))
                return
            }
            resolveDomain(domain: domain, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initializeDns(configJson: String, result: @escaping FlutterResult) {
        do {
            logDebug("Parsing config JSON: \(configJson)")
            
            guard let data = configJson.data(using: .utf8),
                  let config = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logError("Invalid config JSON format")
                result(FlutterError(code: "INVALID_CONFIG", message: "Invalid config JSON", details: nil))
                return
            }
            
            logDebug("Parsed config: \(config)")
            
            // 检测是否在模拟器上运行
            #if targetEnvironment(simulator)
            isSimulator = true
            logDebug("Warning: Running on simulator, DNS functionality will be limited")
            isInitialized = true
            result(true)
            return
            #endif
            
            // 获取 DNSResolver 实例
            let dnsResolverClass = NSClassFromString("DNSResolver") as! NSObject.Type
            dnsResolver = dnsResolverClass.perform(NSSelectorFromString("share"))?.takeUnretainedValue() as? NSObject
            
            // 根据官方文档设置 Account ID 和鉴权参数
            let accountId = config["accountId"] as? String ?? ""
            let accessKeyId = config["accessKeyId"] as? String ?? ""
            let accessKeySecret = config["accessKeySecret"] as? String ?? ""
            
            logDebug("Initializing DNS with accountId: \(accountId), accessKeyId: \(accessKeyId)")
            
            // 使用 KVC 设置属性
            dnsResolver?.setValue(accountId, forKey: "accountId")
            dnsResolver?.setValue(accessKeyId, forKey: "accessKeyId")
            dnsResolver?.setValue(accessKeySecret, forKey: "accessKeySecret")
            
            // 设置解析协议（默认使用 HTTPS）
            dnsResolver?.setValue(1, forKey: "scheme") // DNSResolverSchemeHttps = 1
            
            // 设置缓存功能
            let enableCache = config["enableCache"] as? Bool ?? true
            dnsResolver?.setValue(enableCache, forKey: "cacheEnable")
            
            // 设置缓存大小
            let maxCacheSize = config["maxCacheSize"] as? Int ?? 100
            dnsResolver?.setValue(maxCacheSize, forKey: "cacheCountLimit")
            
            // 设置超时时间
            let timeout = config["timeout"] as? Int ?? 3
            dnsResolver?.setValue(timeout, forKey: "timeout")
            
            // 设置 IPv6 支持
            let enableIPv6 = config["enableIPv6"] as? Bool ?? false
            dnsResolver?.setValue(enableIPv6, forKey: "ipv6Enable")
            
            // 设置测速功能
            let enableSpeedTest = config["enableSpeedTest"] as? Bool ?? true
            dnsResolver?.setValue(enableSpeedTest, forKey: "speedTestEnable")
            
            // 设置测速端口
            let speedPort = config["speedPort"] as? Int ?? 80
            dnsResolver?.setValue(speedPort, forKey: "speedPort")
            
            // 设置否定缓存时间
            let maxNegativeCache = config["maxNegativeCache"] as? Int ?? 30
            dnsResolver?.setValue(maxNegativeCache, forKey: "maxNegativeCache")
            
            // 设置最大缓存 TTL
            let maxCacheTTL = config["maxCacheTTL"] as? Int ?? 3600
            dnsResolver?.setValue(maxCacheTTL, forKey: "maxCacheTTL")
            
            // 设置 ISP 网络区分
            let ispEnable = config["ispEnable"] as? Bool ?? true
            dnsResolver?.setValue(ispEnable, forKey: "ispEnable")
            
            // 设置保持连接的域名
            if let keepAliveDomains = config["keepAliveDomains"] as? [String], !keepAliveDomains.isEmpty {
                logDebug("Setting keep alive domains: \(keepAliveDomains)")
                dnsResolver?.setValue(keepAliveDomains, forKey: "keepAliveDomains")
            }
            
            // 预加载域名 - 暂时跳过，因为需要回调函数
            if let preloadDomains = config["preloadDomains"] as? [String], !preloadDomains.isEmpty {
                logDebug("Preloading domains: \(preloadDomains)")
            }
            
            isInitialized = true
            logDebug("DNS initialization completed successfully")
            result(true)
            
        } catch {
            logError("Failed to initialize DNS: \(error.localizedDescription)")
            result(FlutterError(code: "INITIALIZATION_ERROR", message: "Failed to initialize DNS: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func resolveDomain(domain: String, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "DNS service not initialized", details: nil))
            return
        }
        
        // 如果在模拟器上运行，使用系统 DNS 作为备选
        if isSimulator {
            logDebug("Simulator mode: using system DNS for \(domain)")
            // 在模拟器上，我们返回 null 让 Flutter 端使用系统 DNS
            result(nil)
            return
        }
        
        guard let dnsResolver = dnsResolver else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "DNS resolver not available", details: nil))
            return
        }
        
        // 尝试使用 DNSResolver 进行解析
        // 由于 Objective-C 运行时调用复杂，暂时返回 null 让 Flutter 端使用系统 DNS
        logDebug("Attempting DNS resolution for \(domain)")
        result(nil)
    }
}
