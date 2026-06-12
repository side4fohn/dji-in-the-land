import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VideoManager extends ChangeNotifier {
  Uint8List? _latestVideoData;
  bool _isReceiving = false;
  bool _isReady = false;

  Uint8List? get latestVideoData => _latestVideoData;
  bool get isReceiving => _isReceiving;
  bool get isReady => _isReady;

  static const _eventChannel = EventChannel('com.dji.sdk/Video/events');
  StreamSubscription? _subscription;

  Future<void> start() async {
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(_handleVideoData);
      _isReceiving = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Video start error: $e');
    }
  }

  void _handleVideoData(dynamic data) {
    if (data is Uint8List) {
      _latestVideoData = data;
      _isReady = true;
      notifyListeners();
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isReceiving = false;
    _isReady = false;
    _latestVideoData = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
