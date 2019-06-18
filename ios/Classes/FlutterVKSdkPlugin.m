#import "FlutterVKSdkPlugin.h"
#import <flutter_vk_sdk/flutter_vk_sdk-Swift.h>

@implementation FlutterVKSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterVKSdkPlugin registerWithRegistrar:registrar];
}
@end
