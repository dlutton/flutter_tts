import Flutter
import Foundation

public class FlutterTtsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    SwiftFlutterTtsPlugin.register(with: registrar)
  }
}
