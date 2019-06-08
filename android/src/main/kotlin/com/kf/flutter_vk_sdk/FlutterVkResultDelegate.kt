package com.kf.flutter_vk_sdk

import android.content.Intent

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
    const val LOGIN_ERROR_CODE: String = "LoginError"
  }

  init {
    registrar.addActivityResultListener(this)
  }

  fun setPendingResult(methodName: String, result: MethodChannel.Result) {
    if (pendingResult != null) {
      result.error(
          "ProgressError",
          methodName + " called while another VK operation was in progress.",
          null
      )
    }
    pendingResult = result
  }

  private fun clearPending() {
    pendingResult = null
    loginCallback = null
  }

  private fun finishWithResult(result: Any?) {
    pendingResult?.success(result)
    clearPending()
  }

  private fun finishWithError(code: String?, message: String?, detail: Any?) {
    pendingResult?.error(code, message, detail)
    clearPending()
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    return VKSdk.onActivityResult(requestCode, resultCode, data, loginCallback!!)
  }

  fun initialize(appId: Int, apiVersion: String): VKSdk {
    return VKSdk.customInitialize(registrar.context(), appId, apiVersion)
  }

  fun isLoggedIn(): Boolean {
    return VKSdk.isLoggedIn()
  }

  fun login(scope: String, result: MethodChannel.Result) {
    setPendingResult(FlutterVkSdkPlugin.LOGIN_ACTION, result)
    loginCallback = object : VKCallback<VKAccessToken> {
      override fun onResult(res: VKAccessToken) {
        finishWithResult(FlutterVkResults.successLogin(res))
      }

      override fun onError(error: VKError) {
        finishWithError(LOGIN_ERROR_CODE, error.errorMessage, FlutterVkResults.error(error))
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
    setPendingResult(FlutterVkSdkPlugin.SHARE_ACTION, result)
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
          finishWithError(null, null, null)
        }

        override fun onVkShareError(error: VKError) {
          // recycle bitmap if need
          finishWithError("ShareError", error.errorMessage, FlutterVkResults.error(error))
        }
      })
      builder.show(registrar.activity().fragmentManager, "VK_SHARE_DIALOG")
    } else {
      finishWithError("ShareError", "NeedLogin", null)
    }
  }
}

object FlutterVkResults {
  val cancelled: Map<String, String> = mapOf("status" to "cancelled")

  fun successLogin(token: VKAccessToken): Map<String, Any?> {
    val accessTokenMap = FlutterVkResults.accessToken(token)

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
        "token" to accessToken!!.accessToken,
        "userId" to accessToken!!.userId,
        "expiresIn" to accessToken!!.expiresIn,
        "secret" to accessToken!!.secret,
        "email" to accessToken!!.email,
        "scope" to accessToken!!.hasScope()
    )
  }
}
