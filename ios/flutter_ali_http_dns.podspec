#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_ali_http_dns.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_ali_http_dns'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for Alibaba Cloud HttpDNS integration with proxy server support.'
  s.description      = <<-DESC
A Flutter plugin for Alibaba Cloud HttpDNS integration with proxy server support.
                       DESC
  s.homepage         = 'https://github.com/jixiaoyong/flutter_ali_http_dns'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m}'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/AlicloudPDNS/pdns-sdk-ios.framework/Headers',
    'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/AlicloudPDNS',
    'ONLY_ACTIVE_ARCH' => 'YES'
  }
  s.swift_version = '5.0'
  
  # 阿里云 HttpDNS SDK 依赖
  s.dependency 'AlicloudPDNS'
  
  # 处理静态框架依赖问题
  s.static_framework = true
  
  # 用户目标的 xcconfig 设置，处理模拟器兼容性
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end
