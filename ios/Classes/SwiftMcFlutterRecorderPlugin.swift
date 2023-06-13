import Flutter
import UIKit

public class SwiftMcFlutterRecorderPlugin: NSObject, FlutterPlugin, MCRecorderManagerDelegate {
    
    var channel: FlutterMethodChannel?
    private var engineActive: Bool = false
    private lazy var _manager: MCRecorderManager = {
        let manager = MCRecorderManager.init()
        manager.delegate = self
        return manager
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mc_flutter_recorder", binaryMessenger: registrar.messenger())
        let instance = SwiftMcFlutterRecorderPlugin()
        instance.channel = channel
        instance.engineActive = true
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("method: \(call.method), arguments: \(String(describing: call.arguments))")
        switch call.method {
        case "init":
            let success = _manager.initRecorder(arguments: call.arguments)
            result(success)
            break
        case "start":
            let success = _manager.start()
            result(success)
            break
        case "pause":
            let success = _manager.pause()
            result(success)
            break
        case "resume":
            let success = _manager.resume()
            result(success)
            break
        case "stop":
            let success = _manager.stop()
            result(success)
            break
        case "close":
            let success = _manager.close()
            result(success)
            break
        case "getState":
            result(_manager.state.rawValue)
            break
        default: break
        }
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        engineActive = false
    }
    
    func updateRecorderState(_ state: MCRecorderState) {
        var arguments = Dictionary<String, String>()
        arguments["state"] = state.rawValue
        if engineActive {
            channel?.invokeMethod("updateRecordState", arguments: arguments)
        }
    }
    
    func updateRecorderInfo(_ duration: TimeInterval, _ db: Double) {
        var arguments = Dictionary<String, Any>()
        arguments["duration"] = Int(duration * 1000)
        arguments["db"] = db
        if engineActive {
            channel?.invokeMethod("updateRecordInfo", arguments: arguments)
        }
    }
    
    func updateRecorderException(_ exception: MCRecorderException, _ message: String) {
        var arguments = Dictionary<String, Any>()
        arguments["errorType"] = exception.rawValue
        arguments["message"] = message
        if engineActive {
            channel?.invokeMethod("updateRecordError", arguments: arguments)
        }
    }
}

