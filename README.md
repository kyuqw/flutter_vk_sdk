# flutter_vk_sdk

[![pub package](https://img.shields.io/pub/v/flutter_vk_sdk.svg)](https://pub.dev/packages/flutter_vk_sdk)

Flutter vk sdk project.

This plugin is based on:
- Android: [vk-android-sdk v2.1.0](https://github.com/VKCOM/vk-android-sdk/tree/2.1.0)
- iOS: [vk-ios-sdk](https://github.com/VKCOM/vk-ios-sdk)

## Installation

First, add  [*`flutter_vk_sdk`*](https://pub.dev/packages/flutter_vk_sdk#-installing-tab-)  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
flutter_vk_sdk: ^0.0.6+4
```

### Android

In your android res/values create strings.xml and fill with this examples
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <integer name="com_vk_sdk_AppId">YOUR_VK_APP_ID</integer>
</resources>
```

### iOS

* AppDelegate
```
import UIKit
import Flutter
import VK_ios_sdk

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
        ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        VKSdk.processOpen(url, fromApplication: "")
        return true
    }
}
```

* info.plist
```
<key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>vk{YOUR_APP_ID}</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>vk{YOUR_APP_ID}</string>
            </array>
        </dict>
    </array>


<key>LSApplicationQueriesSchemes</key>
<array>
    <string>vk</string>
    <string>vk-share</string>
    <string>vkauthorize</string>
</array>
```

## Dart usage
