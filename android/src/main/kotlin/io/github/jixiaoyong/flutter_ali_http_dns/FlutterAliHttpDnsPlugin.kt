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
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** FlutterAliHttpDnsPlugin */
class FlutterAliHttpDnsPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var dnsResolver: DNSResolver? = null
    private val gson = Gson()
    private var isInitialized = false
    private var applicationContext: android.content.Context? = null
    private val executor = Executors.newCachedThreadPool()

    companion object {
        private const val TAG = "[Android]"
        private const val DNS_TIMEOUT_SECONDS = 10L
        @Volatile
        private var enableDebugLog = false

        private fun logDebug(message: String) {
            if (enableDebugLog) {
                android.util.Log.d(TAG, message)
            }
        }

        private fun logError(message: String, throwable: Throwable? = null) {
            if (throwable != null) {
                android.util.Log.e(TAG, message, throwable)
            } else {
                android.util.Log.e(TAG, message)
            }
        }

        private fun isDebuggable(context: android.content.Context): Boolean {
            val flags = context.applicationInfo.flags
            return (flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        }

        private fun isNetworkAvailable(context: android.content.Context): Boolean {
            try {
                val connectivityManager =
                    context.getSystemService(android.content.Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                val network = connectivityManager.activeNetwork
                if (network != null) {
                    val networkCapabilities = connectivityManager.getNetworkCapabilities(network)
                    return networkCapabilities != null && (
                            networkCapabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI) ||
                                    networkCapabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR) ||
                                    networkCapabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_ETHERNET)
                            )
                }
            } catch (e: Exception) {
                logError("Failed to check network status", e)
            }
            return false
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ali_http_dns")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        applicationContext?.let { context ->
            enableDebugLog = isDebuggable(context)
        }
        DNSResolver.setEnableLogger(enableDebugLog)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initializeDns" -> {
                val configMap = call.arguments as? Map<String, Any>
                if (configMap != null) {
                    val configJson = gson.toJson(configMap)
                    initializeDns(configJson, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Config is required", null)
                }
            }

            "resolveDomain" -> {
                val domain = call.arguments as? String
                if (domain != null) {
                    resolveDomain(domain, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Domain is required", null)
                }
            }

            "clearCache" -> {
                val hostNames = call.arguments as? List<String>
                clearCache(hostNames, result)
            }

            "setEnableCache" -> {
                val enable = call.argument<Boolean>("enable")
                if (enable != null) {
                    setEnableCache(enable, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Enable flag is required", null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun setEnableCache(enable: Boolean, result: Result) {
        try {
            logDebug("Setting cache enabled: $enable")
            DNSResolver.setEnableCache(enable)
            result.success(null)
        } catch (e: Exception) {
            logError("Failed to set cache enabled", e)
            result.error("SET_CACHE_ERROR", "Failed to set cache: ${e.message}", null)
        }
    }

    private fun initializeDns(configJson: String, result: Result) {
        try {
            val config = gson.fromJson(configJson, JsonObject::class.java)
            val context = applicationContext
            if (context == null) {
                result.error("CONTEXT_ERROR", "Application context not available", null)
                return
            }

            val accountId = config.get("accountId").asString
            val accessKeyId = config.get("accessKeyId").asString
            val accessKeySecret = config.get("accessKeySecret").asString

            try {
                DNSResolver.Init(context, accountId, accessKeyId, accessKeySecret)
                dnsResolver = DNSResolver.getInstance()
            } catch (e: Exception) {
                logError("DNSResolver.Init failed", e)
                result.error("INIT_ERROR", "DNSResolver.Init failed: ${e.message}", null)
                return
            }

            val keepAliveDomains = config.getAsJsonArray("keepAliveDomains")
            if (keepAliveDomains != null && keepAliveDomains.size() > 0) {
                val domains = Array(keepAliveDomains.size()) { i -> keepAliveDomains[i].asString }
                DNSResolver.setKeepAliveDomains(domains)
            }

            val enableCache = config.get("enableCache").asBoolean
            DNSResolver.setEnableCache(enableCache)

            val preloadDomains = config.getAsJsonArray("preloadDomains")
            if (preloadDomains != null && preloadDomains.size() > 0) {
                val domains = Array(preloadDomains.size()) { i -> preloadDomains[i].asString }
                dnsResolver?.preLoadDomains(DNSResolver.QTYPE_IPV4, domains)
            }

            isInitialized = true
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

            // 检查网络连接
            val context = applicationContext

            // 使用异步执行器处理DNS解析，避免阻塞主线程
            executor.submit {
                try {
                    logDebug("Starting DNS resolution for domain: $domain")

                    // 使用超时机制
                    val future = executor.submit<String> {
                        try {
                            val ip = dnsResolver?.getIPV4ByHost(domain)
                            if (ip != null && ip.isNotEmpty() && ip != domain) {
                                logDebug("DNS resolution successful: $domain -> $ip")
                                ip
                            } else {
                                logDebug("DNS resolution returned null, empty, or original domain for $domain")
                                null
                            }
                        } catch (e: Exception) {
                            logError("DNS resolution exception for domain: $domain", e)
                            null
                        }
                    }

                    val ip = try {
                        future.get(DNS_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                    } catch (e: java.util.concurrent.TimeoutException) {
                        logError("DNS resolution timeout for domain: $domain")
                        future.cancel(true)
                        null
                    } catch (e: Exception) {
                        logError("DNS resolution error for domain: $domain", e)
                        null
                    }

                    if (ip != null && ip.isNotEmpty()) {
                        result.success(ip)
                    } else {
                        // 返回 null 让 Flutter 端使用系统 DNS
                        logDebug("DNS resolution failed for $domain, returning null for fallback")
                        result.success(null)
                    }
                } catch (e: Exception) {
                    logError("Unexpected error during DNS resolution for $domain", e)
                    result.error("RESOLUTION_ERROR", "Failed to resolve domain: ${e.message}", null)
                }
            }
        } catch (e: Exception) {
            logError("Failed to submit DNS resolution task for $domain", e)
            result.error("RESOLUTION_ERROR", "Failed to resolve domain: ${e.message}", null)
        }
    }

    private fun clearCache(hostNames: List<String>?, result: Result) {
        try {
            if (!isInitialized) {
                result.error("NOT_INITIALIZED", "DNS service not initialized", null)
                return
            }

            logDebug("Clearing DNS cache for: ${hostNames ?: "all hosts"}")
            
            if (hostNames == null || hostNames.isEmpty()) {
                dnsResolver?.clearHostCache(null)
            } else {
                dnsResolver?.clearHostCache(hostNames.toTypedArray())
            }
            
            result.success(true)
        } catch (e: Exception) {
            logError("Failed to clear cache", e)
            result.error("CLEAR_CACHE_ERROR", "Failed to clear cache: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
