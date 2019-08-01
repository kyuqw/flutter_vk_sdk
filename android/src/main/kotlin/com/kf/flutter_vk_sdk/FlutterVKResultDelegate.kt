package com.kf.flutter_vk_sdk

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

import com.vk.api.sdk.auth.VKAccessToken
import com.vk.api.sdk.auth.VKAuthCallback
import com.vk.api.sdk.auth.VKScope
import com.vk.api.sdk.exceptions.VKApiExecutionException
import com.vk.api.sdk.VK

class FlutterVKSdkDelegate constructor(val registrar: PluginRegistry.Registrar) : PluginRegistry.ActivityResultListener {
  private var loginCallback: VKAuthCallback? = null
  private var pendingResult: MethodChannel.Result? = null

  companion object {
    private const val VK_APP_AUTH_CODE = 282
    const val PREFERENCE_NAME = "com.vkontakte.android_pref_name"
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
    return FlutterVKResults.getErrorCode(methodName)
  }

  private fun getCanceledCode(methodName: String): String {
    return FlutterVKResults.getCanceledCode(methodName)
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
    var intent = data
    if (intent == null && requestCode == VK_APP_AUTH_CODE) intent = Intent()
    return VK.onActivityResult(requestCode, resultCode, intent, loginCallback!!)
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

  fun getCurrentAccessToken(result: MethodChannel.Result) {
    val token = VKAccessToken.restore(getPreferences(registrar.context()))
    result.success(FlutterVKResults.accessToken(token))
  }

  fun login(scopes: String?, result: MethodChannel.Result) {
    val scopeCollection = scopesFromString(scopes)
    val methodName = FlutterVKSdkPlugin.LOGIN_ACTION
    if (!setPendingResult(methodName, result)) return
    loginCallback = object : VKAuthCallback {
      override fun onLogin(token: VKAccessToken) {
        finishWithResult(FlutterVKResults.successLogin(token))
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

  fun getPreferences(context: Context): SharedPreferences = context.getSharedPreferences(PREFERENCE_NAME, Context.MODE_PRIVATE)
}

object FlutterVKResults {
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

  fun successLogin(token: VKAccessToken): Map<String, Any?>? {
    return accessToken(token)
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

  fun accessToken(token: VKAccessToken?): Map<String, Any?>? {
    if (token == null) return null
    return mapOf(
        "token" to token.accessToken,
        "userId" to token.userId,
        "secret" to token.secret,
        "email" to token.email,
        "phone" to token.phone,
        "phoneAccessKey" to token.phoneAccessKey,
        "created" to token.created
    )
  }
}
