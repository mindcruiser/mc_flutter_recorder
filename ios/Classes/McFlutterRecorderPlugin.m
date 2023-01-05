#import "McFlutterRecorderPlugin.h"
#if __has_include(<mc_flutter_recorder/mc_flutter_recorder-Swift.h>)
#import <mc_flutter_recorder/mc_flutter_recorder-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mc_flutter_recorder-Swift.h"
#endif

@implementation McFlutterRecorderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMcFlutterRecorderPlugin registerWithRegistrar:registrar];
}
@end
