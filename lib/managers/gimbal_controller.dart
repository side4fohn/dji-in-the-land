import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GimbalCtrl extends ChangeNotifier {
  double _pitchAngle = 0.0;
  double _yawAngle = 0.0;
  double _currentPitch = 0.0;
  double _currentYaw = 0.0;
  bool _isSpeedMode = true;
  bool _isReady = false;

  double get pitchAngle => _pitchAngle;
  double get yawAngle => _yawAngle;
  double get currentPitch => _currentPitch;
  double get currentYaw => _currentYaw;
  bool get isSpeedMode => _isSpeedMode;
  bool get isReady => _isReady;

  static const _channel = MethodChannel('com.dji.sdk/Gimbal');

  void setReady(bool ready) {
    _isReady = ready;
    notifyListeners();
  }

  Future<void> rotateToAngle(double pitch, double yaw, {double time = 0.5}) async {
    _pitchAngle = pitch.clamp(-90.0, 17.0);
    _yawAngle = yaw;
    notifyListeners();
    try {
      await _channel.invokeMethod('rotateToAngle', {
        'pitch': pitch,
        'yaw': yaw,
        'time': time,
      });
    } on PlatformException catch (e) {
      debugPrint('Gimbal rotate error: ${e.message}');
    }
  }

  Future<void> setSpeed(double pitchSpeed, double yawSpeed) async {
    try {
      await _channel.invokeMethod('setSpeed', {
        'pitch': pitchSpeed,
        'yaw': yawSpeed,
      });
    } on PlatformException catch (e) {
      debugPrint('Gimbal speed error: ${e.message}');
    }
  }

  void updateFromJoystick(double normalizedPitch, double normalizedYaw) {
    if (!_isReady) return;
    setSpeed(normalizedPitch * 50.0, normalizedYaw * 30.0);
  }

  void resetToDefault() => rotateToAngle(0.0, 0.0, time: 1.0);
  void centerPitch() => rotateToAngle(0.0, _yawAngle, time: 0.5);
  void toggleMode() {
    _isSpeedMode = !_isSpeedMode;
    notifyListeners();
  }

  void updateAttitude(double pitch, double yaw) {
    _currentPitch = pitch;
    _currentYaw = yaw;
    notifyListeners();
  }
}
