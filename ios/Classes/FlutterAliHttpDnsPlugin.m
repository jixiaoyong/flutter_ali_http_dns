#import "FlutterAliHttpDnsPlugin.h"
#import <Foundation/Foundation.h>
#import "pdns-sdk-ios/DNSResolver.h"

// Debug logging macro that does nothing in release builds
#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"[iOS] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLog(...)
#endif

@implementation FlutterAliHttpDnsPlugin {
    DNSResolver *_dnsResolver;
    BOOL _isInitialized;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                    methodChannelWithName:@"flutter_ali_http_dns"
                                    binaryMessenger:[registrar messenger]];
    FlutterAliHttpDnsPlugin* instance = [[FlutterAliHttpDnsPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    id arguments = call.arguments;
    
    if ([@"initializeDns" isEqualToString:method]) {
        [self initializeDns:arguments result:result];
    } else if ([@"resolveDomain" isEqualToString:method]) {
        [self resolveDomain:arguments result:result];
    } else if ([@"clearCache" isEqualToString:method]) {
        [self clearCache:arguments result:result];
    } else if ([@"setEnableCache" isEqualToString:method]) {
        [self setEnableCache:arguments result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)setEnableCache:(id)arguments result:(FlutterResult)result {
    @try {
        if (!_isInitialized || !_dnsResolver) {
            DLog(@"ERROR: DNS service not initialized, cannot set cache status");
            result([FlutterError errorWithCode:@"NOT_INITIALIZED" 
                                     message:@"DNS service not initialized" 
                                     details:nil]);
            return;
        }
        
        BOOL enable = NO;
        if ([arguments isKindOfClass:[NSDictionary class]]) {
            id enableValue = arguments[@"enable"];
            if ([enableValue isKindOfClass:[NSNumber class]]) {
                enable = [enableValue boolValue];
            }
        }
        
        DLog(@"Setting cache enabled: %s", enable ? "YES" : "NO");
        _dnsResolver.cacheEnable = enable;
        result(nil); // void method returns nil for success
        
    } @catch (NSException *exception) {
        DLog(@"ERROR: Failed to set cache enabled status: %@", exception.reason);
        result([FlutterError errorWithCode:@"SET_CACHE_ERROR" 
                                 message:[NSString stringWithFormat:@"Failed to set cache: %@", exception.reason] 
                                 details:nil]);
    }
}

- (void)initializeDns:(id)arguments result:(FlutterResult)result {
    @try {
        DLog(@"Initializing DNS with arguments: %@", arguments);
        
        NSDictionary *config = nil;
        if ([arguments isKindOfClass:[NSDictionary class]]) {
            config = arguments;
        }
        
        if (!config) {
            DLog(@"ERROR: Invalid configuration format");
            result(@NO);
            return;
        }
        
        DLog(@"Parsed config: %@", config);
        
        _dnsResolver = [DNSResolver share];
        if (!_dnsResolver) {
            DLog(@"ERROR: Failed to get DNSResolver instance");
            result(@NO);
            return;
        }
        
        NSString *accountId = config[@"accountId"] ?: @"";
        NSString *accessKeyId = config[@"accessKeyId"] ?: @"";
        NSString *accessKeySecret = config[@"accessKeySecret"] ?: @"";
        
        DLog(@"Setting up DNS with accountId: %@, accessKeyId: %@", accountId, accessKeyId);
        
        [_dnsResolver setAccountId:accountId andAccessKeyId:accessKeyId andAccesskeySecret:accessKeySecret];
        
        _dnsResolver.scheme = DNSResolverSchemeHttps;
        
        BOOL enableCache = [config[@"enableCache"] boolValue];
        _dnsResolver.cacheEnable = enableCache;
        
        NSNumber *maxCacheSize = config[@"maxCacheSize"];
        if (maxCacheSize) {
            _dnsResolver.cacheCountLimit = [maxCacheSize intValue];
        }
        
        NSNumber *timeout = config[@"timeout"];
        if (timeout) {
            _dnsResolver.timeout = [timeout intValue];
        }
        
        BOOL enableIPv6 = [config[@"enableIPv6"] boolValue];
        _dnsResolver.ipv6Enable = enableIPv6;
        
        BOOL enableSpeedTest = [config[@"enableSpeedTest"] boolValue];
        _dnsResolver.speedTestEnable = enableSpeedTest;
        
        NSNumber *speedPort = config[@"speedPort"];
        if (speedPort) {
            _dnsResolver.speedPort = [speedPort intValue];
        }
        
        NSNumber *maxNegativeCache = config[@"maxNegativeCache"];
        if (maxNegativeCache) {
            _dnsResolver.maxNegativeCache = [maxNegativeCache intValue];
        }
        
        NSNumber *maxCacheTTL = config[@"maxCacheTTL"];
        if (maxCacheTTL) {
            _dnsResolver.maxCacheTTL = [maxCacheTTL intValue];
        }
        
        BOOL ispEnable = [config[@"ispEnable"] boolValue];
        _dnsResolver.ispEnable = ispEnable;
        
        NSArray *keepAliveDomains = config[@"keepAliveDomains"];
        if (keepAliveDomains && [keepAliveDomains isKindOfClass:[NSArray class]]) {
            DLog(@"Setting keep alive domains: %@", keepAliveDomains);
            [_dnsResolver setKeepAliveDomains:keepAliveDomains];
        }
        
        NSArray *preloadDomains = config[@"preloadDomains"];
        if (preloadDomains && [preloadDomains isKindOfClass:[NSArray class]]) {
            DLog(@"Preloading domains: %@", preloadDomains);
            [_dnsResolver preloadDomains:preloadDomains complete:^{
                DLog(@"Preload completed for domains: %@", preloadDomains);
            }];
        }
        
        _isInitialized = YES;
        DLog(@"DNS initialization completed successfully");
        result(@YES);
        
    } @catch (NSException *exception) {
        DLog(@"ERROR: Failed to initialize DNS: %@", exception.reason);
        result([FlutterError errorWithCode:@"INITIALIZATION_ERROR" 
                                 message:[NSString stringWithFormat:@"Failed to initialize DNS: %@", exception.reason] 
                                 details:nil]);
    }
}

- (void)resolveDomain:(id)arguments result:(FlutterResult)result {
    @try {
        if (!_isInitialized) {
            DLog(@"ERROR: DNS service not initialized");
            result([FlutterError errorWithCode:@"NOT_INITIALIZED" 
                                     message:@"DNS service not initialized" 
                                     details:nil]);
            return;
        }
        
        if (!_dnsResolver) {
            DLog(@"ERROR: DNS resolver not available");
            result([FlutterError errorWithCode:@"NOT_INITIALIZED" 
                                     message:@"DNS resolver not available" 
                                     details:nil]);
            return;
        }
        
        NSString *domain = nil;
        if ([arguments isKindOfClass:[NSString class]]) {
            domain = arguments;
        }
        
        if (!domain || [domain length] == 0) {
            DLog(@"ERROR: Domain is required but was not provided");
            result([FlutterError errorWithCode:@"INVALID_ARGUMENT" 
                                     message:@"Domain is required" 
                                     details:nil]);
            return;
        }
        
        DLog(@"Attempting DNS resolution for: %@", domain);
        
        // 使用自动感知网络环境的方法获取IP数组
        [_dnsResolver getIpsDataWithDomain:domain complete:^(NSArray<NSString *> *dataArray) {
            if (dataArray && dataArray.count > 0) {
                // 返回第一个IP地址（可以根据需要选择其他策略）
                NSString *ip = dataArray[0];
                DLog(@"DNS resolution successful: %@ -> %@ (total IPs: %lu)", domain, ip, (unsigned long)dataArray.count);
                DLog(@"All available IPs: %@", [dataArray componentsJoinedByString:@", "]);
                result(ip);
            } else {
                DLog(@"DNS resolution returned empty array for: %@", domain);
                result(nil);
            }
        }];
        
    } @catch (NSException *exception) {
        DLog(@"ERROR: DNS resolution failed for domain '%@': %@", arguments, exception.reason);
        result([FlutterError errorWithCode:@"RESOLUTION_ERROR" 
                                 message:[NSString stringWithFormat:@"DNS resolution failed: %@", exception.reason] 
                                 details:nil]);
    }
}

- (void)clearCache:(id)arguments result:(FlutterResult)result {
    @try {
        if (!_isInitialized || !_dnsResolver) {
            DLog(@"ERROR: DNS service not initialized");
            result(@NO);
            return;
        }
        
        NSArray *hostNames = nil;
        if (arguments != [NSNull null] && [arguments isKindOfClass:[NSArray class]]) {
            hostNames = (NSArray *)arguments;
        }
        
        DLog(@"Clearing DNS cache for: %@", (hostNames && hostNames.count > 0) ? [hostNames componentsJoinedByString:@", "] : @"all hosts");
        
        [_dnsResolver clearHostCache:hostNames];
        
        DLog(@"DNS cache cleared successfully");
        result(@YES);
        
    } @catch (NSException *exception) {
        DLog(@"ERROR: Failed to clear cache: %@", exception.reason);
        result([FlutterError errorWithCode:@"CLEAR_CACHE_ERROR" 
                                 message:[NSString stringWithFormat:@"Failed to clear cache: %@", exception.reason] 
                                 details:nil]);
    }
}

@end
