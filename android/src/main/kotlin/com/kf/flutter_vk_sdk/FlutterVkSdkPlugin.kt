package com.kf.flutter_vk_sdk

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

import com.vk.sdk.VKSdk
import com.vk.sdk.VKScope

class FlutterVkSdkPlugin : MethodCallHandler {

  private var delegate: FlutterVkSdkDelegate
  private var registrar: Registrar

  constructor(registrar: Registrar) {
    this.registrar = registrar
    delegate = FlutterVkSdkDelegate(registrar)
  }

  companion object {
    private const val CHANNEL_NAME: String = "com.fb.fluttervksdk/vk"
    const val APP_ID_ARGUMENT: String = "app_id"
    const val API_VERSION_ARGUMENT: String = "api_version"
    const val SCOPE_ARGUMENT: String = "scope"

    const val INITIALIZE_ACTION: String = "initialize"
    const val IS_LOGGED_IN_ACTION: String = "is_logged_in"
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
      INITIALIZE_ACTION -> {
        val appIdArg: String? = call.argument(APP_ID_ARGUMENT)
        val appId = appIdArg?.toInt() ?: 0
        val apiVersion: String = call.argument(API_VERSION_ARGUMENT) ?: ""
        delegate.initialize(appId, apiVersion)
        result.success(null)
      }
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
      IS_LOGGED_IN_ACTION -> {
        delegate.isLoggedIn(result)
      }
      GET_ACCESS_TOKEN_ACTION -> {
        delegate.getCurrentAccessToken(result)
      }
      SHARE_ACTION -> {
        val text: String? = call.argument("text")
        delegate.share(text, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
}
