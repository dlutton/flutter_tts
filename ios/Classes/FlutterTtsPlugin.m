#import "FlutterTtsPlugin.h"
#import <flutter_tts/flutter_tts-Swift.h>

@implementation FlutterTtsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterTtsPlugin registerWithRegistrar:registrar];
}
@end
