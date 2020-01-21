import Flutter
import UIKit

public class SwiftFlutterTimeDatePickerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_time_date_picker", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterTimeDatePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
