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
    case apiCall = "api_method_call"
    case postCall = "post_method_call"
}

public class SwiftFlutterVKSdkPlugin: NSObject, FlutterPlugin {
    private let vkScope = [VK_PER_EMAIL, VK_PER_FRIENDS, VK_PER_OFFLINE, VK_PER_WALL]
    var methodChannelResult: FlutterResult!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.fb.fluttervksdk/vk", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterVKSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case VKAction.initialize.rawValue:
            guard let vkAppId: String = getArgument("app_id", from: call.arguments) else {
                result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
                return
            }
            VKSdk.initialize(withAppId: vkAppId)
            VKSdk.instance().uiDelegate = self
            VKSdk.instance().register(self)
            result(["success": true])
            break
        case VKAction.login.rawValue:
            loginVK(result, scope: getArgument("scope", from: call.arguments))
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
        case VKAction.postCall.rawValue:
            self.postMethodCall(arguments: call.arguments, result: result)
            break
        case VKAction.apiCall.rawValue:
            self.apiMethodCall(arguments: call.arguments, result: result)
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

class VKAPIRequest {
    var method: String
    var url: String?
    var parameters: [String: String]
    var retryCount: Int32?
    
    init(method: String, parameters: [String: String]?, retryCount: Int32? = 3) {
        self.method = method
        self.parameters = parameters ?? [:]
        self.retryCount = retryCount
    }
    
//    init(url: String, parameters: [String: String]?, retryCount: Int32? = 3) {
//        self.url = url
//        self.parameters = parameters ?? [:]
//        self.retryCount = retryCount
//    }
    
    func request(completeBlock: @escaping (_ vkResponse: VKResponse<VKApiObject>?) -> Void, errorBlock: @escaping (Error?) -> Void) {
        let newRequest: VKRequest = VKRequest(method: self.method, parameters: self.parameters)
        newRequest.parseModel = false
        newRequest.requestTimeout = 25
        if let attempts = retryCount {
            newRequest.attempts = attempts
        }
        newRequest.execute(resultBlock: completeBlock, errorBlock: errorBlock)
    }
}

extension SwiftFlutterVKSdkPlugin: VKSdkDelegate, VKSdkUIDelegate {
    func apiMethodCall(arguments: Any?, result: @escaping FlutterResult) {
        guard let methodName = getArgument("method", from: arguments) as String? else {
            return result(FlutterError(code: "VK API DELEGATE", message: "___________________ERROR: NO METHOD PASSED", details: nil))
        }
        print("VK API DELEGATE", "___________________METHOD: \(methodName)")
        let args: Dictionary<String, String>? = getArgument("arguments", from: arguments)
        let retryCount: Int32? = getArgument("retry_count", from: arguments)
        // var skipValidation: Bool? = getArgument("skip_validation", from: arguments)
        VKAPIRequest(method: methodName, parameters: args, retryCount: retryCount).request(
            completeBlock: { vkResult in
                print("VK API DELEGATE", "___________________SUCCESS: \(vkResult?.responseString)")
                result(vkResult?.responseString ?? "")
            },
            errorBlock: { error in
                // TODO : common error handler
                print("VK API DELEGATE", "___________________ERROR: \(error.debugDescription)")
                result(FlutterError(code: "\(methodName)_ERROR", message: error.debugDescription, details: nil))
            }
        )
    }
    func postMethodCall(arguments: Any?, result: @escaping FlutterResult) {
        guard let url = getArgument("url", from: arguments) as String? else {
            return print("VK API DELEGATE", "___________________NO URL PASSED")
        }
        print("VK API DELEGATE", "___________________POST URL: \(url)")
        
        let args: Dictionary<String, String>? = getArgument("arguments", from: arguments)
        
        guard let photo = args?["photo"] else {
            return result(FlutterError(code: "VK API DELEGATE", message: "___________________ERROR: NO PHOTO PASSED", details: nil))
        }
        
        let _image = VKUploadImage(data: try? Data(contentsOf: URL(string: photo)!), andParams: VKImageParameters.pngImage())
        VKRequest.photoRequest(withPostUrl: url, withPhotos: [_image]).execute(
            resultBlock: { vkResult in
                print("VK API DELEGATE", "___________________SUCCESS: \(vkResult?.responseString)")
                result(vkResult?.responseString ?? "")
            },
                errorBlock: { error in
                // TODO : common error handler
                print("VK API DELEGATE", "___________________ERROR: \(error.debugDescription)")
                result(FlutterError(code: "POST_ERROR", message: error.debugDescription, details: nil))
            }
        )
    }
    
    func getImgPath(name: String) -> UIImage?
    {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths             = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        if let dirPath        = paths.first
        {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(name)
            let image    = UIImage(contentsOfFile: imageURL.path)
            return image
        }
        return nil
    }
    
    func loginVK(_ result: @escaping FlutterResult, scope: String?) {
        self.methodChannelResult = result
        let _scope = scopesFromString(scope)
        VKSdk.wakeUpSession(_scope) { state, error in
            switch state {
            case .authorized:
                if let token = VKSdk.accessToken() {
                    self.authorizeVK(with: token)
                } else {
                    result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
                }
                break
            case .initialized:
                VKSdk.authorize(_scope)
                break
            case .error:
                result(FlutterError(code: "UNAVAILABLE", message: "VK login error", details: nil))
                break
            default:
                break
            }
        }
    }
    
    func scopesFromString(_ scopesStr: String?) -> [String] {
        guard let _scopesStr = scopesStr else {return self.vkScope}
        let arr = _scopesStr.components(separatedBy: ",")
        return arr.map({$0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()})
    }
    
    func authorizeVK(with token: VKAccessToken) {
        let data: [String: Any?] = [
            "token": token.accessToken,
            "userId": token.userId,
            "expiresIn": token.expiresIn,
            "secret": token.secret,
            "email": token.email
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

