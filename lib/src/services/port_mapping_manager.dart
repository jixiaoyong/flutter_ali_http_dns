import '../models/port_mapping.dart';
import '../utils/logger.dart';

/// 端口映射管理器
class PortMappingManager {
  final Map<int, PortMapping> _mappings = {};
  
  /// 添加端口映射
  Future<bool> addMapping(PortMapping mapping) async {
    try {
      if (_mappings.containsKey(mapping.localPort)) {
        Logger.warning('Port mapping for port ${mapping.localPort} already exists, updating...');
        // 移除旧的映射
        _mappings.remove(mapping.localPort);
      }
      
      _mappings[mapping.localPort] = mapping;
      Logger.info('Added port mapping: ${mapping.localPort} -> ${mapping.targetDomain}:${mapping.targetPort}');
      return true;
    } catch (e) {
      Logger.error('Failed to add port mapping', e);
      return false;
    }
  }
  
  /// 移除端口映射
  Future<bool> removeMapping(int localPort) async {
    try {
      final mapping = _mappings.remove(localPort);
      if (mapping != null) {
        Logger.info('Removed port mapping: ${mapping.localPort} -> ${mapping.targetDomain}:${mapping.targetPort}');
        return true;
      } else {
        Logger.warning('Port mapping for port $localPort not found');
        return false;
      }
    } catch (e) {
      Logger.error('Failed to remove port mapping', e);
      return false;
    }
  }
  
  /// 获取端口映射
  PortMapping? getMapping(int localPort) {
    return _mappings[localPort];
  }
  
  /// 获取所有端口映射
  Map<int, PortMapping> getAllMappings() {
    return Map.unmodifiable(_mappings);
  }
  
  /// 获取激活的端口映射
  Map<int, PortMapping> getActiveMappings() {
    return Map.unmodifiable(
      Map.fromEntries(_mappings.entries.where((entry) => entry.value.isActive)),
    );
  }
  
  /// 检查端口是否有映射
  bool hasMapping(int localPort) {
    return _mappings.containsKey(localPort);
  }
  
  /// 获取映射的本地端口列表
  List<int> getLocalPorts() {
    return _mappings.keys.toList();
  }
  
  /// 获取激活的本地端口列表
  List<int> getActiveLocalPorts() {
    return _mappings.entries
        .where((entry) => entry.value.isActive)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// 清除所有映射
  void clear() {
    _mappings.clear();
    Logger.info('Cleared all port mappings');
  }
  
  /// 获取映射数量
  int get mappingCount => _mappings.length;
  
  /// 获取激活的映射数量
  int get activeMappingCount => _mappings.values.where((m) => m.isActive).length;
}
