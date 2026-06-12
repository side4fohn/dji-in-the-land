import Flutter

class CameraEventStreamHandler: NSObject, FlutterStreamHandler {
    static var shared: CameraEventStreamHandler?

    private var eventSink: FlutterEventSink?
    private var product: DJIBaseProduct?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        CameraEventStreamHandler.shared = self
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        CameraEventStreamHandler.shared = nil
        return nil
    }

    func attachCallbacks(to product: DJIBaseProduct?) {
        self.product = product
        guard let camera = product?.camera else { return }
        camera.setSystemStateCallback { [weak self] state in
            guard let sink = self?.eventSink else { return }
            sink([
                "isRecording": state.isRecording,
                "recordingSeconds": state.currentVideoRecordingTimeInSeconds,
                "sdCardInserted": state.isSDCardInserted,
                "sdCardError": state.hasError,
                "sdCardRemainingMB": state.remainingSpaceInMB,
                "mode": self?.cameraModeToString(state.mode) ?? "unknown"
            ] as [String : Any])
        }
    }

    func detachCallbacks() {
        product?.camera?.setSystemStateCallback(nil)
    }

    private func cameraModeToString(_ mode: DJICameraMode) -> String {
        switch mode {
        case .shootPhoto: return "shootPhoto"
        case .recordVideo: return "recordVideo"
        case .playback: return "playback"
        case .mediaDownload: return "download"
        default: return "unknown"
        }
    }
}
