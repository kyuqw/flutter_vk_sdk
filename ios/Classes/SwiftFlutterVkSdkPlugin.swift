import Flutter
import UIKit
import VK_ios_sdk

enum VKAction: String {
    case initialize = "initialize"
    case login = "login"
    case logout = "logout"
    case getAccessToken = "get_access_token"
    case share = "share"
}

public class SwiftFlutterVkSdkPlugin: NSObject, FlutterPlugin {
    private let vkScope = [VK_PER_EMAIL, VK_PER_FRIENDS, VK_PER_OFFLINE]
    var methodChannelResult: FlutterResult!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.fb.fluttervksdk/vk", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterVkSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case VKAction.initialize.rawValue:
            // TODO : init from flutter?
            
//            guard
//                let appId: String = getArgument("appId", from: input.arguments)
//                else {
//                    feedback(.failure("Invalid arguments"), to: output)
//                    return
//            }
//
//            let apiVersion: String? = getArgument("apiVersion", from: input.arguments)
//            VKSdk.instance().uiDelegate = self
//            VKSdk.instance().register(self)
            break
        case VKAction.login.rawValue:
            loginVK(result)
            break
        case VKAction.share.rawValue:
            if VKSdk.isLoggedIn() {
                shareToVK()
            } else {
                loginVK(result)
            }
            break
        default:
            return result(FlutterMethodNotImplemented)
        }
    }
    
    func loginVK(_ result: @escaping FlutterResult) {
        if let vkAppId = Bundle.main.object(forInfoDictionaryKey: "VKAppId") as? String, let sdkInstance = VKSdk.initialize(withAppId: vkAppId) {
            self.methodChannelResult = result
            sdkInstance.uiDelegate = self
            sdkInstance.register(self)
            VKSdk.wakeUpSession(self.vkScope) { state, error in
                switch state {
                case .authorized:
                    if let token = VKSdk.accessToken() {
                        self.authorizeVK(with: token)
                    } else {
                        result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
                    }
                    break
                case .initialized:
                    VKSdk.authorize(self.vkScope)
                    break
                case .error:
                    result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
                    break
                default:
                    break
                }
            }
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
        }
    }
    
    func shareToVK() {
        if let vkAppId = Bundle.main.object(forInfoDictionaryKey: "VKAppId") as? String, let sdkInstance = VKSdk.initialize(withAppId: vkAppId) {
            sdkInstance.uiDelegate = self
            sdkInstance.register(self)
            showVKShareModal()
        }
    }
    
    func authorizeVK(with token: VKAccessToken) {
        let data: [String: Any?] = [
            "status": true,
            "access_token": [
                "token": token.accessToken,
                "userId": token.userId,
                "expiresIn": token.expiresIn,
                "secret": token.secret,
                "email": token.email
            ]
        ]
        methodChannelResult(data)
    }
}

extension SwiftFlutterVkSdkPlugin: VKSdkDelegate, VKSdkUIDelegate {
    public func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if result.token != nil {
            self.authorizeVK(with: result.token)
        } else {
            self.methodChannelResult(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
        }
    }
    
    public func vkSdkUserAuthorizationFailed() {
        
    }
    
    public func vkSdkShouldPresent(_ controller: UIViewController!) {
//        dispatch(.vkSdkShouldPresent)
        guard let rootController = UIApplication.shared.keyWindow?.rootViewController else {
            // TODO: Should dispatch error
            return
        }
        rootController.present(controller, animated: true)
    }
    
    public func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
//        dispatch(.vkSdkNeedCaptchaEnter, payload: [
//            "error": captchaError.errorMessage,
//            ])
        
        guard
            let rootController = UIApplication.shared.keyWindow?.rootViewController,
            let controller = VKCaptchaViewController.captchaControllerWithError(captchaError) else {
                // TODO: Should dispatch error
                return
        }
        
        rootController.present(controller, animated: true)
    }
    
    func showVKShareModal() {
        guard
            let rootController = UIApplication.shared.keyWindow?.rootViewController else {
                // TODO: Should dispatch error
                return
        }
        
        let shareDialog = VKShareDialogController()
        shareDialog.text = "Я участник форума #YTPO2019"
//        let image = Constants.postcardImages[self.postcard.id]
//        if image != "" {
//            shareDialog.vkImages = [image]
//        }
//        shareDialog.shareLink = VKShareLink(title: "Выиграй поездку для своих близких в Тюмень!", link: URL(string: "https://visit-tyumen.ru/postcards"))
        
        shareDialog.completionHandler = { controller, result in
            // print(result.rawValue) //0 - cancel 1 - sent
            rootController.dismiss(animated: true)
        }
        
        rootController.present(shareDialog, animated: true, completion: nil)
    }
}
