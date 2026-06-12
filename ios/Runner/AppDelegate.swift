import Flutter
import UIKit
import DJISDK

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var sdkChannel: FlutterMethodChannel?
    private var gimbalChannel: FlutterMethodChannel?
    private var cameraChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        // SDK Manager Channel
        sdkChannel = FlutterMethodChannel(
            name: "com.dji.sdk/API",
            binaryMessenger: controller.binaryMessenger
        )
        sdkChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleSDKCall(call: call, result: result)
        }

        // Gimbal Channel
        gimbalChannel = FlutterMethodChannel(
            name: "com.dji.sdk/Gimbal",
            binaryMessenger: controller.binaryMessenger
        )
        gimbalChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleGimbalCall(call: call, result: result)
        }

        // RC Event Channel
        let rcEventChannel = FlutterEventChannel(
            name: "com.dji.sdk/RC/events",
            binaryMessenger: controller.binaryMessenger
        )
        rcEventChannel.setStreamHandler(RCEventStreamHandler())

        // Camera Channel
        cameraChannel = FlutterMethodChannel(
            name: "com.dji.sdk/Camera",
            binaryMessenger: controller.binaryMessenger
        )
        cameraChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleCameraCall(call: call, result: result)
        }

        // Camera Event Channel
        let cameraEventChannel = FlutterEventChannel(
            name: "com.dji.sdk/Camera/events",
            binaryMessenger: controller.binaryMessenger
        )
        cameraEventChannel.setStreamHandler(CameraEventStreamHandler())

        // Video Event Channel
        let videoEventChannel = FlutterEventChannel(
            name: "com.dji.sdk/Video/events",
            binaryMessenger: controller.binaryMessenger
        )
        videoEventChannel.setStreamHandler(VideoEventStreamHandler())

        // Telemetry Event Channel
        let telemetryChannel = FlutterEventChannel(
            name: "com.dji.sdk/Telemetry/events",
            binaryMessenger: controller.binaryMessenger
        )
        telemetryChannel.setStreamHandler(TelemetryEventStreamHandler())

        // Register with DJI SDK
        DJISDKManager.registerApp(with: self)

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleSDKCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "registerApp":
            result(true)
        case "connectProduct":
            DJISDKManager.startConnection()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleGimbalCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let product = DJISDKManager.product(),
              let gimbal = product.gimbal else {
            result(FlutterError(code: "NO_GIMBAL", message: "No gimbal available", details: nil))
            return
        }

        switch call.method {
        case "rotateToAngle":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                return
            }
            let pitch = args["pitch"] as? Double ?? 0
            let yaw = args["yaw"] as? Double ?? 0
            let time = args["time"] as? Double ?? 0.5

            let rotation = DJIGimbalRotation(
                pitchValue: NSNumber(value: pitch),
                rollValue: nil,
                yawValue: NSNumber(value: yaw),
                time: time,
                mode: .absoluteAngle,
                ignore: true
            )
            gimbal.rotate(with: rotation) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(code: "GIMBAL_ERROR",
                            message: error.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }
            }

        case "setSpeed":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                return
            }
            let pitch = args["pitch"] as? Double ?? 0
            let yaw = args["yaw"] as? Double ?? 0

            gimbal.rotateGimbalBySpeed(
                with: DJIGimbalSpeedRotation(speed: pitch, enable: true),
                roll: DJIGimbalSpeedRotation(speed: 0, enable: false),
                yaw: DJIGimbalSpeedRotation(speed: yaw, enable: true)
            ) { error in
                DispatchQueue.main.async { result(nil) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleCameraCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let product = DJISDKManager.product(),
              let camera = product.camera else {
            result(FlutterError(code: "NO_CAMERA", message: "No camera available", details: nil))
            return
        }

        switch call.method {
        case "setCameraMode":
            guard let args = call.arguments as? [String: Any],
                  let modeStr = args["mode"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing mode", details: nil))
                return
            }
            camera.setMode(cameraModeFromString(modeStr), withCompletion: { error in
                DispatchQueue.main.async {
                    if let e = error {
                        result(FlutterError(code: "CAMERA_ERROR",
                            message: e.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }
            })

        case "takePhoto":
            camera.setMode(.shootPhoto, withCompletion: { [weak self] error in
                if error != nil {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CAMERA_ERROR",
                            message: error?.localizedDescription ?? "Mode switch failed", details: nil))
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    camera.startShootPhoto(completion: { error in
                        DispatchQueue.main.async {
                            if let e = error {
                                result(FlutterError(code: "CAMERA_ERROR",
                                    message: e.localizedDescription, details: nil))
                            } else {
                                result(nil)
                            }
                        }
                    })
                }
            })

        case "startRecording":
            camera.setMode(.recordVideo, withCompletion: { [weak self] error in
                if error != nil {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CAMERA_ERROR",
                            message: error?.localizedDescription ?? "Mode switch failed", details: nil))
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    camera.startRecordVideo(completion: { error in
                        DispatchQueue.main.async {
                            if let e = error {
                                result(FlutterError(code: "CAMERA_ERROR",
                                    message: e.localizedDescription, details: nil))
                            } else {
                                result(nil)
                            }
                        }
                    })
                }
            })

        case "stopRecording":
            camera.stopRecordVideo(completion: { error in
                DispatchQueue.main.async {
                    if let e = error {
                        result(FlutterError(code: "CAMERA_ERROR",
                            message: e.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }
            })

        case "setDigitalZoom":
            guard let args = call.arguments as? [String: Any],
                  let factor = args["factor"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing factor", details: nil))
                return
            }
            camera.setDigitalZoomFactor(CGFloat(factor), withCompletion: { _ in
                DispatchQueue.main.async { result(nil) }
            })

        case "setExposureMode":
            guard let args = call.arguments as? [String: Any],
                  let modeStr = args["mode"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing mode", details: nil))
                return
            }
            camera.setExposureMode(exposureModeFromString(modeStr), withCompletion: { error in
                DispatchQueue.main.async {
                    if let e = error {
                        result(FlutterError(code: "CAMERA_ERROR",
                            message: e.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }
            })

        case "setExposureCompensation":
            guard let args = call.arguments as? [String: Any],
                  let compStr = args["comp"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing comp", details: nil))
                return
            }
            if let comp = exposureCompFromString(compStr) {
                camera.setExposureCompensation(comp, withCompletion: { error in
                    DispatchQueue.main.async { result(nil) }
                })
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid EV value", details: nil))
            }

        case "setISO":
            guard let args = call.arguments as? [String: Any],
                  let isoStr = args["iso"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing iso", details: nil))
                return
            }
            if let iso = isoFromString(isoStr) {
                camera.setISO(iso, withCompletion: { error in
                    DispatchQueue.main.async { result(nil) }
                })
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid ISO", details: nil))
            }

        case "setWhiteBalance":
            guard let args = call.arguments as? [String: Any],
                  let wbStr = args["wb"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing wb", details: nil))
                return
            }
            if let wb = whiteBalanceFromString(wbStr) {
                camera.setWhiteBalance(wb, withCompletion: { error in
                    DispatchQueue.main.async { result(nil) }
                })
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid WB", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func cameraModeFromString(_ str: String) -> DJICameraMode {
        switch str {
        case "ShootPhoto": return .shootPhoto
        case "RecordVideo": return .recordVideo
        case "Playback": return .playback
        case "Download": return .mediaDownload
        default: return .shootPhoto
        }
    }

    private func exposureModeFromString(_ str: String) -> DJICameraExposureMode {
        switch str {
        case "AUTO": return .auto
        case "PROGRAM": return .programAuto
        case "SHUTTER": return .shutterPriority
        case "APERTURE": return .aperturePriority
        case "MANUAL": return .manual
        default: return .auto
        }
    }

    private func exposureCompFromString(_ str: String) -> DJICameraExposureCompensation? {
        switch str {
        case "P_3_0": return .EV_3_0
        case "P_2_7": return .EV_2_7
        case "P_2_3": return .EV_2_3
        case "P_2_0": return .EV_2_0
        case "P_1_7": return .EV_1_7
        case "P_1_3": return .EV_1_3
        case "P_1_0": return .EV_1_0
        case "P_0_7": return .EV_0_7
        case "P_0_3": return .EV_0_3
        case "P_0_0": return .EV_0_0
        case "N_0_3": return .N_0_3
        case "N_0_7": return .N_0_7
        case "N_1_0": return .N_1_0
        case "N_1_3": return .N_1_3
        case "N_1_7": return .N_1_7
        case "N_2_0": return .N_2_0
        case "N_2_3": return .N_2_3
        case "N_2_7": return .N_2_7
        case "N_3_0": return .N_3_0
        default: return nil
        }
    }

    private func isoFromString(_ str: String) -> DJICameraISO? {
        switch str {
        case "ISO_100": return .iso100
        case "ISO_200": return .iso200
        case "ISO_400": return .iso400
        case "ISO_800": return .iso800
        case "ISO_1600": return .iso1600
        case "ISO_3200": return .iso3200
        case "ISO_6400": return .iso6400
        default: return nil
        }
    }

    private func whiteBalanceFromString(_ str: String) -> DJICameraWhiteBalance? {
        switch str {
        case "AUTO": return .auto
        case "SUNNY": return .sunny
        case "CLOUDY": return .cloudy
        case "WATER_SURFACE": return .waterSurface
        case "INDOOR": return .indoor
        default: return nil
        }
    }
}

// MARK: - DJISDKManagerDelegate
extension AppDelegate: DJISDKManagerDelegate {
    func appRegisteredWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if error == nil {
                print("[DJI] SDK Registration SUCCESS")
                DJISDKManager.startConnection()
            } else {
                print("[DJI] SDK Registration FAILED: \(error!.localizedDescription)")
            }
        }
    }

    func productConnected(_ product: DJIBaseProduct?) {
        print("[DJI] Product connected: \(product?.model ?? "unknown")")
        DispatchQueue.main.async {
            TelemetryEventStreamHandler.shared?.setProduct(product)
            TelemetryEventStreamHandler.shared?.attachCallbacks(to: product)
            CameraEventStreamHandler.shared?.attachCallbacks(to: product)
            RCEventStreamHandler.shared?.attachCallbacks(to: product)
            VideoEventStreamHandler.shared?.setupVideoFeed()
        }
    }

    func productDisconnected(_ product: DJIBaseProduct?) {
        print("[DJI] Product disconnected")
        DispatchQueue.main.async {
            TelemetryEventStreamHandler.shared?.detachCallbacks()
            CameraEventStreamHandler.shared?.detachCallbacks()
            RCEventStreamHandler.shared?.detachCallbacks()
            VideoEventStreamHandler.shared?.cleanup()
        }
    }
}
