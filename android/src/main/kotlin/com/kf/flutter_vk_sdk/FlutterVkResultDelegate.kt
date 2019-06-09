package com.kf.flutter_vk_sdk

import android.content.Intent
import android.util.Log

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

import com.vk.sdk.api.VKError
import com.vk.sdk.dialogs.VKShareDialogBuilder
import com.vk.sdk.dialogs.VKShareDialog
import com.vk.sdk.VKAccessToken
import com.vk.sdk.VKCallback
import com.vk.sdk.VKSdk

class FlutterVkSdkDelegate constructor(val registrar: PluginRegistry.Registrar) : PluginRegistry.ActivityResultListener {
  private var loginCallback: VKCallback<VKAccessToken>? = null
  private var pendingResult: MethodChannel.Result? = null

  companion object {
    const val UNKNOWN_METHOD: String = "UNKNOWN"
    const val NEED_LOGIN_ERROR_MSG: String = "NEED_LOGIN"
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
    var name = methodName
    if (name.isEmpty()) name = UNKNOWN_METHOD
    return "${name.toLowerCase()}_error"
  }

  private fun getCanceledCode(methodName: String): String {
    var name = methodName
    if (name.isEmpty()) name = UNKNOWN_METHOD
    return "${name.toLowerCase()}_canceled"
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

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (loginCallback == null) return false
    return VKSdk.onActivityResult(requestCode, resultCode, data, loginCallback!!)
  }

  fun initialize(appId: Int, apiVersion: String): VKSdk {
    return VKSdk.customInitialize(registrar.context(), appId, apiVersion)
  }

  fun isLoggedIn(): Boolean {
    return VKSdk.isLoggedIn()
  }

  fun login(scope: String, result: MethodChannel.Result) {
    val methodName = FlutterVkSdkPlugin.LOGIN_ACTION
    if (!setPendingResult(methodName, result)) return
    loginCallback = object : VKCallback<VKAccessToken> {
      override fun onResult(res: VKAccessToken) {
        finishWithResult(FlutterVkResults.successLogin(res))
      }

      override fun onError(error: VKError) {
        finishWithError(getErrorCode(methodName), error.errorMessage, FlutterVkResults.error(error))
      }
    }
    VKSdk.login(registrar.activity(), scope)
  }

  fun logout(result: MethodChannel.Result) {
    VKSdk.logout()
    result.success(null)
  }

  fun isLoggedIn(result: MethodChannel.Result) {
    result.success(isLoggedIn())
  }

  fun getCurrentAccessToken(result: MethodChannel.Result) {
    result.success(FlutterVkResults.accessToken(VKAccessToken.currentToken()))
  }

  fun share(text: String?, result: MethodChannel.Result) {
    val methodName = FlutterVkSdkPlugin.SHARE_ACTION
    if (!setPendingResult(methodName, result)) return
    if (isLoggedIn()) {
      val builder = VKShareDialogBuilder()
      if (!text.isNullOrEmpty()) builder.setText(text)

//      if (!it.isEmpty()) {
//        val photos = VKPhotoArray()
//        photos.add(VKApiPhoto(it))
//        builder.setUploadedPhotos(photos)
//      }
//      builder.setAttachmentLink(title, url)
      builder.setShareDialogListener(object : VKShareDialog.VKShareDialogListener {
        override fun onVkShareComplete(postId: Int) {
          // recycle bitmap if need
          finishWithResult(postId.toString()) // TODO: add owner id to result response
        }

        override fun onVkShareCancel() {
          // recycle bitmap if need
          finishWithError(getCanceledCode(methodName), null, null)
        }

        override fun onVkShareError(error: VKError) {
          // recycle bitmap if need
          finishWithError(getErrorCode(methodName), error.errorMessage, FlutterVkResults.error(error))
        }
      })
      val fragmentManager = registrar.activity().fragmentManager
      fragmentManager.addOnBackStackChangedListener {
        finishWithError(getCanceledCode(methodName), null, null)
      }
      builder.show(fragmentManager, "VK_SHARE_DIALOG")
    } else {
      finishWithError(getErrorCode(methodName), NEED_LOGIN_ERROR_MSG, null)
    }
  }
}

object FlutterVkResults {
  val cancelled: Map<String, String> = mapOf("status" to "cancelled")

  fun successLogin(token: VKAccessToken): Map<String, Any?> {
    val accessTokenMap = accessToken(token)

    return mapOf(
        "status" to "loggedIn",
        "accessToken" to accessTokenMap
    )
  }

  fun error(error: VKError): Map<String, String>? {
    when (error.errorCode) {
      VKError.VK_API_ERROR -> return mapOf(
          "status" to "error",
          "errorMessage" to error.errorMessage,
          "errorReason" to error.errorReason
      )

      VKError.VK_CANCELED -> return cancelled
    }
    return null
  }

  fun accessToken(accessToken: VKAccessToken?): Map<String, Any>? {
    if (accessToken == null) return null
    return mapOf(
        "token" to accessToken.accessToken,
        "userId" to accessToken.userId,
        "expiresIn" to accessToken.expiresIn,
        "secret" to accessToken.secret,
        "email" to accessToken.email,
        "scope" to accessToken.hasScope()
    )
  }
}
