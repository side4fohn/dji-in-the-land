import Flutter
import AVFoundation
import VideoToolbox

class VideoEventStreamHandler: NSObject, FlutterStreamHandler, DJIVideoFeedListener {
    static var shared: VideoEventStreamHandler?

    private var eventSink: FlutterEventSink?
    private var videoFeed: DJIVideoFeed?
    private var decoder: VTDecompressionSession?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        VideoEventStreamHandler.shared = self
        setupVideoFeed()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cleanup()
        self.eventSink = nil
        VideoEventStreamHandler.shared = nil
        return nil
    }

    func setupVideoFeed() {
        guard let product = DJISDKManager.product(),
              let camera = product.camera else { return }
        videoFeed = DJIVideoFeed.feed(for: .mainCamera)
        videoFeed?.add(self, with: nil)
    }

    func cleanup() {
        videoFeed?.remove(self)
        videoFeed = nil
        if let decoder = decoder {
            VTDecompressionSessionInvalidate(decoder)
            self.decoder = nil
        }
    }

    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData rawData: Data) {
        guard !rawData.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(FlutterStandardTypedData(bytes: rawData))
        }
    }
}
