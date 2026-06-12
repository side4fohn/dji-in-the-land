import Flutter

class TelemetryEventStreamHandler: NSObject, FlutterStreamHandler {
    static var shared: TelemetryEventStreamHandler?

    private var eventSink: FlutterEventSink?
    private var product: DJIBaseProduct?
    private var flushTimer: Timer?

    private var lastFCState: DJIFlightControllerState?
    private var lastBatteryState: DJIBatteryState?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        TelemetryEventStreamHandler.shared = self
        startFlushTimer()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        flushTimer?.invalidate()
        flushTimer = nil
        self.eventSink = nil
        TelemetryEventStreamHandler.shared = nil
        return nil
    }

    func setProduct(_ product: DJIBaseProduct?) {
        self.product = product
    }

    func attachCallbacks(to product: DJIBaseProduct?) {
        self.product = product

        product?.flightController?.setStateCallback { [weak self] state in
            self?.lastFCState = state
        }

        product?.battery?.setStateCallback { [weak self] state in
            self?.lastBatteryState = state
        }
    }

    func detachCallbacks() {
        product?.flightController?.setStateCallback(nil)
        product?.battery?.setStateCallback(nil)
        lastFCState = nil
        lastBatteryState = nil
    }

    private func startFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }

    private func flush() {
        guard let sink = eventSink else { return }

        var data: [String: Any] = [:]

        if let fc = lastFCState {
            var fcData: [String: Any] = [
                "altitude": fc.altitude,
                "speedX": fc.velocityX,
                "speedY": fc.velocityY,
                "speedZ": fc.velocityZ,
                "satellites": fc.satelliteCount,
                "gpsSignalGood": fc.isGPSSignalLevelGood,
                "motorsOn": fc.areMotorsOn,
                "flightMode": fc.flightMode?.rawValue ?? "",
                "isFlying": fc.isFlying,
                "lowBatteryWarning": (fc.batteryThresholdBehavior?.lowBatteryWarningThreshold ?? 0) > 0,
                "seriousLowBatteryWarning": (fc.batteryThresholdBehavior?.seriousLowBatteryWarningThreshold ?? 0) > 0
            ]
            if let loc = fc.aircraftLocation {
                fcData["location"] = [
                    "latitude": loc.latitude,
                    "longitude": loc.longitude
                ]
            }
            data["flightController"] = fcData
        }

        if let battery = lastBatteryState {
            data["battery"] = [
                "percent": battery.chargeRemainingInPercent,
                "temp": battery.temperature,
                "voltage": battery.voltage
            ]
        }

        sink(data)
    }
}
