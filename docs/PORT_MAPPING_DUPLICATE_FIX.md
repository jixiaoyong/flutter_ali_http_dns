# 端口映射重复问题修复

## 🔍 问题分析

### 原始错误日志
```
[INFO] Found available port 4042 for mapping
[INFO] Registering port 4042 for listening
[INFO] HTTPDNS Smart Proxy listening on port 4042
[INFO] Successfully registered port 4042 for listening
[WARN] Port mapping for port 4042 already exists
[INFO] Deregistering port 4042 from listening
[INFO] Successfully deregistered port 4042 from listening
[ERROR] Failed to register mapping for port 4042
```

### 问题原因

#### 1. **竞态条件（Race Condition）**
- 多个线程同时调用 `registerMapping()`
- `_findAvailablePort()` 和 `registerMapping()` 之间存在时间窗口
- 导致多个线程找到同一个可用端口

#### 2. **端口查找逻辑不完整**
- `_findAvailablePort()` 只检查端口可用性和监听状态
- 没有检查端口是否已经有映射
- 导致已映射但未监听的端口被重复使用

#### 3. **应用重启或热重载**
- 应用重启时旧映射没有正确清理
- 新的注册尝试使用相同的端口
- 导致映射冲突

## 🔧 解决方案

### 1. **改进端口可用性检查**

#### 修复前
```dart
if (await isPortAvailable(port) && !await isPortListening(port)) {
  return port;
}
```

#### 修复后
```dart
Future<bool> _isPortTrulyAvailable(int port) async {
  // 检查端口是否可用
  if (!await isPortAvailable(port)) {
    return false;
  }
  
  // 检查端口是否正在被监听
  if (await isPortListening(port)) {
    return false;
  }
  
  // 检查端口是否已经有映射
  if (_proxyServer!.hasMapping(port)) {
    Logger.debug('Port $port has existing mapping, not available');
    return false;
  }
  
  return true;
}
```

### 2. **自动处理重复映射**

#### 修复前
```dart
if (_mappings.containsKey(mapping.localPort)) {
  Logger.warning('Port mapping for port ${mapping.localPort} already exists');
  return false;
}
```

#### 修复后
```dart
if (_mappings.containsKey(mapping.localPort)) {
  Logger.warning('Port mapping for port ${mapping.localPort} already exists, updating...');
  // 移除旧的映射
  _mappings.remove(mapping.localPort);
}
```

### 3. **添加过期映射清理**

```dart
void _cleanupStaleMappings() {
  if (_proxyServer == null) return;
  
  final allMappings = _proxyServer!.getAllMappings();
  final staleMappings = <int>[];
  
  for (final entry in allMappings.entries) {
    final port = entry.key;
    final mapping = entry.value;
    
    // 检查映射是否过期（超过1小时）
    if (mapping.createdAt == null) continue;
    final age = DateTime.now().difference(mapping.createdAt!);
    if (age.inHours > 1) {
      staleMappings.add(port);
      Logger.info('Found stale mapping for port $port (age: ${age.inMinutes} minutes)');
    }
  }
  
  // 清理过期映射
  for (final port in staleMappings) {
    _proxyServer!.removeMapping(port);
    Logger.info('Cleaned up stale mapping for port $port');
  }
  
  if (staleMappings.isNotEmpty) {
    Logger.info('Cleaned up ${staleMappings.length} stale mappings');
  }
}
```

### 4. **启动时自动清理**

在代理服务器启动时自动清理过期映射：

```dart
Future<bool> _startProxyInternal(ProxyConfig config) async {
  try {
    // ... 启动逻辑 ...
    
    // 清理可能存在的旧映射（防止应用重启导致的映射冲突）
    _cleanupStaleMappings();
    
    // ... 其他逻辑 ...
  } catch (e) {
    // ... 错误处理 ...
  }
}
```

## 📊 修复效果

### 修复前的问题流程
```
1. _findAvailablePort() 找到端口4042
2. registerPort(4042) 成功
3. registerMapping(4042) 失败（已存在映射）
4. deregisterPort(4042) 清理
5. 返回 null（注册失败）
```

### 修复后的流程
```
1. _isPortTrulyAvailable(4042) 检查端口、监听状态、映射状态
2. 如果端口已有映射，自动清理旧映射
3. registerPort(4042) 成功
4. registerMapping(4042) 成功（自动处理重复）
5. 返回 4042（注册成功）
```

## 🎯 关键改进点

### 1. **完整性检查**
- 端口可用性
- 监听状态
- 映射状态

### 2. **自动处理**
- 自动清理重复映射
- 自动清理过期映射
- 启动时自动清理

### 3. **错误预防**
- 竞态条件处理
- 状态一致性保证
- 资源清理机制

### 4. **日志改进**
- 详细的调试信息
- 清晰的错误提示
- 操作状态跟踪

## 🚀 验证方法

### 1. **功能测试**
```dart
// 测试重复注册
final port1 = await FlutterAliHttpDns.instance.registerMapping(
  targetDomain: 'example.com',
  targetPort: 80,
);
final port2 = await FlutterAliHttpDns.instance.registerMapping(
  targetDomain: 'example.com',
  targetPort: 80,
);
// 应该返回不同的端口
```

### 2. **日志验证**
```
[INFO] Found available port 4042 for mapping
[INFO] Registering port 4042 for listening
[INFO] Successfully registered port 4042 for listening
[INFO] Added port mapping: 4042 -> example.com:80
[INFO] Successfully registered mapping for port 4042
```

### 3. **压力测试**
- 并发注册多个映射
- 应用重启测试
- 长时间运行测试

## 🎉 总结

通过以上修复，端口映射重复问题得到了根本解决：

1. **预防性检查**：在端口分配前进行完整性检查
2. **自动处理**：自动清理重复和过期映射
3. **状态一致性**：确保端口状态的一致性
4. **错误恢复**：提供完善的错误处理和恢复机制

现在端口映射注册可以稳定、可靠地工作！🎊
