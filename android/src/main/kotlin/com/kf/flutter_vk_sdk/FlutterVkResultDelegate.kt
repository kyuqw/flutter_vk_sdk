package com.kf.flutter_vk_sdk

import android.content.Intent
import android.util.Log

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

import com.vk.api.sdk.auth.VKAccessToken
import com.vk.api.sdk.auth.VKAuthCallback
import com.vk.api.sdk.auth.VKScope
import com.vk.api.sdk.VKApiConfig
import com.vk.api.sdk.exceptions.VKApiExecutionException
import com.vk.api.sdk.VK

class FlutterVkSdkDelegate constructor(val registrar: PluginRegistry.Registrar) : PluginRegistry.ActivityResultListener {
  private var loginCallback: VKAuthCallback? = null
  private var pendingResult: MethodChannel.Result? = null

  companion object {
    const val NEED_LOGIN_ERROR_MSG: String = "NEED_LOGIN"
    val defaultScope: Collection<VKScope> = emptySet()
  }

  init {
    registrar.addActivityResultListener(this)
  }

  fun setPendingResult(methodName: String, result: MethodChannel.Result): Boolean {
    if (pendingResult != null) {
      val message = "$methodName called while another VK operation was in progress."
      Log.d("VK DELEGATE", "_______________________CONFLICT ERROR: ${message}")
      result.error(getErrorCode("conflict"), message, null)
      return false
    }
    pendingResult = result
    return true
  }

  private fun getErrorCode(methodName: String): String {
    return FlutterVkResults.getErrorCode(methodName)
  }

  private fun getCanceledCode(methodName: String): String {
    return FlutterVkResults.getCanceledCode(methodName)
  }

  private fun clearPending() {
    pendingResult = null
    loginCallback = null
  }

  private fun finishWithResult(result: Any?) {
    Log.d("VK DELEGATE", "_______________________SET RESULT: ${result}")
    pendingResult?.success(result)
    clearPending()
  }

  private fun finishWithError(code: String?, message: String?, detail: Any?) {
    Log.d("VK DELEGATE", "_______________________SET ERROR: ${code} ${message} ${detail}")
    pendingResult?.error(code, message, detail)
    clearPending()
  }

  fun scopesFromString(scopesStr: String?): Collection<VKScope> {
    if (scopesStr == null) return defaultScope
    val arr = scopesStr.split(",")
    val scopes = arr.map {
      val s = it.trim()
      VKScope.valueOf(s.toUpperCase())
    }
    return scopes
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (loginCallback == null) return false
    return VK.onActivityResult(requestCode, resultCode, data, loginCallback!!)
  }

//  fun initialize(appId: Int, apiVersion: String) {
//    if (appId == 0) {
//      throw RuntimeException("<integer name=\"com_vk_sdk_AppId\">your_app_id</integer> is not found in your resources.xml")
//    }
//
//    val context = registrar.context()
//    VK.setConfig(VKApiConfig(
//        context = context,
//        appId = appId,
//        version = apiVersion,
//        validationHandler = VKDefaultValidationHandler(context))
//    )
//  }

  fun isLoggedIn(): Boolean {
    return VK.isLoggedIn()
  }

  fun login(scopes: String?, result: MethodChannel.Result) {
    val scopeCollection = scopesFromString(scopes)
    val methodName = FlutterVkSdkPlugin.LOGIN_ACTION
    if (!setPendingResult(methodName, result)) return
    loginCallback = object : VKAuthCallback {
      override fun onLogin(token: VKAccessToken) {
        finishWithResult(FlutterVkResults.successLogin(token))
      }

      override fun onLoginFailed(errorCode: Int) {
        val code = if (errorCode == VKAuthCallback.AUTH_CANCELED) getCanceledCode(methodName) else getErrorCode(methodName)
        finishWithError(code, null, null)
      }
    }
    VK.login(registrar.activity(), scopeCollection)
  }

  fun logout(result: MethodChannel.Result) {
    VK.logout()
    result.success(null)
  }

  fun isLoggedIn(result: MethodChannel.Result) {
    result.success(isLoggedIn())
  }
}

object FlutterVkResults {
  private const val UNKNOWN_METHOD: String = "UNKNOWN"

  fun getErrorCode(methodName: String): String {
    var name = methodName
    if (name.isEmpty()) name = UNKNOWN_METHOD
    return "${name.toLowerCase()}_error"
  }

  fun getCanceledCode(methodName: String): String {
    var name = methodName
    if (name.isEmpty()) name = UNKNOWN_METHOD
    return "${name.toLowerCase()}_canceled"
  }

  fun successLogin(token: VKAccessToken): Map<String, Any?> {
    val accessTokenMap = accessToken(token)

    return mapOf(
        "status" to "loggedIn",
        "accessToken" to accessTokenMap
    )
  }

  fun error(error: VKApiExecutionException): Map<String, Any?> {
    val res = HashMap<String, Any?>()
    res["code"] = error.code
    res["apiMethod"] = error.apiMethod
    res["hasLocalizedMessage"] = error.hasLocalizedMessage
    res["errorMsg"] = error.errorMsg
    res["detailMessage"] = error.message
    if (error.extra != null) res["extra"] = error.extra.toString()
    if (error.executeErrors != null)
      res["executeErrors"] = error.executeErrors?.map { error(it) }?.joinToString(prefix = "[", postfix = "]")
    return res
  }

//  fun error(error: VKError?): Map<String, String>? {
//    if (error == null) return null
//    when (error.errorCode) {
//      VKError.VK_API_ERROR -> return mapOf(
//          "status" to "error",
//          "errorMessage" to error.errorMessage,
//          "errorReason" to error.errorReason
//      )
//
////      VKError.VK_CANCELED -> return null
//    }
//    return null
//  }

  fun accessToken(token: VKAccessToken): Map<String, Any?> {
    return mapOf(
        "token" to token.accessToken,
        "userId" to token.userId,
        "secret" to token.secret,
        "email" to token.email,
        "phone" to token.phone,
        "phoneAccessKey" to token.phoneAccessKey,
        "created" to token.created.toString()
    )
  }
}
