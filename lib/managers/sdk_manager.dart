import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SDKState {
  unknown,
  unregistered,
  registered,
  connecting,
  connected,
  disconnected,
  error
}

class SDKManager extends ChangeNotifier {
  SDKState _state = SDKState.unknown;
  String _errorMessage = '';
  String _productName = '';
  String _firmwareVersion = '';

  SDKState get state => _state;
  String get errorMessage => _errorMessage;
  String get productName => _productName;
  String get firmwareVersion => _firmwareVersion;
  bool get isConnected => _state == SDKState.connected;

  static const String _appKey = 'be9d6aefbe48fbd8d9c55e0d';

  void startSDK() {
    _state = SDKState.unregistered;
    notifyListeners();
    _registerApp();
  }

  Future<void> _registerApp() async {
    try {
      const channel = MethodChannel('com.dji.sdk/API');
      final result = await channel.invokeMethod('registerApp', {'appKey': _appKey});
      if (result == true) {
        _state = SDKState.registered;
        notifyListeners();
        _connectProduct();
      } else {
        _state = SDKState.error;
        _errorMessage = 'Registration failed: $result';
        notifyListeners();
      }
    } on PlatformException catch (e) {
      _state = SDKState.error;
      _errorMessage = e.message ?? 'Unknown error';
      notifyListeners();
    }
  }

  Future<void> _connectProduct() async {
    _state = SDKState.connecting;
    notifyListeners();
    try {
      const channel = MethodChannel('com.dji.sdk/API');
      final result = await channel.invokeMethod('connectProduct');
      if (result == true) {
        _state = SDKState.connected;
        _productName = 'DJI Air 2';
        notifyListeners();
      }
    } on PlatformException catch (e) {
      _state = SDKState.disconnected;
      _errorMessage = e.message ?? 'Connection failed';
      notifyListeners();
    }
  }

  void onProductConnected(Map<String, dynamic> productInfo) {
    _state = SDKState.connected;
    _productName = productInfo['modelName'] ?? 'Unknown';
    _firmwareVersion = productInfo['firmwareVersion'] ?? '';
    notifyListeners();
  }

  void onProductDisconnected() {
    _state = SDKState.disconnected;
    _productName = '';
    _firmwareVersion = '';
    notifyListeners();
  }
}
