package com.kf.flutter_vk_sdk_example

import io.flutter.app.FlutterApplication
import com.vk.sdk.VKSdk

class Application : FlutterApplication() {
  override fun onCreate() {
    super.onCreate()
    VKSdk.initialize(this)
  }
}
