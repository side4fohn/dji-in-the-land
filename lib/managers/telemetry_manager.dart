import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';

class TelemetryManager extends ChangeNotifier {
  int _batteryPercent = -1;
  double _batteryTemp = -1;
  double _latitude = 0;
  double _longitude = 0;
  double _altitude = 0;
  double _speedX = 0;
  double _speedY = 0;
  double _speedZ = 0;
  int _satellites = 0;
  bool _gpsSignalGood = false;
  bool _motorsOn = false;
  String _flightMode = '';
  bool _isFlying = false;
  bool _lowBatteryWarning = false;
  bool _seriousLowBatteryWarning = false;
  bool _isMonitoring = false;
  StreamSubscription? _subscription;

  int get batteryPercent => _batteryPercent;
  double get batteryTemp => _batteryTemp;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get altitude => _altitude;
  double get speedX => _speedX;
  double get speedY => _speedY;
  double get speedZ => _speedZ;
  int get satellites => _satellites;
  bool get gpsSignalGood => _gpsSignalGood;
  bool get motorsOn => _motorsOn;
  String get flightMode => _flightMode;
  bool get isFlying => _isFlying;
  bool get lowBatteryWarning => _lowBatteryWarning;
  bool get seriousLowBatteryWarning => _seriousLowBatteryWarning;
  bool get isMonitoring => _isMonitoring;

  static const _eventChannel = EventChannel('com.dji.sdk/Telemetry/events');

  void startMonitoring() {
    if (_isMonitoring) return;
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(_handleTelemetry);
      _isMonitoring = true;
    } catch (e) {
      debugPrint('Telemetry startMonitoring error: $e');
    }
  }

  void _handleTelemetry(dynamic data) {
    if (data is! Map) return;
    final fc = data['flightController'] as Map?;
    final battery = data['battery'] as Map?;

    if (fc != null) {
      final loc = fc['location'] as Map?;
      if (loc != null) {
        _latitude = (loc['latitude'] as num?)?.toDouble() ?? 0;
        _longitude = (loc['longitude'] as num?)?.toDouble() ?? 0;
      }
      _altitude = (fc['altitude'] as num?)?.toDouble() ?? 0;
      _speedX = (fc['speedX'] as num?)?.toDouble() ?? 0;
      _speedY = (fc['speedY'] as num?)?.toDouble() ?? 0;
      _speedZ = (fc['speedZ'] as num?)?.toDouble() ?? 0;
      _satellites = (fc['satellites'] as num?)?.toInt() ?? 0;
      _gpsSignalGood = fc['gpsSignalGood'] ?? false;
      _motorsOn = fc['motorsOn'] ?? false;
      _flightMode = fc['flightMode'] as String? ?? '';
      _isFlying = fc['isFlying'] ?? false;
      _lowBatteryWarning = fc['lowBatteryWarning'] ?? false;
      _seriousLowBatteryWarning = fc['seriousLowBatteryWarning'] ?? false;
    }

    if (battery != null) {
      _batteryPercent = (battery['percent'] as num?)?.toInt() ?? -1;
      _batteryTemp = (battery['temp'] as num?)?.toDouble() ?? -1;
    }

    notifyListeners();
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
