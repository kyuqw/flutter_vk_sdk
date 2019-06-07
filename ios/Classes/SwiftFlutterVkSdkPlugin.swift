import Flutter
import UIKit
import VK_ios_sdk

enum VKAction: String {
    case initialize = "initialize"
    case login = "login"
    case logout = "logout"
    case getAccessToken = "get_access_token"
    case isLoggedIn = "is_logged_in"
    case share = "share"
}

public class SwiftFlutterVkSdkPlugin: NSObject, FlutterPlugin {
    private let vkScope = [VK_PER_EMAIL, VK_PER_FRIENDS, VK_PER_OFFLINE, VK_PER_WALL]
    var methodChannelResult: FlutterResult!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.fb.fluttervksdk/vk", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterVkSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case VKAction.initialize.rawValue:
            guard let vkAppId: String = getArgument("appId", from: call.arguments) else {
                result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
                return
            }
            VKSdk.initialize(withAppId: vkAppId)
            VKSdk.instance().uiDelegate = self
            VKSdk.instance().register(self)
            result(["success": true])
            break
        case VKAction.login.rawValue:
            loginVK(result)
            break
        case VKAction.share.rawValue:
            if VKSdk.isLoggedIn() {
                if let shareText: String = getArgument("text", from: call.arguments) {
                    shareToVK(text: shareText, result: result)
                } else {
                    result(FlutterError(code: "UNAVAILABLE", message: "VK share error", details: nil))
                }
            } else {
                result(FlutterError(code: "UNAVAILABLE", message: "VK share error", details: nil))
            }
            break
        case VKAction.logout.rawValue:
            VKSdk.forceLogout()
            result(["success": true])
            break
        case VKAction.isLoggedIn.rawValue:
            result(VKSdk.isLoggedIn())
            break
        default:
            return result(FlutterMethodNotImplemented)
        }
    }
    
    private func getArgument<T>(_ name: String, from arguments: Any?) -> T? {
        guard let arguments = arguments as? [String: Any] else { return nil }
        return arguments[name] as? T
    }
}

extension SwiftFlutterVkSdkPlugin: VKSdkDelegate, VKSdkUIDelegate {
    func loginVK(_ result: @escaping FlutterResult) {
        self.methodChannelResult = result
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
    
    func shareToVK(text: String, result: @escaping FlutterResult) {
        guard
            let rootController = UIApplication.shared.keyWindow?.rootViewController else {
                // TODO: Should dispatch error
                return
        }
        
        let shareDialog = VKShareDialogController()
        shareDialog.text = text
        //        let image = Constants.postcardImages[self.postcard.id]
        //        if image != "" {
        //            shareDialog.vkImages = [image]
        //        }
        //        shareDialog.shareLink = VKShareLink(title: "Выиграй поездку для своих близких в Тюмень!", link: URL(string: "https://visit-tyumen.ru/postcards"))
        
        shareDialog.completionHandler = { controller, _result in
            switch _result {
            case VKShareDialogControllerResult.cancelled:
                result(FlutterError(code: "UNAVAILABLE", message: "VK share error", details: nil))
            case VKShareDialogControllerResult.done:
                result(controller?.postId)
            default:
                result(FlutterError(code: "UNAVAILABLE", message: "VK share error", details: nil))
            }
            rootController.dismiss(animated: true)
        }
        
        rootController.present(shareDialog, animated: true, completion: nil)
    }
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
                return
        }
        
        rootController.present(controller, animated: true)
    }
    
}

