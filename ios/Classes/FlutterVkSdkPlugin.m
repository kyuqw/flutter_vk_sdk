#import "FlutterVkSdkPlugin.h"
#import <flutter_vk_sdk/flutter_vk_sdk-Swift.h>

@implementation FlutterVkSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterVkSdkPlugin registerWithRegistrar:registrar];
}
@end
