import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CameraMode { shootPhoto, recordVideo, playback, download }

class CameraCtrl extends ChangeNotifier {
  CameraMode _mode = CameraMode.shootPhoto;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  bool _sdCardInserted = false;
  bool _sdCardError = false;
  int _sdCardRemainingMB = 0;
  double _zoomFactor = 1.0;
  String _exposureMode = 'AUTO';
  Timer? _recordingTimer;

  CameraMode get mode => _mode;
  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;
  bool get sdCardInserted => _sdCardInserted;
  bool get sdCardError => _sdCardError;
  int get sdCardRemainingMB => _sdCardRemainingMB;
  double get zoomFactor => _zoomFactor;
  String get exposureMode => _exposureMode;

  static const _channel = MethodChannel('com.dji.sdk/Camera');
  static const _eventChannel = EventChannel('com.dji.sdk/Camera/events');

  StreamSubscription? _subscription;

  Future<void> init() async {
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(_handleCameraState);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _handleCameraState(dynamic state) {
    if (state is! Map) return;
    _isRecording = state['isRecording'] ?? false;
    _recordingSeconds = (state['recordingSeconds'] as num?)?.toInt() ?? 0;
    _sdCardInserted = state['sdCardInserted'] ?? false;
    _sdCardError = state['sdCardError'] ?? false;
    _sdCardRemainingMB = (state['sdCardRemainingMB'] as num?)?.toInt() ?? 0;

    final modeStr = state['mode'] as String?;
    if (modeStr != null) {
      _mode = CameraMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => CameraMode.shootPhoto,
      );
    }

    if (_isRecording && _recordingTimer == null) {
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingSeconds++;
        notifyListeners();
      });
    } else if (!_isRecording && _recordingTimer != null) {
      _recordingTimer!.cancel();
      _recordingTimer = null;
    }
    notifyListeners();
  }

  Future<void> takePhoto() async {
    try {
      await _channel.invokeMethod('setCameraMode', {'mode': 'ShootPhoto'});
      await Future.delayed(const Duration(milliseconds: 500));
      await _channel.invokeMethod('takePhoto');
    } on PlatformException catch (e) {
      debugPrint('takePhoto error: ${e.message}');
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      await _channel.invokeMethod('setCameraMode', {'mode': 'RecordVideo'});
      await Future.delayed(const Duration(milliseconds: 500));
      await _channel.invokeMethod('startRecording');
    } on PlatformException catch (e) {
      debugPrint('startRecording error: ${e.message}');
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    try {
      await _channel.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      debugPrint('stopRecording error: ${e.message}');
    }
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> setZoom(double factor) async {
    try {
      await _channel.invokeMethod('setDigitalZoom', {'factor': factor});
    } on PlatformException catch (e) {
      debugPrint('setZoom error: ${e.message}');
    }
  }

  Future<void> setExposureMode(String mode) async {
    try {
      await _channel.invokeMethod('setExposureMode', {'mode': mode});
      _exposureMode = mode;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('setExposureMode error: ${e.message}');
    }
  }

  Future<void> setExposureCompensation(String comp) async {
    try {
      await _channel.invokeMethod('setExposureCompensation', {'comp': comp});
    } on PlatformException catch (e) {
      debugPrint('setExposureCompensation error: ${e.message}');
    }
  }

  Future<void> setISO(String iso) async {
    try {
      await _channel.invokeMethod('setISO', {'iso': iso});
    } on PlatformException catch (e) {
      debugPrint('setISO error: ${e.message}');
    }
  }

  Future<void> setWhiteBalance(String wb) async {
    try {
      await _channel.invokeMethod('setWhiteBalance', {'wb': wb});
    } on PlatformException catch (e) {
      debugPrint('setWhiteBalance error: ${e.message}');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
