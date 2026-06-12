import Flutter

class RCEventStreamHandler: NSObject, FlutterStreamHandler {
    static var shared: RCEventStreamHandler?

    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        RCEventStreamHandler.shared = self
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        RCEventStreamHandler.shared = nil
        return nil
    }

    func attachCallbacks(to product: DJIBaseProduct?) {
        guard let rc = product?.remoteController else { return }
        rc.hardwareState.setCallback { [weak self] state in
            guard let sink = self?.eventSink else { return }
            sink([
                "leftStick": [
                    "vertical": state.leftStick.vertical,
                    "horizontal": state.leftStick.horizontal
                ],
                "rightStick": [
                    "vertical": state.rightStick.vertical,
                    "horizontal": state.rightStick.horizontal
                ]
            ])
        }
    }

    func detachCallbacks() {
        if let rc = DJISDKManager.product()?.remoteController {
            rc.hardwareState.setCallback(nil)
        }
    }
}
