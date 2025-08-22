package io.github.jixiaoyong.flutter_ali_http_dns

import androidx.annotation.NonNull
import com.alibaba.pdns.DNSResolver
import com.google.gson.Gson
import com.google.gson.JsonObject
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterAliHttpDnsPlugin */
class FlutterAliHttpDnsPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var dnsResolver: DNSResolver
  private val gson = Gson()
  private var isInitialized = false
  private var applicationContext: android.content.Context? = null

  companion object {
    private const val TAG = "FlutterAliHttpDns"
    
    /**
     * 打印调试日志（仅在debug模式下）
     */
    private fun logDebug(message: String) {
      if (BuildConfig.DEBUG) {
        android.util.Log.d(TAG, message)
      }
    }
    
    /**
     * 打印错误日志（仅在debug模式下）
     */
    private fun logError(message: String, throwable: Throwable? = null) {
      if (BuildConfig.DEBUG) {
        if (throwable != null) {
          android.util.Log.e(TAG, message, throwable)
        } else {
          android.util.Log.e(TAG, message)
        }
      }
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ali_http_dns")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
    dnsResolver = DNSResolver.getInstance()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initializeDns" -> {
        // 添加详细的日志输出（仅在debug模式下）
        logDebug("Received initializeDns call with arguments: ${call.arguments}")
        logDebug("Arguments type: ${call.arguments?.javaClass?.simpleName}")
        
        // 尝试从参数中获取配置
        val configMap = call.arguments as? Map<String, Any>
        if (configMap != null) {
          // 将Map转换为JSON字符串
          val configJson = gson.toJson(configMap)
          logDebug("Config JSON: $configJson")
          initializeDns(configJson, result)
        } else {
          logError("Config is null or invalid type. Expected Map<String, Any>, got: ${call.arguments?.javaClass?.name}")
          result.error("INVALID_ARGUMENT", "Config is required", null)
        }
      }
      "resolveDomain" -> {
        val domain = call.argument<String>("domain")
        if (domain != null) {
          resolveDomain(domain, result)
        } else {
          result.error("INVALID_ARGUMENT", "Domain is required", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun initializeDns(configJson: String, result: Result) {
    try {
      logDebug("Parsing config JSON: $configJson")
      val config = gson.fromJson(configJson, JsonObject::class.java)
      logDebug("Parsed config: $config")
      
      // 检查应用上下文
      val context = applicationContext
      if (context == null) {
        logError("Application context is null")
        result.error("CONTEXT_ERROR", "Application context not available", null)
        return
      }
      
      // 根据官方文档初始化 DNSResolver
      // DNSResolver.Init(context, accountId, accessKeyId, accessKeySecret)
      val accountId = config.get("accountId").asString
      val accessKeyId = config.get("accessKeyId").asString
      val accessKeySecret = config.get("accessKeySecret").asString
      
      logDebug("Initializing DNS with accountId: $accountId, accessKeyId: $accessKeyId")
      
      DNSResolver.Init(context, accountId, accessKeyId, accessKeySecret)
      logDebug("DNSResolver.Init completed successfully")
      
      // 设置保持连接的域名
      val keepAliveDomains = config.getAsJsonArray("keepAliveDomains")
      if (keepAliveDomains != null && keepAliveDomains.size() > 0) {
        val domains = mutableListOf<String>()
        for (i in 0 until keepAliveDomains.size()) {
          domains.add(keepAliveDomains[i].asString)
        }
        logDebug("Setting keep alive domains: $domains")
        DNSResolver.setKeepAliveDomains(domains.toTypedArray())
      }
      
      // 预加载域名
      val preloadDomains = config.getAsJsonArray("preloadDomains")
      if (preloadDomains != null && preloadDomains.size() > 0) {
        val domains = mutableListOf<String>()
        for (i in 0 until preloadDomains.size()) {
          domains.add(preloadDomains[i].asString)
        }
        logDebug("Preloading domains: $domains")
        dnsResolver.preLoadDomains(DNSResolver.QTYPE_IPV4, domains.toTypedArray())
      }
      
      isInitialized = true
      logDebug("DNS initialization completed successfully")
      result.success(true)
    } catch (e: Exception) {
      logError("Failed to initialize DNS", e)
      result.error("INITIALIZATION_ERROR", "Failed to initialize DNS: ${e.message}", null)
    }
  }

  private fun resolveDomain(domain: String, result: Result) {
    try {
      if (!isInitialized) {
        result.error("NOT_INITIALIZED", "DNS service not initialized", null)
        return
      }
      
      // 根据官方文档使用 getIPV4ByHost 方法
      val ip = dnsResolver.getIPV4ByHost(domain)
      if (ip != null && ip.isNotEmpty()) {
        result.success(ip)
      } else {
        // 如果没有获取到 IP，返回原域名作为兜底
        result.success(domain)
      }
    } catch (e: Exception) {
      result.error("RESOLUTION_ERROR", "Failed to resolve domain: ${e.message}", null)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
