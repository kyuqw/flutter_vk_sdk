package com.kf.flutter_vk_sdk

import android.net.Uri
import android.util.Log

import io.flutter.plugin.common.MethodChannel

import com.vk.api.sdk.*
import com.vk.api.sdk.exceptions.VKApiExecutionException
import com.vk.api.sdk.internal.ApiCommand

class FlutterVKApiDelegate {

  private fun finishWithResult(result: MethodChannel.Result, value: String) {
    Log.d("VK API DELEGATE", "___________________SET RESULT: $value")
    result.success(value)
  }

  private fun finishWithError(result: MethodChannel.Result, methodName: String, error: VKApiExecutionException) {
    val code = FlutterVKResults.getErrorCode(methodName)
    val message = error.errorMsg
    val detail = FlutterVKResults.error(error)
    Log.d("VK API DELEGATE", "___________________SET ERROR: $code $message $detail")
    result.error(code, message, detail)
  }

  fun apiMethodCall(arguments: Map<String, Any?>, _result: MethodChannel.Result) {
    val methodName: String = arguments["method"] as String
    Log.d("VK API DELEGATE", "___________________METHOD: $methodName")
    var args: Map<String, String>? = null
    if (arguments.containsKey("arguments")) args = arguments["arguments"] as Map<String, String>
    var retryCount: Int? = null
    if (arguments.containsKey("retry_count")) retryCount = arguments["retry_count"] as Int
    var skipValidation: Boolean? = null
    if (arguments.containsKey("skip_validation")) skipValidation = arguments["skip_validation"] as Boolean

    val command = RawApiCommand(methodName, args, retryCount, skipValidation)
    VK.execute(command, object : VKApiCallback<String> {
      override fun success(result: String) {
        finishWithResult(_result, result)
      }

      override fun fail(error: VKApiExecutionException) {
        finishWithError(_result, methodName, error)
      }
    })
  }

  fun getPostCommandArguments(arguments: Map<String, Any>?): Map<String, Any>? {
    if (arguments == null) return null
    return arguments.map {
      val value = it.value.toString()
      if (value.startsWith("file:///")) Pair(it.key, Uri.parse(value))
      else Pair(it.key, value)
    }.toMap()
  }

  fun postMethodCall(arguments: Map<String, Any?>, _result: MethodChannel.Result) {
    val url: String = arguments["url"] as String
    Log.d("VK API DELEGATE", "___________________POST URL: $url")
    var args: Map<String, Any>? = null
    if (arguments.containsKey("arguments")) args = getPostCommandArguments(arguments["arguments"] as Map<String, Any>)
    var retryCount: Int? = null
    if (arguments.containsKey("retry_count")) retryCount = arguments["retry_count"] as Int
    var timeout: Long? = null
    if (arguments.containsKey("timeout")) timeout = arguments["timeout"] as Long
    val command = RawPostCommand(url, args, retryCount, timeout)
    VK.execute(command, object : VKApiCallback<String> {
      override fun success(result: String) {
        finishWithResult(_result, result)
      }

      override fun fail(error: VKApiExecutionException) {
        finishWithError(_result, "post_method_call", error)
      }
    })
  }
}


class RawApiCommand(private val method: String, private val args: Map<String, String>?,
                    private val retryCount: Int?, private val skipValidation: Boolean?) : ApiCommand<String>() {
  companion object {
    const val RETRY_COUNT = 3
  }

  override fun onExecute(manager: VKApiManager): String {
    val callBuilder = VKMethodCall.Builder()
    callBuilder.method(method)
    callBuilder.version(manager.config.version)
    if (args != null) callBuilder.args(args)

    val retryCount = retryCount ?: RETRY_COUNT
    callBuilder.retryCount(retryCount)
    if (skipValidation != null) callBuilder.skipValidation(skipValidation)

    return manager.execute(callBuilder.build(), RawVKApiResponseParser())
  }
}

class RawVKApiResponseParser : VKApiResponseParser<String> {
  override fun parse(response: String): String {
    return response
  }
}


class RawPostCommand(private val url: String, private val args: Map<String, Any>?,
                     private val retryCount: Int?, private val timeout: Long?) : ApiCommand<String>() {
  companion object {
    const val RETRY_COUNT = 3
  }

  override fun onExecute(manager: VKApiManager): String {
    val callBuilder = VKHttpPostCall.Builder()
    callBuilder.url(url)
    args?.forEach { (k, v) ->
      when (v) {
        is Uri -> callBuilder.args(k, v)
        is String -> callBuilder.args(k, v)
      }
    }

    val retryCount = retryCount ?: RETRY_COUNT
    callBuilder.retryCount(retryCount)
    if (timeout != null) callBuilder.timeout(timeout)

    return manager.execute(callBuilder.build(), null, RawVKApiResponseParser())
  }
}
