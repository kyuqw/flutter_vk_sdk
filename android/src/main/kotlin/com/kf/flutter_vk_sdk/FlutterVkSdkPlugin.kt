package com.kf.flutter_vk_sdk

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

import com.vk.sdk.VKScope

class FlutterVkSdkPlugin : MethodCallHandler {

  private var delegate: FlutterVkSdkDelegate

  constructor(registrar: Registrar) {
    delegate = FlutterVkSdkDelegate(registrar)
  }

  companion object {
    private const val CHANNEL_NAME: String = "com.fb.fluttervksdk/vk"
    const val SCOPE_ARGUMENT: String = "scope"

    const val LOGIN_ACTION: String = "login"
    const val LOGOUT_ACTION: String = "logout"
    const val GET_ACCESS_TOKEN_ACTION: String = "get_access_token"
    const val SHARE_ACTION: String = "share"

    val defaultScope: String = "${VKScope.EMAIL}, ${VKScope.NOTIFICATIONS}"

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(FlutterVkSdkPlugin(registrar))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      LOGIN_ACTION -> {
        var scope: String = defaultScope
        val scopeArg: String? = call.argument(SCOPE_ARGUMENT)
        if (!scopeArg.isNullOrBlank()) {
          scope = scopeArg!!
        }
        delegate.login(scope, result)
      }
      LOGOUT_ACTION -> {
        delegate.logout(result)
      }
      GET_ACCESS_TOKEN_ACTION -> {
        delegate.getCurrentAccessToken(result)
      }
      SHARE_ACTION -> {
        val text: String? = call.argument("text")
        var scope: String = "${defaultScope}, ${VKScope.WALL}"
        val scopeArg: String? = call.argument(SCOPE_ARGUMENT)
        if (!scopeArg.isNullOrBlank()) {
          scope = scopeArg!!
        }
        delegate.share(text, scope, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
}
