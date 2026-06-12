import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RCInputManager extends ChangeNotifier {
  int _leftStickVertical = 0;
  int _leftStickHorizontal = 0;
  int _rightStickVertical = 0;
  int _rightStickHorizontal = 0;
  bool _isListening = false;
  StreamSubscription? _subscription;

  int get leftStickVertical => _leftStickVertical;
  int get leftStickHorizontal => _leftStickHorizontal;
  int get rightStickVertical => _rightStickVertical;
  int get rightStickHorizontal => _rightStickHorizontal;
  bool get isListening => _isListening;

  static const _eventChannel = EventChannel('com.dji.sdk/RC/events');
  static const int _deadZone = 50;
  static const int _maxValue = 660;

  Function(double pitch, double yaw)? onJoystickChanged;

  Future<void> startListening() async {
    if (_isListening) return;
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(_handleRCHardwareState);
      _isListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('RC startListening error: $e');
    }
  }

  void _handleRCHardwareState(dynamic state) {
    if (state is! Map) return;
    final left = state['leftStick'] as Map?;
    final right = state['rightStick'] as Map?;

    if (left != null) {
      _leftStickVertical = (left['vertical'] as num?)?.toInt() ?? 0;
      _leftStickHorizontal = (left['horizontal'] as num?)?.toInt() ?? 0;
    }
    if (right != null) {
      _rightStickVertical = (right['vertical'] as num?)?.toInt() ?? 0;
      _rightStickHorizontal = (right['horizontal'] as num?)?.toInt() ?? 0;
    }

    double pitchRaw = _leftStickVertical / _maxValue;
    double yawRaw = _leftStickHorizontal / _maxValue;

    pitchRaw = _applyDeadZone(pitchRaw);
    yawRaw = _applyDeadZone(yawRaw);

    onJoystickChanged?.call(pitchRaw, yawRaw);
    notifyListeners();
  }

  double _applyDeadZone(double value) {
    if (value.abs() < _deadZone / _maxValue) return 0.0;
    return value;
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
