package com.kf.flutter_vk_sdk

import android.util.Log

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterVKSdkPlugin : MethodCallHandler {

  private var delegate: FlutterVKSdkDelegate
  private var apiDelegate: FlutterVKApiDelegate

  constructor(registrar: Registrar) {
    Log.d("VK PLUGIN", "_________________________CALL CONSTRUCTOR")
    delegate = FlutterVKSdkDelegate(registrar)
    apiDelegate = FlutterVKApiDelegate()
  }

  companion object {
    private const val CHANNEL_NAME: String = "com.fb.fluttervksdk/vk"
    const val APP_ID_ARGUMENT: String = "app_id"
    const val API_VERSION_ARGUMENT: String = "api_version"
    const val SCOPE_ARGUMENT: String = "email"

    const val INITIALIZE_ACTION: String = "initialize"
    const val IS_LOGGED_IN_ACTION: String = "is_logged_in"
    const val LOGIN_ACTION: String = "login"
    const val LOGOUT_ACTION: String = "logout"
    const val GET_ACCESS_TOKEN_ACTION: String = "get_access_token"
    const val API_ACTION: String = "api_method_call"
    const val POST_ACTION: String = "post_method_call"

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(FlutterVKSdkPlugin(registrar))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d("VK PLUGIN", "_________________________CALL METHOD: ${call.method}")
    when (call.method) {
//      INITIALIZE_ACTION -> {
//        val appIdArg: String? = call.argument(APP_ID_ARGUMENT)
//        val appId = appIdArg?.toInt() ?: 0
//        val apiVersion: String = call.argument(API_VERSION_ARGUMENT) ?: ""
//        delegate.initialize(appId, apiVersion)
//        result.success(null)
//      }
      LOGIN_ACTION -> {
        val scope: String? = call.argument(SCOPE_ARGUMENT)
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
      API_ACTION -> {
        val arguments = call.arguments<Map<String, Any?>>()
        apiDelegate.apiMethodCall(arguments, result)
      }
      POST_ACTION -> {
        val arguments = call.arguments<Map<String, Any?>>()
        apiDelegate.postMethodCall(arguments, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
}
