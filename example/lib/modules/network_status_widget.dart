import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

/// 网络状态检测浮窗组件
class NetworkStatusWidget extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const NetworkStatusWidget({
    super.key,
    this.isVisible = true,
    this.onToggleVisibility,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget>
    with TickerProviderStateMixin {
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  String _connectionType = '未知';
  String _ipAddress = '未知';
  bool _isConnected = false;
  Timer? _statusTimer;
  Timer? _pingTimer;
  int _pingLatency = -1;
  int _lastPingTime = 0;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNetworkMonitoring();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startNetworkMonitoring() {
    // 立即检查一次网络状态
    _checkNetworkStatus();
    
    // 每3秒检查一次网络状态
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkNetworkStatus();
    });

    // 每5秒进行一次ping测试
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pingTest();
    });
  }

  Future<void> _checkNetworkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (mounted) {
        setState(() {
          _isConnected = hasConnection;
          _networkStatus = hasConnection ? NetworkStatus.connected : NetworkStatus.disconnected;
        });
        
        if (hasConnection) {
          _getConnectionInfo();
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _networkStatus = NetworkStatus.disconnected;
          _connectionType = '无网络';
          _ipAddress = '未知';
        });
        _animationController.reverse();
      }
    }
  }

  Future<void> _getConnectionInfo() async {
    try {
      // 获取本地IP地址
      final interfaces = await NetworkInterface.list();
      String? localIp;
      
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('en') || 
            interface.name.toLowerCase().contains('wlan')) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && 
                !addr.address.startsWith('127.')) {
              localIp = addr.address;
              break;
            }
          }
          if (localIp != null) break;
        }
      }

      // 获取公网IP地址
      String? publicIp;
      try {
        final response = await HttpClient()
            .getUrl(Uri.parse('https://api.ipify.org'))
            .timeout(const Duration(seconds: 3));
        final result = await response.close();
        final body = await result.transform(utf8.decoder).join();
        publicIp = body.trim();
      } catch (e) {
        // 忽略公网IP获取失败
      }

      if (mounted) {
        setState(() {
          _ipAddress = publicIp ?? localIp ?? '未知';
          _connectionType = _determineConnectionType(interfaces);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionType = '未知';
          _ipAddress = '未知';
        });
      }
    }
  }

  String _determineConnectionType(List<NetworkInterface> interfaces) {
    bool hasWifi = false;
    bool hasCellular = false;
    bool hasEthernet = false;

    for (var interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.contains('wlan') || name.contains('wifi')) {
        hasWifi = true;
      } else if (name.contains('pdp') || name.contains('cellular')) {
        hasCellular = true;
      } else if (name.contains('en') && !name.contains('wlan')) {
        hasEthernet = true;
      }
    }

    if (hasWifi) return 'WiFi';
    if (hasCellular) return '移动网络';
    if (hasEthernet) return '以太网';
    return '未知';
  }

  Future<void> _pingTest() async {
    if (!_isConnected) return;
    
    final stopwatch = Stopwatch()..start();
    try {
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 2));
      stopwatch.stop();
      
      if (mounted && result.isNotEmpty) {
        setState(() {
          _pingLatency = stopwatch.elapsedMilliseconds;
          _lastPingTime = DateTime.now().millisecondsSinceEpoch;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pingLatency = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onToggleVisibility,
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _colorAnimation.value?.withOpacity(0.9) ?? Colors.grey.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 状态指示器
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isConnected ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isConnected ? '已连接' : '未连接',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 连接类型
                    Text(
                      '类型: $_connectionType',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    
                    // IP地址
                    Text(
                      'IP: ${_ipAddress.length > 15 ? '${_ipAddress.substring(0, 15)}...' : _ipAddress}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    
                    // Ping延迟
                    if (_pingLatency > 0)
                      Text(
                        '延迟: ${_pingLatency}ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

/// 网络状态枚举
enum NetworkStatus {
  unknown,
  connected,
  disconnected,
}
